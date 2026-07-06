import 'package:flutter/material.dart';

import '../models/video_item.dart';

class VideoListTile extends StatelessWidget {
  const VideoListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.selecting = false,
    this.selected = false,
  });

  final VideoItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selecting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final zh = item.zhSubPath != null ? '中✓' : '中✗';
    final en = item.enSubPath != null ? '英✓' : '英✗';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: ListTile(
        leading: selecting
            ? Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
              )
            : const Icon(Icons.movie_outlined, size: 36),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('$zh  $en'),
        trailing: selecting
            ? null
            : const Icon(Icons.play_circle_outline),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
