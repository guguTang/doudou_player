import 'package:path/path.dart' as p;

enum LibraryScanPhase {
  scanningDirectory,
  importingVideos,
}

class LibraryScanProgress {
  const LibraryScanProgress({
    required this.phase,
    this.scannedEntries = 0,
    this.foundVideos = 0,
    this.current = 0,
    this.total = 0,
    this.currentLabel,
  });

  final LibraryScanPhase phase;
  final int scannedEntries;
  final int foundVideos;
  final int current;
  final int total;
  final String? currentLabel;

  double? get fraction {
    if (phase != LibraryScanPhase.importingVideos || total <= 0) {
      return null;
    }
    return current / total;
  }

  String get title {
    switch (phase) {
      case LibraryScanPhase.scanningDirectory:
        return '正在扫描文件夹';
      case LibraryScanPhase.importingVideos:
        return '正在导入视频';
    }
  }

  String get message {
    switch (phase) {
      case LibraryScanPhase.scanningDirectory:
        if (scannedEntries <= 0) {
          return '正在遍历文件…';
        }
        return '已检查 $scannedEntries 项，发现 $foundVideos 个视频';
      case LibraryScanPhase.importingVideos:
        if (total <= 0) {
          return '准备导入…';
        }
        final name = currentLabel == null ? '' : ' · ${p.basename(currentLabel!)}';
        return '$current / $total$name';
    }
  }
}
