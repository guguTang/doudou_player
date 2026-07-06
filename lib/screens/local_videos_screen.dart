import 'package:flutter/material.dart';

import '../models/video_item.dart';
import '../services/library_service.dart';
import '../widgets/video_list_tile.dart';
import 'player_screen.dart';

class LocalVideosScreen extends StatefulWidget {
  const LocalVideosScreen({super.key, required this.libraryService});

  final LibraryService libraryService;

  @override
  State<LocalVideosScreen> createState() => _LocalVideosScreenState();
}

class _LocalVideosScreenState extends State<LocalVideosScreen> {
  @override
  void initState() {
    super.initState();
    widget.libraryService.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    widget.libraryService.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addVideos() async {
    final added = await widget.libraryService.pickAndAddVideos();
    if (!mounted) {
      return;
    }
    if (added > 0) {
      _showSnackBar('已添加 $added 个视频');
    }
  }

  Future<void> _scanDirectory() async {
    final added = await widget.libraryService.pickAndScanDirectory();
    if (!mounted) {
      return;
    }
    if (added > 0) {
      _showSnackBar('扫描并添加 $added 个视频');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openPlayer(VideoItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlayerScreen(
          item: item,
          libraryService: widget.libraryService,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _showItemActions(VideoItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.subtitles),
                title: const Text('选择中文字幕'),
                onTap: () => Navigator.pop(context, 'zh'),
              ),
              ListTile(
                leading: const Icon(Icons.subtitles_outlined),
                title: const Text('选择英文字幕'),
                onTap: () => Navigator.pop(context, 'en'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('从列表移除'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case 'zh':
        final path = await widget.libraryService.pickSubtitleFile();
        if (path != null) {
          await widget.libraryService.updateSubtitles(
            id: item.id,
            zhSubPath: path,
          );
        }
      case 'en':
        final path = await widget.libraryService.pickSubtitleFile();
        if (path != null) {
          await widget.libraryService.updateSubtitles(
            id: item.id,
            enSubPath: path,
          );
        }
      case 'delete':
        await widget.libraryService.removeVideo(item.id);
    }
  }

  Future<void> _showAddMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.video_file_outlined),
                title: const Text('添加视频'),
                onTap: () => Navigator.pop(context, 'files'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('扫描文件夹'),
                onTap: () => Navigator.pop(context, 'folder'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == 'files') {
      await _addVideos();
    } else if (action == 'folder') {
      await _scanDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.libraryService.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地视频'),
      ),
      body: !widget.libraryService.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      const Text('暂无视频，点击右下角添加'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return VideoListTile(
                      item: item,
                      onTap: () => _openPlayer(item),
                      onLongPress: () => _showItemActions(item),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        child: const Icon(Icons.add),
      ),
    );
  }
}
