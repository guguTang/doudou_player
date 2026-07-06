import 'package:flutter/material.dart';

import '../models/video_item.dart';

class VideoListTile extends StatelessWidget {
  const VideoListTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  final VideoItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final zh = item.zhSubPath != null ? '中✓' : '中✗';
    final en = item.enSubPath != null ? '英✓' : '英✗';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.movie_outlined, size: 36),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('$zh  $en'),
        trailing: const Icon(Icons.play_circle_outline),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
