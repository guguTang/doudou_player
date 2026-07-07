import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';

import '../models/lan_upload_settings.dart';
import 'lan_upload_page.dart';
import 'lan_upload_storage.dart';
import 'library_service.dart';
import 'settings_service.dart';
import 'subtitle_matcher.dart';

class LanUploadService extends ChangeNotifier {
  LanUploadService({
    required LibraryService libraryService,
    required SettingsService settingsService,
    LanUploadStorage? storage,
  })  : _libraryService = libraryService,
        _settingsService = settingsService,
        _storage = storage ?? LanUploadStorage() {
    _settingsService.addListener(_onSettingsChanged);
  }

  final LibraryService _libraryService;
  final SettingsService _settingsService;
  final LanUploadStorage _storage;

  HttpServer? _server;
  int? _boundPort;
  String? _error;
  List<String> _addresses = const [];
  bool _starting = false;

  @visibleForTesting
  Handler get handler => _createHandler();

  bool get isRunning => _server != null;
  bool get isStarting => _starting;
  int? get boundPort => _boundPort;
  String? get error => _error;
  List<String> get addresses => _addresses;
  LanUploadSettings get settings => _settingsService.lanUploadSettings;

  Future<void> initialize() async {
    final lanSettings = _settingsService.lanUploadSettings;
    if (lanSettings.enabled || lanSettings.autoStart) {
      await start();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final next = _settingsService.lanUploadSettings.copyWith(enabled: enabled);
    await _settingsService.setLanUploadSettings(next);
  }

  Future<void> setPort(int port) async {
    final clamped = port.clamp(1024, 65535);
    final next =
        _settingsService.lanUploadSettings.copyWith(port: clamped);
    await _settingsService.setLanUploadSettings(next);
  }

  Future<void> setAutoStart(bool autoStart) async {
    final next =
        _settingsService.lanUploadSettings.copyWith(autoStart: autoStart);
    await _settingsService.setLanUploadSettings(next);
  }

  Future<void> regenerateToken() async {
    await _settingsService.regenerateLanUploadToken();
  }

  Handler _createHandler() {
    final router = Router()
      ..get('/', _handleIndex)
      ..get('/api/status', _handleStatus)
      ..post('/api/upload', _handleUpload);
    return router.call;
  }

  Future<void> start() async {
    if (_server != null || _starting) {
      return;
    }

    _starting = true;
    _error = null;
    notifyListeners();

    try {
      final port = _settingsService.lanUploadSettings.port;
      _server = await shelf_io.serve(
        _createHandler(),
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );
      _boundPort = _server!.port;
      _addresses = await _discoverAddresses();
      await _settingsService.setLanUploadSettings(
        _settingsService.lanUploadSettings.copyWith(enabled: true),
      );
    } catch (error) {
      _error = error.toString();
      await stop();
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _boundPort = null;
    _addresses = const [];

    if (server != null) {
      await server.close(force: true);
    }

    if (_settingsService.lanUploadSettings.enabled) {
      await _settingsService.setLanUploadSettings(
        _settingsService.lanUploadSettings.copyWith(enabled: false),
      );
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    unawaited(stop());
    super.dispose();
  }

  void _onSettingsChanged() {
    final lanSettings = _settingsService.lanUploadSettings;
    if (lanSettings.enabled) {
      if (!isRunning && !_starting) {
        unawaited(start());
      } else if (isRunning &&
          _boundPort != null &&
          _boundPort != lanSettings.port) {
        unawaited(_restartForPortChange());
      }
    } else if (!lanSettings.enabled && isRunning) {
      unawaited(stop());
    } else {
      notifyListeners();
    }
  }

  Future<void> _restartForPortChange() async {
    await stop();
    await start();
  }

  Response _handleIndex(Request request) {
    return Response.ok(
      lanUploadPageHtml,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  Future<Response> _handleStatus(Request request) async {
    return Response.ok(
      jsonEncode({
        'running': isRunning,
        'port': _boundPort ?? settings.port,
        'addresses': _addresses,
        'tokenRequired': true,
      }),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Future<Response> _handleUpload(Request request) async {
    final token = settings.token;
    if (!_validateToken(request, token)) {
      return _jsonError('invalid token', statusCode: HttpStatus.unauthorized);
    }

    final contentType = request.headers['content-type'];
    if (contentType == null ||
        !contentType.toLowerCase().startsWith('multipart/form-data')) {
      return _jsonError('expected multipart form data');
    }

    final form = request.formData();
    if (form == null) {
      return _jsonError('expected multipart form data');
    }

    final savedPaths = <String>[];
    final errors = <String>[];
    var skipped = 0;

    try {
      await for (final data in form.formData) {
        if (data.name != 'files' && data.name != 'file') {
          continue;
        }

        final filename = data.filename;
        if (filename == null || filename.isEmpty) {
          skipped++;
          continue;
        }

        try {
          final savedPath =
              await _storage.saveUploadedFile(filename, data.part);
          savedPaths.add(savedPath);
        } on LanUploadStorageException catch (error) {
          skipped++;
          errors.add('${p.basename(filename)}: $error');
        }
      }
    } catch (error) {
      return _jsonError('upload failed: $error');
    }

    if (savedPaths.isEmpty) {
      return Response.ok(
        jsonEncode({
          'videosAdded': 0,
          'subtitlesAttached': 0,
          'skipped': skipped,
          'errors': errors,
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    final videoPaths = savedPaths
        .where((path) => SubtitleMatcher.isVideoFile(path))
        .toList();
    final subtitlePaths = savedPaths
        .where((path) => SubtitleMatcher.isSubtitleFile(path))
        .toList();

    final videosAdded = await _libraryService.addVideoPaths(videoPaths);

    final attachResult = await _libraryService.attachUploadedSubtitles(
      subtitlePaths,
      rules: _settingsService.subtitleScanRules,
    );

    skipped += attachResult.skipped;
    errors.addAll(attachResult.errors);

    return Response.ok(
      jsonEncode({
        'videosAdded': videosAdded,
        'subtitlesAttached': attachResult.attached,
        'skipped': skipped,
        'errors': errors,
      }),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  bool _validateToken(Request request, String expectedToken) {
    final headerToken = request.headers['x-upload-token'];
    if (headerToken == expectedToken) {
      return true;
    }
    return request.url.queryParameters['token'] == expectedToken;
  }

  Response _jsonError(String message, {int statusCode = HttpStatus.badRequest}) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Future<List<String>> _discoverAddresses() async {
    final addresses = <String>{};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) {
            addresses.add(address.address);
          }
        }
      }
    } catch (_) {}

    return addresses.toList()..sort();
  }
}
