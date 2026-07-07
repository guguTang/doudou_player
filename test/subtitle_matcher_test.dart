import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:doudou_player/models/subtitle_scan_rules.dart';
import 'package:doudou_player/services/subtitle_matcher.dart';

void main() {
  test('isVideoFile recognizes common extensions', () {
    expect(SubtitleMatcher.isVideoFile('/path/movie.mp4'), isTrue);
    expect(SubtitleMatcher.isVideoFile('/path/movie.MKV'), isTrue);
    expect(SubtitleMatcher.isVideoFile('/path/movie.srt'), isFalse);
  });

  test('findSubtitles uses configured suffix rules', () {
    final tempDir = Directory.systemTemp.createTempSync('doudou_subtitle_test');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final videoPath = p.join(tempDir.path, 'lesson.mp4');
    File(videoPath).createSync();
    File(p.join(tempDir.path, 'lesson.zh.srt')).writeAsStringSync('zh');
    File(p.join(tempDir.path, 'lesson.en.srt')).writeAsStringSync('en');

    final match = SubtitleMatcher.findSubtitles(
      videoPath,
      rules: const SubtitleScanRules(
        zhSuffixes: ['.zh.srt'],
        enSuffixes: ['.en.srt'],
      ),
    );

    expect(match.zhPath, endsWith('lesson.zh.srt'));
    expect(match.enPath, endsWith('lesson.en.srt'));
  });

  test('findSubtitles respects suffix priority order', () {
    final tempDir = Directory.systemTemp.createTempSync('doudou_subtitle_test');
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final videoPath = p.join(tempDir.path, 'movie.mp4');
    File(videoPath).createSync();
    File(p.join(tempDir.path, 'movie.cn.srt')).writeAsStringSync('cn');
    File(p.join(tempDir.path, 'movie.zh.srt')).writeAsStringSync('zh');

    final match = SubtitleMatcher.findSubtitles(
      videoPath,
      rules: const SubtitleScanRules(
        zhSuffixes: ['.zh.srt', '.cn.srt'],
        enSuffixes: ['.en.srt'],
      ),
    );

    expect(match.zhPath, endsWith('movie.zh.srt'));
  });
}
