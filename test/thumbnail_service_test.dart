import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:doudou_player/services/thumbnail_service.dart';

void main() {
  test('randomSeekSecond picks within 4-10 seconds for long videos', () {
    final random = Random(1);
    final second = ThumbnailService.randomSeekSecond(
      const Duration(seconds: 120),
      random,
    );
    expect(second, inInclusiveRange(4, 10));
  });

  test('randomSeekSecond uses middle for short videos', () {
    final random = Random(1);
    expect(
      ThumbnailService.randomSeekSecond(const Duration(seconds: 3), random),
      1,
    );
    expect(
      ThumbnailService.randomSeekSecond(const Duration(seconds: 8), random),
      inInclusiveRange(4, 8),
    );
  });

  test('randomSeekSecond returns 0 for empty duration', () {
    expect(
      ThumbnailService.randomSeekSecond(Duration.zero, Random()),
      0,
    );
  });
}
