import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'services/collection_service.dart';
import 'services/lan_upload_service.dart';
import 'services/library_service.dart';
import 'services/settings_service.dart';
import 'widgets/thumbnail_capture_host.dart';

class DoudouPlayerApp extends StatefulWidget {
  const DoudouPlayerApp({super.key});

  @override
  State<DoudouPlayerApp> createState() => _DoudouPlayerAppState();
}

class _DoudouPlayerAppState extends State<DoudouPlayerApp> {
  final _settingsService = SettingsService();
  final _collectionService = CollectionService();
  late final LibraryService _libraryService = LibraryService(
    _settingsService,
    collectionService: _collectionService,
  );
  late final LanUploadService _lanUploadService = LanUploadService(
    libraryService: _libraryService,
    settingsService: _settingsService,
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _settingsService.load();
    await _collectionService.load();
    await _libraryService.load();
    await _lanUploadService.initialize();
  }

  @override
  void dispose() {
    _lanUploadService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThumbnailCaptureHost(
      child: MaterialApp(
        title: '豆豆播放器',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: MainShell(
          libraryService: _libraryService,
          collectionService: _collectionService,
          settingsService: _settingsService,
          lanUploadService: _lanUploadService,
        ),
      ),
    );
  }
}
