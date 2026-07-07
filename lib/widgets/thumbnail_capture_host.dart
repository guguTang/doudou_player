import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../services/thumbnail_capture_coordinator.dart';

/// 在应用根部挂载隐藏视频输出，供封面生成使用。
class ThumbnailCaptureHost extends StatefulWidget {
  const ThumbnailCaptureHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ThumbnailCaptureHost> createState() => _ThumbnailCaptureHostState();
}

class _ThumbnailCaptureHostState extends State<ThumbnailCaptureHost> {
  Player? _player;
  VideoController? _controller;

  @override
  void initState() {
    super.initState();
    ThumbnailCaptureCoordinator.instance.register(_captureFrame);
  }

  @override
  void dispose() {
    ThumbnailCaptureCoordinator.instance.unregister();
    _player?.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureFrame(String videoPath, int seekSecond) async {
    final player = Player();
    final controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        width: 320,
        height: 180,
      ),
    );

    setState(() {
      _player = player;
      _controller = controller;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;
      await controller.platform.future;
      await player.open(Media(videoPath), play: true);
      await player.setVolume(0);

      await player.stream.duration
          .firstWhere((duration) => duration > Duration.zero)
          .timeout(const Duration(seconds: 12));

      final seekTarget = Duration(seconds: seekSecond);
      await player.seek(seekTarget);

      try {
        await controller.waitUntilFirstFrameRendered.timeout(
          const Duration(seconds: 12),
        );
      } catch (_) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      await player.pause();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return await player.screenshot(format: 'image/jpeg');
    } finally {
      if (mounted) {
        setState(() {
          _controller = null;
          _player = null;
        });
      }
      await player.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_controller != null)
          Offstage(
            child: SizedBox(
              width: 320,
              height: 180,
              child: Video(controller: _controller!),
            ),
          ),
      ],
    );
  }
}
