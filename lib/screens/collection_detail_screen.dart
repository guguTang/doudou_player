import 'package:flutter/material.dart';

import '../models/video_collection.dart';
import '../models/video_item.dart';
import '../services/collection_service.dart';
import '../services/library_service.dart';
import '../services/settings_service.dart';
import '../widgets/video_list_tile.dart';
import 'player_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.collection,
    required this.libraryService,
    required this.collectionService,
    required this.settingsService,
  });

  final VideoCollection collection;
  final LibraryService libraryService;
  final CollectionService collectionService;
  final SettingsService settingsService;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final Set<String> _selectedIds = {};
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    widget.libraryService.addListener(_onDataChanged);
    widget.collectionService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    widget.libraryService.removeListener(_onDataChanged);
    widget.collectionService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
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

  VideoCollection? get _collection =>
      widget.collectionService.findById(widget.collection.id);

  List<VideoItem> get _items {
    final collection = _collection;
    if (collection == null) {
      return const [];
    }
    return widget.collectionService.videosInCollection(
      collection.id,
      widget.libraryService,
    );
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

  Future<void> _confirmBatchRemoveFromCollection() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('从合集移除'),
          content: Text('确定从合集中移除 $count 个视频吗？\n（不会从视频库中删除）'),
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

    final collection = _collection;
    if (collection == null) {
      return;
    }

    await widget.collectionService.removeVideosFromCollection(
      collection.id,
      _selectedIds,
    );
    if (!mounted) {
      return;
    }

    _exitSelectionMode();
    _showSnackBar('已从合集中移除 $count 个视频');
  }

  Future<void> _confirmBatchDeleteFromLibrary() async {
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

  Future<void> _showRenameDialog() async {
    final collection = _collection;
    if (collection == null || collection.type != VideoCollectionType.manual) {
      return;
    }

    final controller = TextEditingController(text: collection.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重命名合集'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '合集名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty || !mounted) {
      return;
    }

    await widget.collectionService.renameCollection(collection.id, newName);
  }

  Future<void> _confirmDeleteCollection() async {
    final collection = _collection;
    if (collection == null || collection.type != VideoCollectionType.manual) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除合集'),
          content: const Text('确定删除此合集吗？\n（视频仍保留在视频库中）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await widget.collectionService.deleteCollection(collection.id);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
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
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('从合集移除'),
                onTap: () => Navigator.pop(context, 'remove_from_collection'),
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

    final collection = _collection;
    if (collection == null) {
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
      case 'remove_from_collection':
        await widget.collectionService.removeVideosFromCollection(
          collection.id,
          {item.id},
        );
      case 'delete':
        await widget.libraryService.removeVideo(item.id);
    }
  }

  PreferredSizeWidget _buildAppBar(List<VideoItem> items) {
    final collection = _collection;
    if (collection == null) {
      return AppBar(title: const Text('合集'));
    }

    if (!_selecting) {
      return AppBar(
        title: Text(collection.name),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: '多选',
              onPressed: () => _enterSelectionMode(),
              icon: const Icon(Icons.checklist),
            ),
          if (collection.type == VideoCollectionType.manual)
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'rename':
                    _showRenameDialog();
                  case 'delete':
                    _confirmDeleteCollection();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('重命名')),
                PopupMenuItem(value: 'delete', child: Text('删除合集')),
              ],
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
              onPressed:
                  _selectedIds.isEmpty ? null : _confirmBatchRemoveFromCollection,
              icon: const Icon(Icons.folder_off_outlined),
              label: const Text('从合集移除'),
            ),
            TextButton.icon(
              onPressed:
                  _selectedIds.isEmpty ? null : _confirmBatchDeleteFromLibrary,
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
    final collection = _collection;
    final items = _items;

    if (collection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('合集')),
        body: const Center(child: Text('合集不存在或已被删除')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(items),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (collection.type == VideoCollectionType.scanRoot &&
              collection.scanRootPath != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                collection.scanRootPath!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: items.isEmpty
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
                        const Text('此合集暂无视频'),
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
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}
