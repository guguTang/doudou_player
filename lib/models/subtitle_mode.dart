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

  String get settingsLabel {
    switch (this) {
      case SubtitleMode.off:
        return '关闭';
      case SubtitleMode.chinese:
        return '仅中文';
      case SubtitleMode.english:
        return '仅英文';
      case SubtitleMode.both:
        return '中英双语';
    }
  }

  static SubtitleMode fromName(String? name) {
    return SubtitleMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => SubtitleMode.both,
    );
  }
}
