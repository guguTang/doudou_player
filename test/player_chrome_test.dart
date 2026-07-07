import 'package:flutter_test/flutter_test.dart';

import 'package:doudou_player/services/player_chrome.dart';

void main() {
  test('PlayerChrome reports orientation lock only on mobile', () {
    // 在测试环境（非 iOS/Android）应为 false。
    expect(PlayerChrome.supportsOrientationLock, isFalse);
  });
}
