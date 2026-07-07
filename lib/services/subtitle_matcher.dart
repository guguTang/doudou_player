import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/subtitle_scan_rules.dart';

class SubtitleMatch {
  const SubtitleMatch({this.zhPath, this.enPath});

  final String? zhPath;
  final String? enPath;
}

enum SubtitleLanguage { zh, en }

class SubtitleMatcher {
  static const _videoExtensions = {
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
  };

  static bool isVideoFile(String filePath) {
    return _videoExtensions.contains(p.extension(filePath).toLowerCase());
  }

  static bool isSubtitleFile(String filePath) {
    return p.extension(filePath).toLowerCase() == '.srt';
  }

  static bool isAllowedUploadFile(String filePath) {
    return isVideoFile(filePath) || isSubtitleFile(filePath);
  }

  /// Returns the video basename and language inferred from subtitle filename.
  static ({String videoBaseName, SubtitleLanguage? language})? parseSubtitleFileName(
    String filePath, {
    SubtitleScanRules rules = SubtitleScanRules.defaults,
  }) {
    if (!isSubtitleFile(filePath)) {
      return null;
    }

    final fileName = p.basename(filePath).toLowerCase();

    for (final suffix in rules.zhSuffixes) {
      if (fileName.endsWith(suffix)) {
        return (
          videoBaseName: fileName.substring(0, fileName.length - suffix.length),
          language: SubtitleLanguage.zh,
        );
      }
    }

    for (final suffix in rules.enSuffixes) {
      if (fileName.endsWith(suffix)) {
        return (
          videoBaseName: fileName.substring(0, fileName.length - suffix.length),
          language: SubtitleLanguage.en,
        );
      }
    }

    if (fileName.endsWith('.srt')) {
      return (
        videoBaseName: p.basenameWithoutExtension(fileName),
        language: null,
      );
    }

    return null;
  }

  static SubtitleMatch findSubtitles(
    String videoPath, {
    SubtitleScanRules rules = SubtitleScanRules.defaults,
  }) {
    final dir = p.dirname(videoPath);
    final baseName = p.basenameWithoutExtension(videoPath);
    final directory = Directory(dir);

    if (!directory.existsSync()) {
      return const SubtitleMatch();
    }

    String? zhPath;
    String? enPath;

    for (final suffix in rules.zhSuffixes) {
      final candidate = p.join(dir, '$baseName$suffix');
      if (File(candidate).existsSync()) {
        zhPath = candidate;
        break;
      }
    }

    for (final suffix in rules.enSuffixes) {
      final candidate = p.join(dir, '$baseName$suffix');
      if (File(candidate).existsSync()) {
        enPath = candidate;
        break;
      }
    }

    final genericSrt = p.join(dir, '$baseName.srt');
    if (File(genericSrt).existsSync()) {
      if (zhPath == null && enPath == null) {
        // Ambiguous single subtitle — leave for manual selection.
      } else if (zhPath == null) {
        zhPath = genericSrt;
      } else {
        enPath ??= genericSrt;
      }
    }

    return SubtitleMatch(zhPath: zhPath, enPath: enPath);
  }

  static Future<List<String>> scanVideosInDirectory(
    String directoryPath, {
    void Function(int scannedEntries, int foundVideos)? onProgress,
  }) async {
    final root = Directory(directoryPath);
    if (!root.existsSync()) {
      return [];
    }

    final results = <String>[];
    var scannedEntries = 0;

    try {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        scannedEntries++;
        if (entity is File && isVideoFile(entity.path)) {
          results.add(entity.path);
        }

        if (scannedEntries % 80 == 0) {
          onProgress?.call(scannedEntries, results.length);
          await Future<void>.delayed(Duration.zero);
        }
      }
    } catch (_) {
      return [];
    }

    onProgress?.call(scannedEntries, results.length);
    results.sort();
    return results;
  }
}
