import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

/// macOS 沙盒下通过 security-scoped bookmark 维持对用户选择文件的访问权限。
class SecureFileAccess {
  SecureFileAccess._();

  static final SecureFileAccess instance = SecureFileAccess._();

  final SecureBookmarks _bookmarks = SecureBookmarks();
  final List<FileSystemEntity> _activeResources = [];

  static bool get enabled => !kIsWeb && Platform.isMacOS;

  Future<String?> createBookmark(String path, {bool isDirectory = false}) async {
    if (!enabled) {
      return null;
    }

    try {
      final entity = isDirectory ? Directory(path) : File(path);
      return await _bookmarks.bookmark(entity);
    } catch (_) {
      return null;
    }
  }

  /// 开始 security-scoped 访问。成功时返回已解析的绝对路径。
  Future<String?> startAccess({
    String? bookmark,
    String? fallbackPath,
    bool isDirectory = false,
  }) async {
    if (!enabled || bookmark == null || bookmark.isEmpty) {
      return fallbackPath;
    }

    try {
      final entity = await _bookmarks.resolveBookmark(
        bookmark,
        isDirectory: isDirectory,
      );
      final granted =
          await _bookmarks.startAccessingSecurityScopedResource(entity);
      if (granted) {
        _activeResources.add(entity);
        return entity.absolute.path;
      }
    } catch (_) {
      if (fallbackPath != null && FileSystemEntity.typeSync(fallbackPath) !=
          FileSystemEntityType.notFound) {
        return fallbackPath;
      }
    }
    return null;
  }

  Future<void> startAccessForPaths({
    String? fileBookmark,
    String? filePath,
    String? directoryBookmark,
    String? zhSubBookmark,
    String? zhSubPath,
    String? enSubBookmark,
    String? enSubPath,
  }) async {
    if (!enabled) {
      return;
    }

    if (directoryBookmark != null) {
      await startAccess(
        bookmark: directoryBookmark,
        fallbackPath: filePath != null ? File(filePath).parent.path : null,
        isDirectory: true,
      );
    }

    if (fileBookmark != null) {
      await startAccess(
        bookmark: fileBookmark,
        fallbackPath: filePath,
      );
    }

    if (zhSubBookmark != null) {
      await startAccess(bookmark: zhSubBookmark, fallbackPath: zhSubPath);
    }

    if (enSubBookmark != null) {
      await startAccess(bookmark: enSubBookmark, fallbackPath: enSubPath);
    }
  }

  Future<void> stopAll() async {
    if (!enabled) {
      return;
    }

    for (final entity in _activeResources.reversed) {
      try {
        await _bookmarks.stopAccessingSecurityScopedResource(entity);
      } catch (_) {}
    }
    _activeResources.clear();
  }
}
