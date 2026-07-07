import 'dart:io';

import 'package:path/path.dart' as p;

String _stripPrivatePrefix(String path) {
  if (Platform.isMacOS && path.startsWith('/private/')) {
    return path.substring('/private'.length);
  }
  return path;
}

/// 统一库内视频路径，避免 /var 与 /private/var 等等价路径被当成不同文件。
String normalizeLibraryPath(String path) {
  var normalized = p.normalize(p.absolute(path));

  try {
    final file = File(normalized);
    if (file.existsSync()) {
      return _stripPrivatePrefix(p.normalize(file.resolveSymbolicLinksSync()));
    }
    final dir = Directory(normalized);
    if (dir.existsSync()) {
      return _stripPrivatePrefix(p.normalize(dir.resolveSymbolicLinksSync()));
    }
  } catch (_) {}

  return _stripPrivatePrefix(normalized);
}

bool libraryPathsEqual(String a, String b) {
  return normalizeLibraryPath(a) == normalizeLibraryPath(b);
}
