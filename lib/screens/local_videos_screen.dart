import 'package:flutter/material.dart';

import '../models/video_collection.dart';
import '../models/video_item.dart';
import '../services/collection_service.dart';
import '../services/library_service.dart';
import '../services/settings_service.dart';
import '../widgets/collection_list_tile.dart';
import '../widgets/video_list_tile.dart';
import 'collection_detail_screen.dart';
import 'player_screen.dart';

enum _LibraryView { all, collections, folders }

class LocalVideosScreen extends StatefulWidget {
  const LocalVideosScreen({
    super.key,
    required this.libraryService,
    required this.collectionService,
    required this.settingsService,
  });

  final LibraryService libraryService;
  final CollectionService collectionService;
  final SettingsService settingsService;

  @override
  State<LocalVideosScreen> createState() => _LocalVideosScreenState();
}

class _LocalVideosScreenState extends State<LocalVideosScreen> {
  final Set<String> _selectedIds = {};
  bool _selecting = false;
  _LibraryView _view = _LibraryView.all;

  @override
  void initState() {
    super.initState();
    widget.libraryService.addListener(_onLibraryChanged);
    widget.collectionService.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    widget.libraryService.removeListener(_onLibraryChanged);
    widget.collectionService.removeListener(_onLibraryChanged);
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

  Future<void> _openCollection(VideoCollection collection) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CollectionDetailScreen(
          collection: collection,
          libraryService: widget.libraryService,
          collectionService: widget.collectionService,
          settingsService: widget.settingsService,
        ),
      ),
    );
  }

  Future<void> _createCollection() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新建合集'),
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
              child: const Text('创建'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty || !mounted) {
      return;
    }

    await widget.collectionService.createManualCollection(name);
    if (!mounted) {
      return;
    }
    _showSnackBar('已创建合集「$name」');
  }

  Future<void> _addSelectedToCollection() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final collections = widget.collectionService.manualCollections;
    if (collections.isEmpty) {
      final create = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('暂无合集'),
            content: const Text('还没有自定义合集，是否创建一个？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('创建'),
              ),
            ],
          );
        },
      );

      if (create == true && mounted) {
        await _createCollection();
        if (mounted) {
          await _addSelectedToCollection();
        }
      }
      return;
    }

    final selectedCollectionIds = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加到合集'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: collections.map((collection) {
                    return CheckboxListTile(
                      title: Text(collection.name),
                      subtitle: Text('${collection.videoIds.length} 个视频'),
                      value: selectedCollectionIds.contains(collection.id),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            selectedCollectionIds.add(collection.id);
                          } else {
                            selectedCollectionIds.remove(collection.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: selectedCollectionIds.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    for (final collectionId in selectedCollectionIds) {
      await widget.collectionService.addVideosToCollection(
        collectionId,
        _selectedIds,
      );
    }

    _exitSelectionMode();
    _showSnackBar('已添加到 ${selectedCollectionIds.length} 个合集');
  }

  Future<void> _addVideoToCollection(VideoItem item) async {
    final collections = widget.collectionService.manualCollections;
    if (collections.isEmpty) {
      final create = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('暂无合集'),
            content: const Text('还没有自定义合集，是否创建一个？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('创建'),
              ),
            ],
          );
        },
      );

      if (create == true && mounted) {
        await _createCollection();
        if (mounted) {
          await _addVideoToCollection(item);
        }
      }
      return;
    }

    final selectedCollectionIds = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加到合集'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: collections.map((collection) {
                    final alreadyIn = collection.videoIds.contains(item.id);
                    return CheckboxListTile(
                      title: Text(collection.name),
                      subtitle: Text(
                        alreadyIn ? '已在合集中' : '${collection.videoIds.length} 个视频',
                      ),
                      value: selectedCollectionIds.contains(collection.id),
                      onChanged: alreadyIn
                          ? null
                          : (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedCollectionIds.add(collection.id);
                                } else {
                                  selectedCollectionIds.remove(collection.id);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: selectedCollectionIds.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    for (final collectionId in selectedCollectionIds) {
      await widget.collectionService.addVideosToCollection(
        collectionId,
        {item.id},
      );
    }

    _showSnackBar('已添加到 ${selectedCollectionIds.length} 个合集');
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
                leading: const Icon(Icons.collections_bookmark_outlined),
                title: const Text('添加到合集'),
                onTap: () => Navigator.pop(context, 'add_to_collection'),
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
      case 'add_to_collection':
        await _addVideoToCollection(item);
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

  String get _appBarTitle {
    switch (_view) {
      case _LibraryView.all:
        return '本地视频';
      case _LibraryView.collections:
        return '合集';
      case _LibraryView.folders:
        return '文件夹';
    }
  }

  PreferredSizeWidget _buildAppBar(List<VideoItem> items) {
    if (!_selecting || _view != _LibraryView.all) {
      return AppBar(
        title: Text(_appBarTitle),
        actions: [
          if (_view == _LibraryView.all && items.isNotEmpty)
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
    if (!_selecting || _view != _LibraryView.all) {
      return null;
    }

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _addSelectedToCollection,
              icon: const Icon(Icons.collections_bookmark_outlined),
              label: const Text('添加到合集'),
            ),
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

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SegmentedButton<_LibraryView>(
        segments: const [
          ButtonSegment(value: _LibraryView.all, label: Text('全部')),
          ButtonSegment(value: _LibraryView.collections, label: Text('合集')),
          ButtonSegment(value: _LibraryView.folders, label: Text('文件夹')),
        ],
        selected: {_view},
        onSelectionChanged: (selection) {
          setState(() {
            _view = selection.first;
            _exitSelectionMode();
          });
        },
      ),
    );
  }

  Widget _buildAllVideosBody(List<VideoItem> items) {
    if (items.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
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
          onLongPress:
              _selecting ? null : () => _showItemActions(item),
        );
      },
    );
  }

  Widget _buildCollectionsBody(List<VideoCollection> collections) {
    if (collections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text('暂无合集，点击右下角创建'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        return CollectionListTile(
          collection: collection,
          onTap: () => _openCollection(collection),
        );
      },
    );
  }

  Widget _buildFoldersBody(List<VideoCollection> folders) {
    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text('扫描文件夹后在此显示'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return CollectionListTile(
          collection: folder,
          onTap: () => _openCollection(folder),
        );
      },
    );
  }

  Widget _buildBody(List<VideoItem> items) {
    switch (_view) {
      case _LibraryView.all:
        return _buildAllVideosBody(items);
      case _LibraryView.collections:
        return _buildCollectionsBody(widget.collectionService.manualCollections);
      case _LibraryView.folders:
        return _buildFoldersBody(widget.collectionService.scanRootCollections);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.libraryService.items;
    final showFab = !_selecting;

    return Scaffold(
      appBar: _buildAppBar(items),
      body: !widget.libraryService.isLoaded ||
              !widget.collectionService.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSegmentedControl(),
                Expanded(child: _buildBody(items)),
              ],
            ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _view == _LibraryView.collections
                  ? _createCollection
                  : _showAddMenu,
              child: Icon(
                _view == _LibraryView.collections ? Icons.create_new_folder : Icons.add,
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}
