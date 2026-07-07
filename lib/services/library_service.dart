import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_scan_progress.dart';
import '../models/subtitle_scan_rules.dart';
import '../models/video_item.dart';
import 'library_path.dart';
import 'macos_secure_picker.dart';
import 'secure_file_access.dart';
import 'settings_service.dart';
import 'subtitle_matcher.dart';
import 'thumbnail_service.dart';

class SubtitleAttachResult {
  const SubtitleAttachResult({
    required this.attached,
    required this.skipped,
    required this.errors,
  });

  final int attached;
  final int skipped;
  final List<String> errors;
}

class LibraryService extends ChangeNotifier {
  LibraryService(this._settingsService, {ThumbnailService? thumbnailService})
      : _thumbnailService = thumbnailService ?? ThumbnailService();

  final SettingsService _settingsService;
  final ThumbnailService _thumbnailService;

  static const _storageKey = 'video_library';

  final List<VideoItem> _items = [];
  bool _loaded = false;
  LibraryScanProgress? _scanProgress;
  final _secureAccess = SecureFileAccess.instance;

  List<VideoItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _loaded;
  LibraryScanProgress? get scanProgress => _scanProgress;

  void _setScanProgress(LibraryScanProgress? progress) {
    _scanProgress = progress;
    notifyListeners();
  }

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
    unawaited(_backfillMissingThumbnails());
  }

  Future<void> _backfillMissingThumbnails() async {
    var updated = false;

    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];
      final existing = item.thumbnailPath;
      if (existing != null &&
          File(existing).existsSync() &&
          File(existing).lengthSync() > 0) {
        continue;
      }

      try {
        final thumbnailPath = await _generateThumbnailForItem(item);
        if (thumbnailPath == null) {
          continue;
        }

        _items[index] = item.copyWith(thumbnailPath: thumbnailPath);
        updated = true;
        notifyListeners();
      } catch (_) {
        continue;
      }
    }

    if (updated) {
      await _save();
    }
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

  Future<VideoItem> _createVideoItem(
    String normalizedPath, {
    String? fileBookmark,
    String? directoryBookmark,
    String? zhPath,
    String? enPath,
  }) async {
    final item = await _withBookmarks(
      normalizedPath,
      fileBookmark: fileBookmark,
      directoryBookmark: directoryBookmark,
      zhPath: zhPath,
      enPath: enPath,
    );
    final thumbnailPath = await _generateThumbnailForItem(item);
    if (thumbnailPath == null) {
      return item;
    }
    return item.copyWith(thumbnailPath: thumbnailPath);
  }

  Future<String?> _generateThumbnailForItem(VideoItem item) async {
    if (SecureFileAccess.enabled) {
      final accessible = await ensureAccess(item);
      if (!accessible) {
        return null;
      }
      try {
        return await _thumbnailService.generateForVideo(item.filePath);
      } finally {
        await releaseAccess();
      }
    }

    if (!File(item.filePath).existsSync()) {
      return null;
    }
    return _thumbnailService.generateForVideo(item.filePath);
  }

  bool _containsVideoPath(String path) {
    return _items.any((item) => libraryPathsEqual(item.filePath, path));
  }

  Future<int> addVideoPaths(
    List<String> paths, {
    String? directoryBookmark,
    bool reportScanProgress = false,
  }) async {
    final pending = <String>[];
    for (final path in paths) {
      if (!SubtitleMatcher.isVideoFile(path)) {
        continue;
      }
      if (_containsVideoPath(path)) {
        continue;
      }
      pending.add(path);
    }

    if (reportScanProgress) {
      _setScanProgress(
        LibraryScanProgress(
          phase: LibraryScanPhase.importingVideos,
          current: 0,
          total: pending.length,
        ),
      );
    }

    var added = 0;
    for (var index = 0; index < pending.length; index++) {
      final path = pending[index];
      final normalizedPath = normalizeLibraryPath(path);

      if (reportScanProgress) {
        _setScanProgress(
          LibraryScanProgress(
            phase: LibraryScanPhase.importingVideos,
            current: index,
            total: pending.length,
            currentLabel: normalizedPath,
          ),
        );
        await Future<void>.delayed(Duration.zero);
      }

      final match = SubtitleMatcher.findSubtitles(
        normalizedPath,
        rules: _settingsService.subtitleScanRules,
      );
      _items.add(
        await _createVideoItem(
          normalizedPath,
          directoryBookmark: directoryBookmark,
          zhPath: match.zhPath,
          enPath: match.enPath,
        ),
      );
      added++;

      if (reportScanProgress) {
        _setScanProgress(
          LibraryScanProgress(
            phase: LibraryScanPhase.importingVideos,
            current: index + 1,
            total: pending.length,
            currentLabel: normalizedPath,
          ),
        );
        notifyListeners();
        await Future<void>.delayed(Duration.zero);
      }
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
        if (_containsVideoPath(file.path)) {
          continue;
        }

        final normalizedPath = normalizeLibraryPath(file.path);
        final match = SubtitleMatcher.findSubtitles(
          normalizedPath,
          rules: _settingsService.subtitleScanRules,
        );
        _items.add(
          await _createVideoItem(
            normalizedPath,
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
    try {
      if (MacosSecurePicker.isSupported) {
        final picked = await MacosSecurePicker.pickDirectory();
        if (picked == null) {
          return 0;
        }

        await _secureAccess.stopAll();
        final scanRoot = await _secureAccess.startAccess(
          bookmark: picked.bookmark,
          fallbackPath: picked.path,
          isDirectory: true,
        );
        if (scanRoot == null) {
          return 0;
        }

        return await _scanAndImportDirectory(
          scanRoot,
          directoryBookmark: picked.bookmark,
        );
      }

      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) {
        return 0;
      }

      final directoryBookmark =
          await _secureAccess.createBookmark(directoryPath, isDirectory: true);

      await _secureAccess.stopAll();

      if (SecureFileAccess.enabled && directoryBookmark != null) {
        final scanRoot = await _secureAccess.startAccess(
          bookmark: directoryBookmark,
          fallbackPath: directoryPath,
          isDirectory: true,
        );
        if (scanRoot == null) {
          return 0;
        }

        return await _scanAndImportDirectory(
          scanRoot,
          directoryBookmark: directoryBookmark,
        );
      }

      return await _scanAndImportDirectory(
        directoryPath,
        directoryBookmark: directoryBookmark,
      );
    } finally {
      _setScanProgress(null);
      if (SecureFileAccess.enabled) {
        await _secureAccess.stopAll();
      }
    }
  }

  Future<int> _scanAndImportDirectory(
    String directoryPath, {
    String? directoryBookmark,
  }) async {
    _setScanProgress(
      const LibraryScanProgress(
        phase: LibraryScanPhase.scanningDirectory,
      ),
    );

    final videos = await SubtitleMatcher.scanVideosInDirectory(
      directoryPath,
      onProgress: (scannedEntries, foundVideos) {
        _setScanProgress(
          LibraryScanProgress(
            phase: LibraryScanPhase.scanningDirectory,
            scannedEntries: scannedEntries,
            foundVideos: foundVideos,
          ),
        );
      },
    );

    return addVideoPaths(
      videos,
      directoryBookmark: directoryBookmark,
      reportScanProgress: true,
    );
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
    await removeVideos({id});
  }

  Future<int> removeVideos(Set<String> ids) async {
    if (ids.isEmpty) {
      return 0;
    }
    final before = _items.length;
    final removing = _items.where((item) => ids.contains(item.id)).toList();
    for (final item in removing) {
      await _thumbnailService.deleteForVideo(item.thumbnailPath);
    }
    _items.removeWhere((item) => ids.contains(item.id));
    final removed = before - _items.length;
    if (removed > 0) {
      await _save();
      notifyListeners();
    }
    return removed;
  }

  VideoItem? findById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<SubtitleAttachResult> attachUploadedSubtitles(
    List<String> subtitlePaths, {
    required SubtitleScanRules rules,
  }) async {
    var attached = 0;
    var skipped = 0;
    final errors = <String>[];

    for (final subtitlePath in subtitlePaths) {
      final info = SubtitleMatcher.parseSubtitleFileName(
        subtitlePath,
        rules: rules,
      );
      if (info == null) {
        skipped++;
        errors.add('${p.basename(subtitlePath)}: unsupported subtitle name');
        continue;
      }
      if (info.language == null) {
        skipped++;
        errors.add('${p.basename(subtitlePath)}: ambiguous language suffix');
        continue;
      }

      final matches = _items.where((item) {
        return p.basenameWithoutExtension(item.filePath).toLowerCase() ==
            info.videoBaseName.toLowerCase();
      }).toList();

      if (matches.isEmpty) {
        skipped++;
        errors.add('${p.basename(subtitlePath)}: no matching video in library');
        continue;
      }

      for (final item in matches) {
        if (info.language == SubtitleLanguage.zh) {
          await updateSubtitles(
            id: item.id,
            zhSubPath: subtitlePath,
          );
        } else {
          await updateSubtitles(
            id: item.id,
            enSubPath: subtitlePath,
          );
        }
        attached++;
      }
    }

    return SubtitleAttachResult(
      attached: attached,
      skipped: skipped,
      errors: errors,
    );
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
