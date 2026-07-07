import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'subtitle_matcher.dart';

class LanUploadStorageException implements Exception {
  LanUploadStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LanUploadStorage {
  LanUploadStorage({
    Future<Directory> Function()? uploadDirectoryProvider,
    int? maxFileSizeBytes,
  })  : _uploadDirectoryProvider = uploadDirectoryProvider,
        _maxFileSizeBytes = maxFileSizeBytes ?? LanUploadStorage.maxFileSizeBytes;

  static const maxFileSizeBytes = 4 * 1024 * 1024 * 1024;

  final Future<Directory> Function()? _uploadDirectoryProvider;
  final int _maxFileSizeBytes;

  Future<Directory> getUploadDirectory() async {
    if (_uploadDirectoryProvider != null) {
      final directory = await _uploadDirectoryProvider();
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      return directory;
    }

    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'lan_uploads'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static String? sanitizeFileName(String originalName) {
    final trimmed = originalName.trim();
    if (trimmed.contains('..') ||
        trimmed.contains('/') ||
        trimmed.contains('\\')) {
      return null;
    }
    final name = p.basename(trimmed);
    if (name.isEmpty || name == '.' || name == '..') {
      return null;
    }
    if (!SubtitleMatcher.isAllowedUploadFile(name)) {
      return null;
    }
    return name;
  }

  Future<String> saveUploadedFile(
    String originalName,
    Stream<List<int>> bytes,
  ) async {
    final sanitized = sanitizeFileName(originalName);
    if (sanitized == null) {
      throw LanUploadStorageException('invalid file name: $originalName');
    }

    final directory = await getUploadDirectory();
    final targetPath = _resolveUniquePath(directory.path, sanitized);
    final file = File(targetPath);
    final sink = file.openWrite();
    var totalSize = 0;

    try {
      await for (final chunk in bytes) {
        totalSize += chunk.length;
        if (totalSize > _maxFileSizeBytes) {
          throw LanUploadStorageException('file too large: $sanitized');
        }
        sink.add(chunk);
      }
      await sink.close();
      return targetPath;
    } catch (error) {
      try {
        await sink.close();
      } catch (_) {}
      if (file.existsSync()) {
        await file.delete();
      }
      rethrow;
    }
  }

  static String _resolveUniquePath(String directoryPath, String fileName) {
    final baseName = p.basenameWithoutExtension(fileName);
    final extension = p.extension(fileName);
    var candidate = p.join(directoryPath, fileName);
    var counter = 1;

    while (File(candidate).existsSync()) {
      candidate = p.join(directoryPath, '${baseName}_$counter$extension');
      counter++;
    }

    return candidate;
  }
}
