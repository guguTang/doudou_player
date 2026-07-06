enum SubtitleMode {
  off,
  chinese,
  english,
  both;

  SubtitleMode get next {
    final values = SubtitleMode.values;
    return values[(index + 1) % values.length];
  }

  String get label {
    switch (this) {
      case SubtitleMode.off:
        return '关';
      case SubtitleMode.chinese:
        return '中';
      case SubtitleMode.english:
        return '英';
      case SubtitleMode.both:
        return '双语';
    }
  }
}
