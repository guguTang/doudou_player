import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_collection.dart';
import '../models/video_item.dart';
import 'library_path.dart';
import 'library_service.dart';

class CollectionService extends ChangeNotifier {
  static const _storageKey = 'video_collections';

  final List<VideoCollection> _collections = [];
  bool _loaded = false;

  List<VideoCollection> get collections => List.unmodifiable(_collections);
  bool get isLoaded => _loaded;

  List<VideoCollection> get manualCollections =>
      _collections.where((c) => c.type == VideoCollectionType.manual).toList();

  List<VideoCollection> get scanRootCollections =>
      _collections.where((c) => c.type == VideoCollectionType.scanRoot).toList();

  VideoCollection? findById(String id) {
    for (final collection in _collections) {
      if (collection.id == id) {
        return collection;
      }
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _collections.clear();

    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final entry in decoded) {
        _collections.add(VideoCollection.fromJson(entry as Map<String, dynamic>));
      }
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(_collections.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<VideoCollection> createManualCollection(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Collection name cannot be empty');
    }

    final collection = VideoCollection(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      type: VideoCollectionType.manual,
    );
    _collections.add(collection);
    await _save();
    notifyListeners();
    return collection;
  }

  Future<void> renameCollection(String id, String name) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }
    final collection = _collections[index];
    if (collection.type != VideoCollectionType.manual) {
      return;
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _collections[index] = collection.copyWith(name: trimmed);
    await _save();
    notifyListeners();
  }

  Future<void> deleteCollection(String id) async {
    final before = _collections.length;
    _collections.removeWhere((c) => c.id == id);
    if (_collections.length < before) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> addVideosToCollection(
    String id,
    Iterable<String> videoIds,
  ) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }

    final collection = _collections[index];
    final merged = {...collection.videoIds, ...videoIds}.toList();
    _collections[index] = collection.copyWith(videoIds: merged);
    await _save();
    notifyListeners();
  }

  Future<void> removeVideosFromCollection(
    String id,
    Iterable<String> videoIds,
  ) async {
    final index = _indexOf(id);
    if (index == -1) {
      return;
    }

    final removeSet = videoIds.toSet();
    final collection = _collections[index];
    final filtered =
        collection.videoIds.where((vid) => !removeSet.contains(vid)).toList();
    _collections[index] = collection.copyWith(videoIds: filtered);
    await _save();
    notifyListeners();
  }

  Future<void> registerScanRootCollection(
    String rootPath,
    String? directoryBookmark,
    Iterable<String> videoIds,
  ) async {
    final normalizedRoot = normalizeLibraryPath(rootPath);
    final ids = videoIds.toList();
    if (ids.isEmpty) {
      return;
    }

    final index = _collections.indexWhere(
      (c) =>
          c.type == VideoCollectionType.scanRoot &&
          c.scanRootPath != null &&
          libraryPathsEqual(c.scanRootPath!, normalizedRoot),
    );

    if (index == -1) {
      _collections.add(
        VideoCollection(
          id: normalizedRoot,
          name: p.basename(normalizedRoot),
          type: VideoCollectionType.scanRoot,
          videoIds: ids,
          scanRootPath: normalizedRoot,
          directoryBookmark: directoryBookmark,
        ),
      );
    } else {
      final existing = _collections[index];
      final merged = {...existing.videoIds, ...ids}.toList();
      _collections[index] = existing.copyWith(
        videoIds: merged,
        directoryBookmark: directoryBookmark ?? existing.directoryBookmark,
      );
    }

    await _save();
    notifyListeners();
  }

  Future<void> pruneVideoIds(Set<String> validIds) async {
    var updated = false;

    for (var index = 0; index < _collections.length; index++) {
      final collection = _collections[index];
      final pruned =
          collection.videoIds.where(validIds.contains).toList();
      if (pruned.length != collection.videoIds.length) {
        _collections[index] = collection.copyWith(videoIds: pruned);
        updated = true;
      }
    }

    if (updated) {
      await _save();
      notifyListeners();
    }
  }

  List<VideoItem> videosInCollection(String id, LibraryService libraryService) {
    final collection = findById(id);
    if (collection == null) {
      return const [];
    }

    final results = <VideoItem>[];
    for (final videoId in collection.videoIds) {
      final item = libraryService.findById(videoId);
      if (item != null) {
        results.add(item);
      }
    }
    return results;
  }

  int _indexOf(String id) {
    return _collections.indexWhere((c) => c.id == id);
  }
}
