import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 播放器全屏时的系统 UI 与屏幕方向控制。
class PlayerChrome {
  static bool get supportsOrientationLock =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> enterFullscreen() async {
    if (supportsOrientationLock) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static Future<void> exitFullscreen() async {
    if (supportsOrientationLock) {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
