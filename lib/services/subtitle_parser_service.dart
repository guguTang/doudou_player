import 'dart:convert';
import 'dart:io';

import 'package:subtitle/subtitle.dart';

class SubtitleCue {
  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });

  final Duration start;
  final Duration end;
  final String text;
}

class SubtitleParserService {
  SubtitleParserService(List<SubtitleCue> cues) : _cues = List.unmodifiable(cues);

  final List<SubtitleCue> _cues;

  static Future<SubtitleParserService?> fromFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }

    final bytes = await file.readAsBytes();
    late final String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes, allowInvalid: true);
    }

    final parser = SubtitleParser(
      SubtitleObject(data: content, type: SubtitleType.srt),
    );
    final subtitles = parser.parsing();

    final cues = subtitles
        .map(
          (item) => SubtitleCue(
            start: item.start,
            end: item.end,
            text: item.data.trim(),
          ),
        )
        .where((cue) => cue.text.isNotEmpty)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return SubtitleParserService(cues);
  }

  String? cueAt(Duration position) {
    for (final cue in _cues) {
      if (position >= cue.start && position <= cue.end) {
        return cue.text;
      }
    }
    return null;
  }
}
