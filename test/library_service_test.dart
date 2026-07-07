import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doudou_player/services/library_path.dart';
import 'package:doudou_player/services/library_service.dart';
import 'package:doudou_player/services/settings_service.dart';
import 'package:doudou_player/services/thumbnail_service.dart';

class _NoopThumbnailService extends ThumbnailService {
  @override
  Future<String?> generateForVideo(String videoPath) async => null;

  @override
  Future<void> deleteForVideo(String? thumbnailPath) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('normalizeLibraryPath strips /private prefix on macOS', () {
    expect(
      normalizeLibraryPath('/private/Users/demo/movie.mp4'),
      '/Users/demo/movie.mp4',
    );
  });

  test('libraryPathsEqual treats /private paths as the same file', () {
    expect(
      libraryPathsEqual(
        '/private/Users/demo/movie.mp4',
        '/Users/demo/movie.mp4',
      ),
      isTrue,
    );
  });

  test('removed videos can be added again from the same path', () async {
    final tempDir = Directory.systemTemp.createTempSync('doudou_library_test');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final videoPath = p.join(tempDir.path, 'lesson.mp4');
    File(videoPath).createSync();

    final settings = SettingsService();
    await settings.load();
    final library = LibraryService(
      settings,
      thumbnailService: _NoopThumbnailService(),
    );
    await library.load();

    expect(await library.addVideoPaths([videoPath]), 1);
    expect(library.items, hasLength(1));

    await library.removeVideo(library.items.first.id);
    expect(library.items, isEmpty);

    expect(await library.addVideoPaths([videoPath]), 1);
    expect(library.items, hasLength(1));
  });

  test('removed videos can be re-added using equivalent /private path', () async {
    final tempDir = Directory.systemTemp.createTempSync('doudou_library_test');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final videoPath = p.join(tempDir.path, 'lesson.mp4');
    File(videoPath).createSync();
    final privateStylePath = videoPath.startsWith('/private/')
        ? videoPath
        : '/private$videoPath';

    final settings = SettingsService();
    await settings.load();
    final library = LibraryService(
      settings,
      thumbnailService: _NoopThumbnailService(),
    );
    await library.load();

    expect(await library.addVideoPaths([videoPath]), 1);
    await library.removeVideo(library.items.first.id);

    if (privateStylePath != videoPath) {
      expect(await library.addVideoPaths([privateStylePath]), 1);
      expect(library.items, hasLength(1));
    }
  });
}
