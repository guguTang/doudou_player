import 'dart:io';

import 'package:path/path.dart' as p;

class SubtitleMatch {
  const SubtitleMatch({this.zhPath, this.enPath});

  final String? zhPath;
  final String? enPath;
}

class SubtitleMatcher {
  static const _zhSuffixes = [
    '.zh.srt',
    '.zh-cn.srt',
    '.zh-tw.srt',
    '.chs.srt',
    '.cht.srt',
    '.cn.srt',
    '.chinese.srt',
  ];

  static const _enSuffixes = [
    '.en.srt',
    '.eng.srt',
    '.english.srt',
  ];

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

  static SubtitleMatch findSubtitles(String videoPath) {
    final dir = p.dirname(videoPath);
    final baseName = p.basenameWithoutExtension(videoPath);
    final directory = Directory(dir);

    if (!directory.existsSync()) {
      return const SubtitleMatch();
    }

    String? zhPath;
    String? enPath;

    for (final suffix in _zhSuffixes) {
      final candidate = p.join(dir, '$baseName$suffix');
      if (File(candidate).existsSync()) {
        zhPath = candidate;
        break;
      }
    }

    for (final suffix in _enSuffixes) {
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

  static List<String> scanVideosInDirectory(String directoryPath) {
    final root = Directory(directoryPath);
    if (!root.existsSync()) {
      return [];
    }

    final results = <String>[];
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is File && isVideoFile(entity.path)) {
        results.add(entity.path);
      }
    }
    results.sort();
    return results;
  }
}
