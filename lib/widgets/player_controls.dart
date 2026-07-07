import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'player_seek_bar.dart';

class PlayerControls extends StatefulWidget {
  const PlayerControls({
    super.key,
    required this.player,
    required this.subtitleLabel,
    required this.onSubtitlePressed,
    required this.onPickZhSubtitle,
    required this.onPickEnSubtitle,
    required this.hasZhSubtitle,
    required this.hasEnSubtitle,
    required this.isFullscreen,
    required this.isLocked,
    required this.onFullscreenToggle,
    required this.onLockToggle,
    this.onUserInteraction,
  });

  final Player player;
  final String subtitleLabel;
  final VoidCallback onSubtitlePressed;
  final VoidCallback onPickZhSubtitle;
  final VoidCallback onPickEnSubtitle;
  final bool hasZhSubtitle;
  final bool hasEnSubtitle;
  final bool isFullscreen;
  final bool isLocked;
  final VoidCallback onFullscreenToggle;
  final VoidCallback onLockToggle;
  final VoidCallback? onUserInteraction;

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  void _notifyInteraction() {
    widget.onUserInteraction?.call();
  }

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
      stream: widget.player.stream.position,
      initialData: widget.player.state.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          initialData: widget.player.state.duration,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;

            return Material(
              color: Colors.black.withValues(alpha: 0.85),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _format(position),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PlayerSeekBar(
                            player: widget.player,
                            enabled: !widget.isLocked,
                            onInteraction: _notifyInteraction,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _format(duration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          tooltip: '选择中文字幕',
                          onPressed: widget.isLocked
                              ? null
                              : () {
                                  _notifyInteraction();
                                  widget.onPickZhSubtitle();
                                },
                          icon: Icon(
                            Icons.subtitles,
                            color: widget.hasZhSubtitle
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                        StreamBuilder<bool>(
                          stream: widget.player.stream.playing,
                          initialData: widget.player.state.playing,
                          builder: (context, snapshot) {
                            final playing = snapshot.data ?? false;
                            return IconButton(
                              iconSize: 42,
                              onPressed: widget.isLocked
                                  ? null
                                  : () {
                                      _notifyInteraction();
                                      widget.player.playOrPause();
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
                          onPressed: widget.isLocked
                              ? null
                              : () {
                                  _notifyInteraction();
                                  widget.onPickEnSubtitle();
                                },
                          icon: Icon(
                            Icons.subtitles_outlined,
                            color: widget.hasEnSubtitle
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.isLocked
                              ? null
                              : () {
                                  _notifyInteraction();
                                  widget.onSubtitlePressed();
                                },
                          child: Text(
                            '字幕: ${widget.subtitleLabel}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: widget.isFullscreen ? '退出全屏' : '全屏',
                          onPressed: widget.isLocked
                              ? null
                              : () {
                                  _notifyInteraction();
                                  widget.onFullscreenToggle();
                                },
                          icon: Icon(
                            widget.isFullscreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          tooltip: widget.isLocked ? '解锁' : '锁定',
                          onPressed: () {
                            _notifyInteraction();
                            widget.onLockToggle();
                          },
                          icon: Icon(
                            widget.isLocked ? Icons.lock : Icons.lock_open,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
