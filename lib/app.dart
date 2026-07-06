import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'services/library_service.dart';

class DoudouPlayerApp extends StatefulWidget {
  const DoudouPlayerApp({super.key});

  @override
  State<DoudouPlayerApp> createState() => _DoudouPlayerAppState();
}

class _DoudouPlayerAppState extends State<DoudouPlayerApp> {
  final LibraryService _libraryService = LibraryService();

  @override
  void initState() {
    super.initState();
    _libraryService.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '豆豆播放器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MainShell(libraryService: _libraryService),
    );
  }
}
