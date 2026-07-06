import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_item.dart';
import 'subtitle_matcher.dart';

class LibraryService extends ChangeNotifier {
  LibraryService();

  static const _storageKey = 'video_library';

  final List<VideoItem> _items = [];
  bool _loaded = false;

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

  Future<int> addVideoPaths(List<String> paths) async {
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
        VideoItem.fromPath(path).copyWith(
          zhSubPath: match.zhPath,
          enSubPath: match.enPath,
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
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return 0;
    }

    final videos = SubtitleMatcher.scanVideosInDirectory(directoryPath);
    return addVideoPaths(videos);
  }

  Future<void> updateSubtitles({
    required String id,
    String? zhSubPath,
    String? enSubPath,
    bool clearZh = false,
    bool clearEn = false,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    _items[index] = _items[index].copyWith(
      zhSubPath: zhSubPath,
      enSubPath: enSubPath,
      clearZhSubPath: clearZh,
      clearEnSubPath: clearEn,
    );
    await _save();
    notifyListeners();
  }

  Future<String?> pickSubtitleFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }
    return result.files.single.path;
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
}
