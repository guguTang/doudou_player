import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'library_path.dart';
import 'thumbnail_capture_coordinator.dart';

class ThumbnailService {
  ThumbnailService({ThumbnailCaptureCoordinator? captureCoordinator})
      : _captureCoordinator =
            captureCoordinator ?? ThumbnailCaptureCoordinator.instance;

  final ThumbnailCaptureCoordinator _captureCoordinator;
  final _random = Random();
  Directory? _cacheDir;
  Future<void> _generationChain = Future<void>.value();

  Future<Directory> _thumbnailDirectory() async {
    if (_cacheDir != null) {
      return _cacheDir!;
    }
    final supportDir = await getApplicationSupportDirectory();
    _cacheDir = Directory(p.join(supportDir.path, 'thumbnails'));
    if (!_cacheDir!.existsSync()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String thumbnailFileName(String videoPath) {
    final normalized = normalizeLibraryPath(videoPath);
    return '${normalized.hashCode.abs()}.jpg';
  }

  Future<String> thumbnailPathForVideo(String videoPath) async {
    final dir = await _thumbnailDirectory();
    return p.join(dir.path, thumbnailFileName(videoPath));
  }

  /// 在 4-10 秒范围内随机取一帧生成封面；短视频则取中间位置。
  static int randomSeekSecond(Duration duration, Random random) {
    const minSecond = 4;
    const maxSecond = 10;
    final totalSeconds = duration.inSeconds;

    if (totalSeconds <= 0) {
      return 0;
    }
    if (totalSeconds <= minSecond) {
      return totalSeconds ~/ 2;
    }

    final upper = totalSeconds < maxSecond ? totalSeconds : maxSecond;
    return minSecond + random.nextInt(upper - minSecond + 1);
  }

  Future<String?> generateForVideo(String videoPath) {
    final task = _generationChain.then(
      (_) => _generateForVideo(videoPath),
    );
    _generationChain = task.then((_) {}, onError: (_) {});
    return task;
  }

  Future<String?> _generateForVideo(String videoPath) async {
    if (!File(videoPath).existsSync()) {
      debugPrint('[ThumbnailService] video not readable: $videoPath');
      return null;
    }

    final outputPath = await thumbnailPathForVideo(videoPath);
    final outputFile = File(outputPath);
    if (outputFile.existsSync() && await outputFile.length() > 0) {
      return outputPath;
    }

    final duration = await _probeDuration(videoPath);
    final seekSecond = randomSeekSecond(duration, _random);

    final bytes = await _captureCoordinator.captureFrame(
      videoPath,
      seekSecond,
    );
    if (bytes != null && bytes.isNotEmpty) {
      await outputFile.writeAsBytes(bytes, flush: true);
      debugPrint(
        '[ThumbnailService] saved ${bytes.length} bytes -> $outputPath',
      );
      return outputPath;
    }

    if (seekSecond > 0) {
      final fallbackBytes = await _captureCoordinator.captureFrame(
        videoPath,
        0,
      );
      if (fallbackBytes != null && fallbackBytes.isNotEmpty) {
        await outputFile.writeAsBytes(fallbackBytes, flush: true);
        debugPrint(
          '[ThumbnailService] saved fallback ${fallbackBytes.length} bytes -> $outputPath',
        );
        return outputPath;
      }
    }

    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    debugPrint('[ThumbnailService] capture failed: $videoPath');
    return null;
  }

  Future<Duration> _probeDuration(String videoPath) async {
    final player = Player();
    try {
      await player.open(Media(videoPath), play: false);
      if (player.state.duration > Duration.zero) {
        return player.state.duration;
      }
      try {
        return await player.stream.duration
            .firstWhere((duration) => duration > Duration.zero)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        return player.state.duration;
      }
    } catch (_) {
      return Duration.zero;
    } finally {
      await player.dispose();
    }
  }

  Future<void> deleteForVideo(String? thumbnailPath) async {
    if (thumbnailPath == null) {
      return;
    }
    final file = File(thumbnailPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
