import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../models/subtitle_mode.dart';
import '../services/subtitle_parser_service.dart';

class DualSubtitleOverlay extends StatefulWidget {
  const DualSubtitleOverlay({
    super.key,
    required this.player,
    required this.mode,
    this.zhParser,
    this.enParser,
  });

  final Player player;
  final SubtitleMode mode;
  final SubtitleParserService? zhParser;
  final SubtitleParserService? enParser;

  @override
  State<DualSubtitleOverlay> createState() => _DualSubtitleOverlayState();
}

class _DualSubtitleOverlayState extends State<DualSubtitleOverlay> {
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.player.stream.position.listen((position) {
      if (!mounted) {
        return;
      }
      final delta = (position - _position).inMilliseconds.abs();
      if (delta < 80 && widget.mode == SubtitleMode.off) {
        return;
      }
      setState(() => _position = position);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == SubtitleMode.off) {
      return const SizedBox.shrink();
    }

    final zhText = widget.mode == SubtitleMode.english
        ? null
        : widget.zhParser?.cueAt(_position);
    final enText = widget.mode == SubtitleMode.chinese
        ? null
        : widget.enParser?.cueAt(_position);

    if ((zhText == null || zhText.isEmpty) &&
        (enText == null || enText.isEmpty)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (enText != null && enText.isNotEmpty)
                _SubtitleLine(text: enText),
              if (enText != null &&
                  enText.isNotEmpty &&
                  zhText != null &&
                  zhText.isNotEmpty)
                const SizedBox(height: 8),
              if (zhText != null && zhText.isNotEmpty)
                _SubtitleLine(text: zhText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtitleLine extends StatelessWidget {
  const _SubtitleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.35,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
          ],
        ),
      ),
    );
  }
}
