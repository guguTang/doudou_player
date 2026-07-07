import 'dart:io';

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

  static const _thumbWidth = 128.0;
  static const _thumbHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final zh = item.zhSubPath != null ? '中✓' : '中✗';
    final en = item.enSubPath != null ? '英✓' : '英✗';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: _thumbHeight + 16,
          child: Row(
            children: [
              SizedBox(
                width: _thumbWidth,
                height: _thumbHeight + 16,
                child: _buildThumbnail(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        '$zh  $en',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selecting)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.play_circle_outline),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final thumbnailPath = item.thumbnailPath;
    if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
      return Image.file(
        File(thumbnailPath),
        width: _thumbWidth,
        height: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.black26,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 36,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
