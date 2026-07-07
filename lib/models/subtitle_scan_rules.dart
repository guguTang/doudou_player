class SubtitleScanRules {
  const SubtitleScanRules({
    required this.zhSuffixes,
    required this.enSuffixes,
  });

  static const defaultZhSuffixes = [
    '.zh.srt',
    '.zh-cn.srt',
    '.zh-hans.srt',
    '.chinese.srt',
  ];

  static const defaultEnSuffixes = [
    '.en.srt',
    '.eng.srt',
    '.english.srt',
  ];

  static const defaults = SubtitleScanRules(
    zhSuffixes: defaultZhSuffixes,
    enSuffixes: defaultEnSuffixes,
  );

  final List<String> zhSuffixes;
  final List<String> enSuffixes;

  SubtitleScanRules copyWith({
    List<String>? zhSuffixes,
    List<String>? enSuffixes,
  }) {
    return SubtitleScanRules(
      zhSuffixes: zhSuffixes ?? this.zhSuffixes,
      enSuffixes: enSuffixes ?? this.enSuffixes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zhSuffixes': zhSuffixes,
      'enSuffixes': enSuffixes,
    };
  }

  factory SubtitleScanRules.fromJson(Map<String, dynamic> json) {
    return SubtitleScanRules(
      zhSuffixes: _parseSuffixList(json['zhSuffixes'], defaultZhSuffixes),
      enSuffixes: _parseSuffixList(json['enSuffixes'], defaultEnSuffixes),
    );
  }

  static List<String> _parseSuffixList(
    Object? raw,
    List<String> fallback,
  ) {
    if (raw is! List) {
      return List.unmodifiable(fallback);
    }

    final parsed = raw
        .whereType<String>()
        .map(normalizeSuffix)
        .where(isValidSuffix)
        .toSet()
        .toList();

    if (parsed.isEmpty) {
      return List.unmodifiable(fallback);
    }
    return List.unmodifiable(parsed);
  }

  static String normalizeSuffix(String raw) {
    var suffix = raw.trim().toLowerCase();
    if (suffix.isEmpty) {
      return suffix;
    }
    if (!suffix.startsWith('.')) {
      suffix = '.$suffix';
    }
    return suffix;
  }

  static bool isValidSuffix(String suffix) {
    return suffix.startsWith('.') &&
        suffix.endsWith('.srt') &&
        suffix.length > '.srt'.length;
  }
}
