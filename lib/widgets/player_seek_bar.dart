import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

/// 桌面端友好的播放进度条，使用 Listener 处理拖拽。
class PlayerSeekBar extends StatefulWidget {
  const PlayerSeekBar({
    super.key,
    required this.player,
    required this.enabled,
    this.onInteraction,
  });

  final Player player;
  final bool enabled;
  final VoidCallback? onInteraction;

  @override
  State<PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar> {
  static const _barHeight = 4.0;
  static const _barHoverHeight = 6.0;
  static const _hitHeight = 36.0;

  bool _hover = false;
  bool _dragging = false;
  double _dragPercent = 0;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _position = widget.player.state.position;
    _duration = widget.player.state.duration;
    _subscriptions.addAll([
      widget.player.stream.position.listen((value) {
        if (!_dragging && mounted) {
          setState(() => _position = value);
        }
      }),
      widget.player.stream.duration.listen((value) {
        if (mounted) {
          setState(() => _duration = value);
        }
      }),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  double _percentFromDx(double dx, double width) {
    if (width <= 0) {
      return 0;
    }
    return (dx / width).clamp(0.0, 1.0);
  }

  double get _positionPercent {
    if (_duration.inMilliseconds <= 0) {
      return 0;
    }
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  double get _displayPercent => _dragging ? _dragPercent : _positionPercent;

  void _seekToPercent(double percent) {
    if (_duration.inMilliseconds <= 0) {
      return;
    }
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * percent).round(),
    );
    widget.player.seek(target);
    setState(() => _position = target);
  }

  void _onPointerDown(PointerDownEvent event, double width) {
    if (!widget.enabled || _duration.inMilliseconds <= 0) {
      return;
    }
    widget.onInteraction?.call();
    final percent = _percentFromDx(event.localPosition.dx, width);
    setState(() {
      _dragging = true;
      _dragPercent = percent;
    });
  }

  void _onPointerMove(PointerMoveEvent event, double width) {
    if (!widget.enabled || !_dragging) {
      return;
    }
    widget.onInteraction?.call();
    setState(() {
      _dragPercent = _percentFromDx(event.localPosition.dx, width);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.enabled || !_dragging) {
      return;
    }
    _seekToPercent(_dragPercent);
    setState(() => _dragging = false);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && _duration.inMilliseconds > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return MouseRegion(
          cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: active
              ? (_) => setState(() => _hover = true)
              : null,
          onExit: active ? (_) => setState(() => _hover = false) : null,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _onPointerDown(event, width),
            onPointerMove: (event) => _onPointerMove(event, width),
            onPointerUp: _onPointerUp,
            onPointerCancel: (_) {
              if (_dragging) {
                setState(() => _dragging = false);
              }
            },
            child: SizedBox(
              height: _hitHeight,
              width: width,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: width,
                  height: _hover || _dragging ? _barHoverHeight : _barHeight,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _displayPercent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
