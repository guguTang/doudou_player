import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_item.dart';
import 'macos_secure_picker.dart';
import 'secure_file_access.dart';
import 'subtitle_matcher.dart';

class LibraryService extends ChangeNotifier {
  LibraryService();

  static const _storageKey = 'video_library';

  final List<VideoItem> _items = [];
  bool _loaded = false;
  final _secureAccess = SecureFileAccess.instance;

  List<VideoItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _items.clear();

    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final entry in decoded) {
        _items.add(VideoItem.fromJson(entry as Map<String, dynamic>));
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<VideoItem> _withBookmarks(
    String path, {
    String? fileBookmark,
    String? directoryBookmark,
    String? zhPath,
    String? enPath,
  }) async {
    final resolvedFileBookmark =
        fileBookmark ?? await _secureAccess.createBookmark(path);
    final zhSubBookmark = zhPath != null
        ? await _secureAccess.createBookmark(zhPath)
        : null;
    final enSubBookmark = enPath != null
        ? await _secureAccess.createBookmark(enPath)
        : null;

    return VideoItem.fromPath(path).copyWith(
      zhSubPath: zhPath,
      enSubPath: enPath,
      fileBookmark: resolvedFileBookmark,
      directoryBookmark: directoryBookmark,
      zhSubBookmark: zhSubBookmark,
      enSubBookmark: enSubBookmark,
    );
  }

  Future<int> addVideoPaths(
    List<String> paths, {
    String? directoryBookmark,
  }) async {
    var added = 0;
    for (final path in paths) {
      if (!SubtitleMatcher.isVideoFile(path)) {
        continue;
      }
      if (_items.any((item) => item.filePath == path)) {
        continue;
      }

      final match = SubtitleMatcher.findSubtitles(path);
      _items.add(
        await _withBookmarks(
          path,
          directoryBookmark: directoryBookmark,
          zhPath: match.zhPath,
          enPath: match.enPath,
        ),
      );
      added++;
    }

    if (added > 0) {
      _items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      await _save();
      notifyListeners();
    }
    return added;
  }

  Future<int> pickAndAddVideos() async {
    if (MacosSecurePicker.isSupported) {
      final picked = await MacosSecurePicker.pickVideos();
      if (picked.isEmpty) {
        return 0;
      }

      var added = 0;
      for (final file in picked) {
        if (!SubtitleMatcher.isVideoFile(file.path)) {
          continue;
        }
        if (_items.any((item) => item.filePath == file.path)) {
          continue;
        }

        final match = SubtitleMatcher.findSubtitles(file.path);
        _items.add(
          await _withBookmarks(
            file.path,
            fileBookmark: file.bookmark,
            zhPath: match.zhPath,
            enPath: match.enPath,
          ),
        );
        added++;
      }

      if (added > 0) {
        _items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        await _save();
        notifyListeners();
      }
      return added;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v'],
      allowMultiple: true,
      withData: false,
    );

    if (result == null) {
      return 0;
    }

    final paths = result.paths.whereType<String>().toList();
    return addVideoPaths(paths);
  }

  Future<int> pickAndScanDirectory() async {
    if (MacosSecurePicker.isSupported) {
      final picked = await MacosSecurePicker.pickDirectory();
      if (picked == null) {
        return 0;
      }

      await _secureAccess.startAccess(
        bookmark: picked.bookmark,
        fallbackPath: picked.path,
        isDirectory: true,
      );

      final videos = SubtitleMatcher.scanVideosInDirectory(picked.path);
      final added = await addVideoPaths(
        videos,
        directoryBookmark: picked.bookmark,
      );

      await _secureAccess.stopAll();
      return added;
    }

    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return 0;
    }

    final directoryBookmark =
        await _secureAccess.createBookmark(directoryPath, isDirectory: true);

    if (SecureFileAccess.enabled && directoryBookmark != null) {
      await _secureAccess.startAccess(
        bookmark: directoryBookmark,
        fallbackPath: directoryPath,
        isDirectory: true,
      );
    }

    final videos = SubtitleMatcher.scanVideosInDirectory(directoryPath);
    final added = await addVideoPaths(
      videos,
      directoryBookmark: directoryBookmark,
    );

    if (SecureFileAccess.enabled && directoryBookmark != null) {
      await _secureAccess.stopAll();
    }

    return added;
  }

  Future<void> updateSubtitles({
    required String id,
    String? zhSubPath,
    String? enSubPath,
    String? zhSubBookmark,
    String? enSubBookmark,
    bool clearZh = false,
    bool clearEn = false,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    String? resolvedZhBookmark = zhSubBookmark;
    String? resolvedEnBookmark = enSubBookmark;
    if (zhSubPath != null && resolvedZhBookmark == null) {
      resolvedZhBookmark = await _secureAccess.createBookmark(zhSubPath);
    }
    if (enSubPath != null && resolvedEnBookmark == null) {
      resolvedEnBookmark = await _secureAccess.createBookmark(enSubPath);
    }

    _items[index] = _items[index].copyWith(
      zhSubPath: zhSubPath,
      enSubPath: enSubPath,
      zhSubBookmark: resolvedZhBookmark,
      enSubBookmark: resolvedEnBookmark,
      clearZhSubPath: clearZh,
      clearEnSubPath: clearEn,
      clearZhSubBookmark: clearZh,
      clearEnSubBookmark: clearEn,
    );
    await _save();
    notifyListeners();
  }

  Future<PickedFileAccess?> pickSubtitleFile() async {
    if (MacosSecurePicker.isSupported) {
      return MacosSecurePicker.pickSubtitle();
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }
    final path = result.files.single.path;
    if (path == null) {
      return null;
    }
    return PickedFileAccess(path: path);
  }

  Future<void> removeVideo(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _save();
    notifyListeners();
  }

  VideoItem? findById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<bool> ensureAccess(VideoItem item) async {
    if (!SecureFileAccess.enabled) {
      return File(item.filePath).existsSync();
    }

    if (item.fileBookmark == null && item.directoryBookmark == null) {
      return false;
    }

    await _secureAccess.stopAll();
    await _secureAccess.startAccessForPaths(
      fileBookmark: item.fileBookmark,
      filePath: item.filePath,
      directoryBookmark: item.directoryBookmark,
      zhSubBookmark: item.zhSubBookmark,
      zhSubPath: item.zhSubPath,
      enSubBookmark: item.enSubBookmark,
      enSubPath: item.enSubPath,
    );

    try {
      final file = File(item.filePath);
      final length = await file.length();
      return length >= 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> releaseAccess() async {
    await _secureAccess.stopAll();
  }
}
