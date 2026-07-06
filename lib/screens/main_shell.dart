import 'package:flutter/material.dart';

import '../services/library_service.dart';
import 'home_tab_screen.dart';
import 'local_videos_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.libraryService});

  final LibraryService libraryService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTabScreen(
        libraryService: widget.libraryService,
        onOpenLocalVideos: () => setState(() => _currentIndex = 1),
      ),
      LocalVideosScreen(libraryService: widget.libraryService),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: '本地视频',
          ),
        ],
      ),
    );
  }
}
