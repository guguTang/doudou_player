import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/subtitle_mode.dart';
import '../models/video_item.dart';
import '../services/library_service.dart';
import '../services/subtitle_parser_service.dart';
import '../widgets/dual_subtitle_overlay.dart';
import '../widgets/player_controls.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.item,
    required this.libraryService,
  });

  final VideoItem item;
  final LibraryService libraryService;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  late VideoItem _item;

  SubtitleMode _subtitleMode = SubtitleMode.off;
  SubtitleParserService? _zhParser;
  SubtitleParserService? _enParser;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _player = Player();
    _videoController = VideoController(_player);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
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
    final path = await widget.libraryService.pickSubtitleFile();
    if (path == null) {
      return;
    }

    await widget.libraryService.updateSubtitles(
      id: _item.id,
      zhSubPath: isChinese ? path : null,
      enSubPath: isChinese ? null : path,
    );
    await _refreshItem();
  }

  void _cycleSubtitleMode() {
    setState(() {
      _subtitleMode = _subtitleMode.next;
    });

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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildVideoArea()),
            PlayerControls(
              player: _player,
              subtitleLabel: _subtitleMode.label,
              onSubtitlePressed: _cycleSubtitleMode,
              onPickZhSubtitle: () => _pickSubtitle(isChinese: true),
              onPickEnSubtitle: () => _pickSubtitle(isChinese: false),
              hasZhSubtitle: _item.zhSubPath != null,
              hasEnSubtitle: _item.enSubPath != null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              _item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
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
          child: Video(
            controller: _videoController,
            controls: NoVideoControls,
          ),
        ),
        DualSubtitleOverlay(
          player: _player,
          mode: _subtitleMode,
          zhParser: _zhParser,
          enParser: _enParser,
        ),
      ],
    );
  }
}
