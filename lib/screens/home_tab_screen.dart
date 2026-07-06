import 'package:flutter/material.dart';

import '../services/library_service.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({
    super.key,
    required this.libraryService,
    required this.onOpenLocalVideos,
  });

  final LibraryService libraryService;
  final VoidCallback onOpenLocalVideos;

  @override
  Widget build(BuildContext context) {
    final count = libraryService.items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('豆豆播放器'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '本地视频播放器',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '支持 SRT 中英字幕单独或同时显示',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('本地视频'),
              subtitle: Text('共 $count 个视频'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenLocalVideos,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.video_file_outlined),
                  title: const Text('添加视频'),
                  onTap: () async {
                    final added = await libraryService.pickAndAddVideos();
                    if (context.mounted && added > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已添加 $added 个视频')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('扫描文件夹'),
                  onTap: () async {
                    final added = await libraryService.pickAndScanDirectory();
                    if (context.mounted && added > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('扫描并添加 $added 个视频')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
