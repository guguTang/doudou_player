import 'package:flutter/material.dart';

import '../models/video_item.dart';
import '../services/library_service.dart';
import '../services/settings_service.dart';
import '../widgets/video_list_tile.dart';
import 'player_screen.dart';

class LocalVideosScreen extends StatefulWidget {
  const LocalVideosScreen({
    super.key,
    required this.libraryService,
    required this.settingsService,
  });

  final LibraryService libraryService;
  final SettingsService settingsService;

  @override
  State<LocalVideosScreen> createState() => _LocalVideosScreenState();
}

class _LocalVideosScreenState extends State<LocalVideosScreen> {
  final Set<String> _selectedIds = {};
  bool _selecting = false;

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
      setState(() {
        _selectedIds.removeWhere(
          (id) => widget.libraryService.findById(id) == null,
        );
        if (_selectedIds.isEmpty && _selecting) {
          _selecting = false;
        }
      });
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
  }

  void _enterSelectionMode([String? initialId]) {
    setState(() {
      _selecting = true;
      _selectedIds.clear();
      if (initialId != null) {
        _selectedIds.add(initialId);
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _selecting = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<VideoItem> items) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(items.map((item) => item.id));
    });
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
    } else {
      _showSnackBar('未扫描到新视频');
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
          settingsService: widget.settingsService,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _confirmBatchDelete() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认移除'),
          content: Text('确定从列表中移除 $count 个视频吗？\n（不会删除本地文件）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final removed = await widget.libraryService.removeVideos(_selectedIds);
    if (!mounted) {
      return;
    }

    _exitSelectionMode();
    _showSnackBar('已移除 $removed 个视频');
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
                leading: const Icon(Icons.checklist),
                title: const Text('多选'),
                onTap: () => Navigator.pop(context, 'select'),
              ),
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
      case 'select':
        _enterSelectionMode(item.id);
      case 'zh':
        final picked = await widget.libraryService.pickSubtitleFile();
        if (picked != null) {
          await widget.libraryService.updateSubtitles(
            id: item.id,
            zhSubPath: picked.path,
            zhSubBookmark: picked.bookmark,
          );
        }
      case 'en':
        final picked = await widget.libraryService.pickSubtitleFile();
        if (picked != null) {
          await widget.libraryService.updateSubtitles(
            id: item.id,
            enSubPath: picked.path,
            enSubBookmark: picked.bookmark,
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

  PreferredSizeWidget _buildAppBar(List<VideoItem> items) {
    if (!_selecting) {
      return AppBar(
        title: const Text('本地视频'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: '多选',
              onPressed: () => _enterSelectionMode(),
              icon: const Icon(Icons.checklist),
            ),
        ],
      );
    }

    final allSelected =
        items.isNotEmpty && _selectedIds.length == items.length;

    return AppBar(
      leading: IconButton(
        tooltip: '取消',
        onPressed: _exitSelectionMode,
        icon: const Icon(Icons.close),
      ),
      title: Text('已选 ${_selectedIds.length} 项'),
      actions: [
        TextButton(
          onPressed: items.isEmpty
              ? null
              : () {
                  if (allSelected) {
                    setState(_selectedIds.clear);
                  } else {
                    _selectAll(items);
                  }
                },
          child: Text(allSelected ? '取消全选' : '全选'),
        ),
      ],
    );
  }

  Widget? _buildBottomBar() {
    if (!_selecting) {
      return null;
    }

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _confirmBatchDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('移除'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.libraryService.items;

    return Scaffold(
      appBar: _buildAppBar(items),
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
                      selecting: _selecting,
                      selected: _selectedIds.contains(item.id),
                      onTap: () {
                        if (_selecting) {
                          _toggleSelection(item.id);
                        } else {
                          _openPlayer(item);
                        }
                      },
                      onLongPress: _selecting
                          ? null
                          : () => _showItemActions(item),
                    );
                  },
                ),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              onPressed: _showAddMenu,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}
