import 'package:flutter_test/flutter_test.dart';

import 'package:doudou_player/services/subtitle_matcher.dart';

void main() {
  test('isVideoFile recognizes common extensions', () {
    expect(SubtitleMatcher.isVideoFile('/path/movie.mp4'), isTrue);
    expect(SubtitleMatcher.isVideoFile('/path/movie.MKV'), isTrue);
    expect(SubtitleMatcher.isVideoFile('/path/movie.srt'), isFalse);
  });
}
