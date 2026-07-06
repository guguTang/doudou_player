import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.player,
    required this.subtitleLabel,
    required this.onSubtitlePressed,
    required this.onPickZhSubtitle,
    required this.onPickEnSubtitle,
    required this.hasZhSubtitle,
    required this.hasEnSubtitle,
  });

  final Player player;
  final String subtitleLabel;
  final VoidCallback onSubtitlePressed;
  final VoidCallback onPickZhSubtitle;
  final VoidCallback onPickEnSubtitle;
  final bool hasZhSubtitle;
  final bool hasEnSubtitle;

  String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final maxMs = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;
            final value = position.inMilliseconds
                .clamp(0, duration.inMilliseconds)
                .toDouble();

            return Container(
              color: Colors.black.withValues(alpha: 0.55),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _format(position),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Expanded(
                        child: Slider(
                          value: value,
                          max: maxMs,
                          onChanged: duration.inMilliseconds > 0
                              ? (v) => player.seek(
                                    Duration(milliseconds: v.round()),
                                  )
                              : null,
                        ),
                      ),
                      Text(
                        _format(duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: '选择中文字幕',
                        onPressed: onPickZhSubtitle,
                        icon: Icon(
                          Icons.subtitles,
                          color: hasZhSubtitle ? Colors.white : Colors.white38,
                        ),
                      ),
                      StreamBuilder<bool>(
                        stream: player.stream.playing,
                        builder: (context, snapshot) {
                          final playing = snapshot.data ?? false;
                          return IconButton(
                            iconSize: 42,
                            onPressed: () {
                              player.playOrPause();
                            },
                            icon: Icon(
                              playing ? Icons.pause_circle : Icons.play_circle,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: '选择英文字幕',
                        onPressed: onPickEnSubtitle,
                        icon: Icon(
                          Icons.subtitles_outlined,
                          color: hasEnSubtitle ? Colors.white : Colors.white38,
                        ),
                      ),
                      TextButton(
                        onPressed: onSubtitlePressed,
                        child: Text(
                          '字幕: $subtitleLabel',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
