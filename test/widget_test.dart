import 'package:flutter_test/flutter_test.dart';

import 'package:doudou_player/models/subtitle_mode.dart';

void main() {
  test('SubtitleMode cycles through all modes', () {
    expect(SubtitleMode.off.next, SubtitleMode.chinese);
    expect(SubtitleMode.chinese.next, SubtitleMode.english);
    expect(SubtitleMode.english.next, SubtitleMode.both);
    expect(SubtitleMode.both.next, SubtitleMode.off);
  });
}
