import 'dart:typed_data';

/// 通过挂载隐藏 [Video] 组件完成 mpv 截图的协调器。
class ThumbnailCaptureCoordinator {
  ThumbnailCaptureCoordinator._();

  static final ThumbnailCaptureCoordinator instance =
      ThumbnailCaptureCoordinator._();

  Future<Uint8List?> Function(String videoPath, int seekSecond)? _capture;

  void register(
    Future<Uint8List?> Function(String videoPath, int seekSecond) capture,
  ) {
    _capture = capture;
  }

  void unregister() {
    _capture = null;
  }

  Future<Uint8List?> captureFrame(String videoPath, int seekSecond) async {
    final capture = _capture;
    if (capture == null) {
      return null;
    }
    return capture(videoPath, seekSecond);
  }
}
