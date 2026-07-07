import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/subtitle_mode.dart';
import '../models/video_item.dart';
import '../services/library_service.dart';
import '../services/player_chrome.dart';
import '../services/secure_file_access.dart';
import '../services/settings_service.dart';
import '../services/subtitle_parser_service.dart';
import '../widgets/dual_subtitle_overlay.dart';
import '../widgets/player_controls.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.item,
    required this.libraryService,
    required this.settingsService,
  });

  final VideoItem item;
  final LibraryService libraryService;
  final SettingsService settingsService;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  late VideoItem _item;

  SubtitleMode _subtitleMode = SubtitleMode.both;
  SubtitleParserService? _zhParser;
  SubtitleParserService? _enParser;
  bool _loading = true;
  String? _error;
  bool _isFullscreen = false;
  bool _isLocked = false;
  bool _overlayVisible = true;
  Timer? _overlayHideTimer;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _subtitleMode = widget.settingsService.defaultSubtitleMode;
    widget.settingsService.addListener(_onSettingsChanged);
    _player = Player();
    _videoController = VideoController(_player);
    _initialize();
  }

  void _onSettingsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _subtitleMode = widget.settingsService.defaultSubtitleMode;
    });
  }

  @override
  void dispose() {
    _overlayHideTimer?.cancel();
    widget.settingsService.removeListener(_onSettingsChanged);
    if (_isFullscreen) {
      PlayerChrome.exitFullscreen();
    }
    if (!_released) {
      _stopAndRelease();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final accessible = await widget.libraryService.ensureAccess(_item);
      if (!accessible) {
        _error = SecureFileAccess.enabled &&
                _item.fileBookmark == null &&
                _item.directoryBookmark == null
            ? '无法访问该视频文件。请从列表中删除后重新添加（macOS 需重新选择文件授权）。'
            : '无法访问该视频文件，请确认文件仍存在且有读取权限。';
        return;
      }

      await _loadSubtitles();
      await _player.open(Media(_item.filePath));
      await _player.setSubtitleTrack(SubtitleTrack.no());
      await _player.setVolume(100);
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadSubtitles() async {
    _zhParser = await SubtitleParserService.fromFile(_item.zhSubPath);
    _enParser = await SubtitleParserService.fromFile(_item.enSubPath);
  }

  Future<void> _refreshItem() async {
    final latest = widget.libraryService.findById(_item.id);
    if (latest != null) {
      _item = latest;
      await _loadSubtitles();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _pickSubtitle({required bool isChinese}) async {
    final picked = await widget.libraryService.pickSubtitleFile();
    if (picked == null) {
      return;
    }

    await widget.libraryService.updateSubtitles(
      id: _item.id,
      zhSubPath: isChinese ? picked.path : null,
      enSubPath: isChinese ? null : picked.path,
      zhSubBookmark: isChinese ? picked.bookmark : null,
      enSubBookmark: isChinese ? null : picked.bookmark,
    );
    await _refreshItem();
  }

  void _cycleSubtitleMode() {
    final nextMode = _subtitleMode.next;
    setState(() {
      _subtitleMode = nextMode;
    });
    widget.settingsService.setDefaultSubtitleMode(nextMode);

    if (_subtitleMode == SubtitleMode.chinese && _item.zhSubPath == null) {
      _showMissingSubtitleHint('中文字幕');
    } else if (_subtitleMode == SubtitleMode.english &&
        _item.enSubPath == null) {
      _showMissingSubtitleHint('英文字幕');
    } else if (_subtitleMode == SubtitleMode.both &&
        (_item.zhSubPath == null || _item.enSubPath == null)) {
      _showMissingSubtitleHint('中英字幕');
    }
  }

  void _showMissingSubtitleHint(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('未找到$label，可点击下方按钮手动选择')),
    );
  }

  void _scheduleOverlayHide() {
    _overlayHideTimer?.cancel();
    if (!_isFullscreen ||
        _isLocked ||
        !_overlayVisible ||
        !PlayerChrome.supportsOrientationLock) {
      return;
    }
    _overlayHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isFullscreen && !_isLocked) {
        setState(() => _overlayVisible = false);
      }
    });
  }

  void _onControlsInteraction() {
    if (_isFullscreen && _overlayVisible && !_isLocked) {
      _scheduleOverlayHide();
    }
  }

  void _onVideoTap() {
    if (_isLocked) {
      return;
    }
    if (_isFullscreen) {
      setState(() => _overlayVisible = !_overlayVisible);
      if (_overlayVisible) {
        _scheduleOverlayHide();
      } else {
        _overlayHideTimer?.cancel();
      }
    }
  }

  Future<void> _enterFullscreen() async {
    await PlayerChrome.enterFullscreen();
    if (!mounted) {
      return;
    }
    setState(() {
      _isFullscreen = true;
      _overlayVisible = true;
    });
    _scheduleOverlayHide();
  }

  Future<void> _exitFullscreen() async {
    _overlayHideTimer?.cancel();
    await PlayerChrome.exitFullscreen();
    if (!mounted) {
      return;
    }
    setState(() {
      _isFullscreen = false;
      _overlayVisible = true;
    });
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) {
      await _exitFullscreen();
    } else {
      await _enterFullscreen();
    }
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _overlayVisible = false;
        _overlayHideTimer?.cancel();
      } else if (_isFullscreen) {
        _overlayVisible = true;
        _scheduleOverlayHide();
      } else {
        _overlayVisible = true;
      }
    });
  }

  bool _released = false;

  Future<void> _stopAndRelease() async {
    if (_released) {
      return;
    }
    _released = true;
    await _player.pause();
    await _player.stop();
    await widget.libraryService.releaseAccess();
    await _player.dispose();
  }

  Future<void> _handleBack() async {
    if (_isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('屏幕已锁定，请先解锁')),
      );
      return;
    }
    if (_isFullscreen) {
      await _exitFullscreen();
      return;
    }
    await _stopAndRelease();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  PlayerControls _buildControls() {
    return PlayerControls(
      player: _player,
      subtitleLabel: _subtitleMode.label,
      onSubtitlePressed: _cycleSubtitleMode,
      onPickZhSubtitle: () => _pickSubtitle(isChinese: true),
      onPickEnSubtitle: () => _pickSubtitle(isChinese: false),
      hasZhSubtitle: _item.zhSubPath != null,
      hasEnSubtitle: _item.enSubPath != null,
      isFullscreen: _isFullscreen,
      isLocked: _isLocked,
      onFullscreenToggle: _toggleFullscreen,
      onLockToggle: _toggleLock,
      onUserInteraction: _onControlsInteraction,
    );
  }

  bool get _isDesktopFullscreen =>
      _isFullscreen && !PlayerChrome.supportsOrientationLock;

  bool get _showFullscreenChrome =>
      !_isLocked && (_isDesktopFullscreen || _overlayVisible);

  double get _subtitleBottomPadding =>
      widget.settingsService.subtitleBottomPadding;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isFullscreen) {
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onVideoTap,
            child: _buildVideoArea(),
          ),
          if (_isLocked)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: _buildUnlockButton(),
            )
          else if (_showFullscreenChrome) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildHeader(showFullscreenButton: false),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _buildControls(),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: _buildHeader(showFullscreenButton: true),
        ),
        Expanded(
          child: _buildVideoArea(),
        ),
        SafeArea(
          top: false,
          child: _buildControls(),
        ),
      ],
    );
  }

  Widget _buildUnlockButton() {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(24),
      child: IconButton(
        tooltip: '解锁',
        onPressed: _toggleLock,
        icon: const Icon(Icons.lock, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader({required bool showFullscreenButton}) {
    return Container(
      color: Colors.black.withValues(alpha: _isFullscreen ? 0.45 : 1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _handleBack,
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.arrow_back,
              color: Colors.white,
            ),
            tooltip: _isFullscreen ? '退出全屏' : '返回',
          ),
          Expanded(
            child: Text(
              _item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (showFullscreenButton)
            IconButton(
              tooltip: '全屏',
              onPressed: _isLocked ? null : _enterFullscreen,
              icon: const Icon(Icons.fullscreen, color: Colors.white),
            ),
          IconButton(
            tooltip: _isLocked ? '解锁' : '锁定',
            onPressed: _toggleLock,
            icon: Icon(
              _isLocked ? Icons.lock : Icons.lock_open,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '无法播放视频\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: IgnorePointer(
            child: Video(
              controller: _videoController,
              controls: NoVideoControls,
            ),
          ),
        ),
        DualSubtitleOverlay(
          player: _player,
          mode: _subtitleMode,
          zhParser: _zhParser,
          enParser: _enParser,
          bottomPadding: _subtitleBottomPadding,
          fontSize: widget.settingsService.subtitleFontSize,
          lineSpacing: widget.settingsService.subtitleLineSpacing,
        ),
      ],
    );
  }
}
