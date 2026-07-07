import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doudou_player/models/lan_upload_settings.dart';
import 'package:doudou_player/models/subtitle_scan_rules.dart';
import 'package:doudou_player/services/lan_upload_service.dart';
import 'package:doudou_player/services/lan_upload_storage.dart';
import 'package:doudou_player/services/library_service.dart';
import 'package:doudou_player/services/settings_service.dart';
import 'package:doudou_player/services/subtitle_matcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanUploadStorage', () {
    late Directory tempDir;
    late LanUploadStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lan_upload_test_');
      storage = LanUploadStorage(
        uploadDirectoryProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('sanitizeFileName rejects traversal and unsupported extensions', () {
      expect(LanUploadStorage.sanitizeFileName('../evil.mp4'), isNull);
      expect(LanUploadStorage.sanitizeFileName('nested/name.mp4'), isNull);
      expect(LanUploadStorage.sanitizeFileName('notes.txt'), isNull);
      expect(LanUploadStorage.sanitizeFileName('movie.mp4'), 'movie.mp4');
      expect(LanUploadStorage.sanitizeFileName('movie.zh.srt'), 'movie.zh.srt');
    });

    test('saveUploadedFile writes stream and resolves duplicate names', () async {
      final first = await storage.saveUploadedFile(
        'clip.mp4',
        Stream.value([1, 2, 3]),
      );
      final second = await storage.saveUploadedFile(
        'clip.mp4',
        Stream.value([4, 5]),
      );

      expect(File(first).existsSync(), isTrue);
      expect(File(second).existsSync(), isTrue);
      expect(first, isNot(second));
      expect(File(first).lengthSync(), 3);
      expect(File(second).lengthSync(), 2);
    });

    test('saveUploadedFile rejects oversized payloads', () async {
      final limitedStorage = LanUploadStorage(
        uploadDirectoryProvider: () async => tempDir,
        maxFileSizeBytes: 8,
      );
      expect(
        () => limitedStorage.saveUploadedFile(
          'big.mp4',
          Stream.value([1, 2, 3, 4, 5, 6, 7, 8, 9]),
        ),
        throwsA(isA<LanUploadStorageException>()),
      );
      expect(Directory(tempDir.path).listSync(), isEmpty);
    });
  });

  group('LibraryService.attachUploadedSubtitles', () {
    late Directory tempDir;
    late SettingsService settings;
    late LibraryService library;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('lan_attach_test_');
      settings = SettingsService();
      await settings.load();
      library = LibraryService(settings);
      await library.load();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('attaches zh subtitle to existing video by basename', () async {
      final videoPath = File('${tempDir.path}/movie.mp4').path;
      await File(videoPath).create();
      await library.addVideoPaths([videoPath]);

      final subtitlePath = File('${tempDir.path}/movie.zh.srt').path;
      await File(subtitlePath).writeAsString('1\n00:00:00,000 --> 00:00:01,000\nhi');

      final result = await library.attachUploadedSubtitles(
        [subtitlePath],
        rules: SubtitleScanRules.defaults,
      );

      expect(result.attached, 1);
      expect(result.skipped, 0);
      final item = library.items.single;
      expect(item.zhSubPath, subtitlePath);
      expect(item.enSubPath, isNull);
    });

    test('skips ambiguous subtitle suffix', () async {
      final subtitlePath = File('${tempDir.path}/movie.srt').path;
      await File(subtitlePath).writeAsString('content');

      final result = await library.attachUploadedSubtitles(
        [subtitlePath],
        rules: SubtitleScanRules.defaults,
      );

      expect(result.attached, 0);
      expect(result.skipped, 1);
      expect(result.errors, isNotEmpty);
    });
  });

  group('SubtitleMatcher upload helpers', () {
    test('parseSubtitleFileName detects language-specific suffixes', () {
      final zh = SubtitleMatcher.parseSubtitleFileName('movie.zh.srt');
      final en = SubtitleMatcher.parseSubtitleFileName('movie.en.srt');

      expect(zh?.videoBaseName, 'movie');
      expect(zh?.language, SubtitleLanguage.zh);
      expect(en?.language, SubtitleLanguage.en);
    });
  });

  group('LanUploadSettings', () {
    test('persists through SettingsService', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService();
      await settings.load();

      const custom = LanUploadSettings(
        enabled: true,
        port: 9000,
        autoStart: true,
        token: '123456',
      );
      await settings.setLanUploadSettings(custom);

      final restored = SettingsService();
      await restored.load();

      expect(restored.lanUploadSettings.enabled, isTrue);
      expect(restored.lanUploadSettings.port, 9000);
      expect(restored.lanUploadSettings.autoStart, isTrue);
      expect(restored.lanUploadSettings.token, '123456');
    });
  });

  group('LanUploadService handler', () {
    late Directory tempDir;
    late SettingsService settings;
    late LibraryService library;
    late LanUploadService lanUpload;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('lan_http_test_');
      settings = SettingsService();
      await settings.load();
      library = LibraryService(settings);
      await library.load();
      lanUpload = LanUploadService(
        libraryService: library,
        settingsService: settings,
        storage: LanUploadStorage(uploadDirectoryProvider: () async => tempDir),
      );
      await settings.setLanUploadSettings(
        const LanUploadSettings(
          enabled: false,
          port: 28765,
          autoStart: false,
          token: '654321',
        ),
      );
    });

    tearDown(() async {
      await lanUpload.stop();
      lanUpload.dispose();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<Response> postMultipart({
      required String token,
      required String body,
      String boundary = '----darttest',
    }) async {
      return await lanUpload.handler(
        Request(
          'POST',
          Uri.parse('http://127.0.0.1/api/upload?token=$token'),
          headers: {
            'content-type': 'multipart/form-data; boundary=$boundary',
            if (token.isNotEmpty) 'x-upload-token': token,
          },
          body: body,
          encoding: utf8,
        ),
      );
    }

    test('rejects upload without valid token', () async {
      const boundary = '----darttest';
      final response = await postMultipart(
        token: '',
        body: '--$boundary--\r\n',
      );
      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('uploads video and imports into library', () async {
      const token = '654321';
      const boundary = '----darttest';
      final body = [
        '--$boundary\r\n',
        'Content-Disposition: form-data; name="files"; filename="remote.mp4"\r\n',
        '\r\n',
        'video-bytes\r\n',
        '--$boundary--\r\n',
      ].join();

      final response = await postMultipart(token: token, body: body);
      final responseBody = await response.readAsString();

      expect(response.statusCode, HttpStatus.ok);
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;
      expect(payload['videosAdded'], 1);
      expect(library.items, hasLength(1));
      expect(library.items.single.title, 'remote');
    });
  });
}
