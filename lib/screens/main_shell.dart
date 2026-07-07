import 'package:flutter/material.dart';

import '../services/lan_upload_service.dart';
import '../services/library_service.dart';
import '../services/settings_service.dart';
import '../widgets/library_scan_progress_overlay.dart';
import 'home_tab_screen.dart';
import 'local_videos_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.libraryService,
    required this.settingsService,
    required this.lanUploadService,
  });

  final LibraryService libraryService;
  final SettingsService settingsService;
  final LanUploadService lanUploadService;

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
      LocalVideosScreen(
        libraryService: widget.libraryService,
        settingsService: widget.settingsService,
      ),
      SettingsScreen(
        settingsService: widget.settingsService,
        lanUploadService: widget.lanUploadService,
      ),
    ];

    return Scaffold(
      body: LibraryScanProgressOverlay(
        libraryService: widget.libraryService,
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
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
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
