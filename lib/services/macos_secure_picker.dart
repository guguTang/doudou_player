import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PickedFileAccess {
  const PickedFileAccess({required this.path, this.bookmark});

  final String path;
  final String? bookmark;
}

/// macOS 沙盒下在用户选择文件/目录时立即创建 security-scoped bookmark。
class MacosSecurePicker {
  MacosSecurePicker._();

  static const _channel = MethodChannel('com.doudou/secure_file_picker');

  static bool get isSupported => !kIsWeb && Platform.isMacOS;

  static Future<List<PickedFileAccess>> pickVideos() async {
    if (!isSupported) {
      return [];
    }

    final result = await _channel.invokeMethod<List<dynamic>>('pickVideos');
    if (result == null) {
      return [];
    }

    return result
        .map((item) => _fromMap(item))
        .whereType<PickedFileAccess>()
        .toList();
  }

  static Future<PickedFileAccess?> pickDirectory() async {
    if (!isSupported) {
      return null;
    }

    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickDirectory',
    );
    return _fromMap(result);
  }

  static Future<PickedFileAccess?> pickSubtitle() async {
    if (!isSupported) {
      return null;
    }

    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickSubtitle',
    );
    return _fromMap(result);
  }

  static PickedFileAccess? _fromMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final path = raw['path'] as String?;
    final bookmark = raw['bookmark'] as String?;
    if (path == null || bookmark == null || path.isEmpty || bookmark.isEmpty) {
      return null;
    }
    return PickedFileAccess(path: path, bookmark: bookmark);
  }
}
