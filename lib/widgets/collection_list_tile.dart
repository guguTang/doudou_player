import 'package:flutter/material.dart';

import '../models/video_collection.dart';

class CollectionListTile extends StatelessWidget {
  const CollectionListTile({
    super.key,
    required this.collection,
    required this.onTap,
  });

  final VideoCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = collection.type == VideoCollectionType.scanRoot
        ? Icons.folder_outlined
        : Icons.collections_bookmark_outlined;
    final count = collection.videoIds.length;
    final subtitle = collection.type == VideoCollectionType.scanRoot
        ? collection.scanRootPath
        : '$count 个视频';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(collection.name),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (collection.type == VideoCollectionType.scanRoot)
              Text(
                '$count',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
