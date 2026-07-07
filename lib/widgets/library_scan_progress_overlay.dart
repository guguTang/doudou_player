import 'package:flutter/material.dart';

import '../services/library_service.dart';

class LibraryScanProgressOverlay extends StatelessWidget {
  const LibraryScanProgressOverlay({
    super.key,
    required this.libraryService,
    required this.child,
  });

  final LibraryService libraryService;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: libraryService,
      builder: (context, _) {
        final progress = libraryService.scanProgress;
        return Stack(
          children: [
            child,
            if (progress != null) ...[
              const ModalBarrier(dismissible: false, color: Colors.black54),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            progress.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress.fraction,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            progress.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
