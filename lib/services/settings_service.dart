import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lan_upload_settings.dart';
import '../models/subtitle_mode.dart';
import '../models/subtitle_scan_rules.dart';

class SettingsService extends ChangeNotifier {
  static const _subtitleModeKey = 'default_subtitle_mode';
  static const _subtitleBottomPaddingKey = 'subtitle_bottom_padding';
  static const _subtitleFontSizeKey = 'subtitle_font_size';
  static const _subtitleLineSpacingKey = 'subtitle_line_spacing';
  static const _subtitleScanRulesKey = 'subtitle_scan_rules';
  static const _lanUploadSettingsKey = 'lan_upload_settings';

  SubtitleMode _defaultSubtitleMode = SubtitleMode.both;
  double _subtitleBottomPadding = 24;
  double _subtitleFontSize = 16;
  double _subtitleLineSpacing = 8;
  SubtitleScanRules _subtitleScanRules = SubtitleScanRules.defaults;
  LanUploadSettings _lanUploadSettings = LanUploadSettings.defaults();
  bool _loaded = false;

  SubtitleMode get defaultSubtitleMode => _defaultSubtitleMode;
  double get subtitleBottomPadding => _subtitleBottomPadding;
  double get subtitleFontSize => _subtitleFontSize;
  double get subtitleLineSpacing => _subtitleLineSpacing;
  SubtitleScanRules get subtitleScanRules => _subtitleScanRules;
  LanUploadSettings get lanUploadSettings => _lanUploadSettings;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultSubtitleMode =
        SubtitleMode.fromName(prefs.getString(_subtitleModeKey));
    _subtitleBottomPadding =
        prefs.getDouble(_subtitleBottomPaddingKey) ?? 24;
    _subtitleFontSize = prefs.getDouble(_subtitleFontSizeKey) ?? 16;
    _subtitleLineSpacing = prefs.getDouble(_subtitleLineSpacingKey) ?? 8;
    final rulesRaw = prefs.getString(_subtitleScanRulesKey);
    if (rulesRaw != null) {
      _subtitleScanRules = SubtitleScanRules.fromJson(
        jsonDecode(rulesRaw) as Map<String, dynamic>,
      );
    }
    final lanUploadRaw = prefs.getString(_lanUploadSettingsKey);
    if (lanUploadRaw != null) {
      _lanUploadSettings = LanUploadSettings.fromJson(
        jsonDecode(lanUploadRaw) as Map<String, dynamic>,
      );
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDefaultSubtitleMode(SubtitleMode mode) async {
    if (_defaultSubtitleMode == mode) {
      return;
    }
    _defaultSubtitleMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleModeKey, mode.name);
  }

  Future<void> setSubtitleBottomPadding(double value) async {
    final rounded = value.roundToDouble();
    if (_subtitleBottomPadding == rounded) {
      return;
    }
    _subtitleBottomPadding = rounded;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_subtitleBottomPaddingKey, rounded);
  }

  Future<void> setSubtitleFontSize(double value) async {
    final rounded = value.roundToDouble();
    if (_subtitleFontSize == rounded) {
      return;
    }
    _subtitleFontSize = rounded;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_subtitleFontSizeKey, rounded);
  }

  Future<void> setSubtitleLineSpacing(double value) async {
    final rounded = value.roundToDouble();
    if (_subtitleLineSpacing == rounded) {
      return;
    }
    _subtitleLineSpacing = rounded;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_subtitleLineSpacingKey, rounded);
  }

  Future<void> setSubtitleScanRules(SubtitleScanRules rules) async {
    if (_subtitleScanRules.zhSuffixes == rules.zhSuffixes &&
        _subtitleScanRules.enSuffixes == rules.enSuffixes) {
      return;
    }
    _subtitleScanRules = rules;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleScanRulesKey, jsonEncode(rules.toJson()));
  }

  Future<void> resetSubtitleScanRules() async {
    await setSubtitleScanRules(SubtitleScanRules.defaults);
  }

  Future<void> setLanUploadSettings(LanUploadSettings settings) async {
    if (_lanUploadSettings.enabled == settings.enabled &&
        _lanUploadSettings.port == settings.port &&
        _lanUploadSettings.autoStart == settings.autoStart &&
        _lanUploadSettings.token == settings.token) {
      return;
    }
    _lanUploadSettings = settings;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lanUploadSettingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  Future<void> regenerateLanUploadToken() async {
    await setLanUploadSettings(
      _lanUploadSettings.copyWith(token: LanUploadSettings.generateToken()),
    );
  }

  Future<void> resetAll() async {
    _defaultSubtitleMode = SubtitleMode.both;
    _subtitleBottomPadding = 24;
    _subtitleFontSize = 16;
    _subtitleLineSpacing = 8;
    _subtitleScanRules = SubtitleScanRules.defaults;
    _lanUploadSettings = LanUploadSettings.defaults();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleModeKey, SubtitleMode.both.name);
    await prefs.setDouble(_subtitleBottomPaddingKey, 24);
    await prefs.setDouble(_subtitleFontSizeKey, 16);
    await prefs.setDouble(_subtitleLineSpacingKey, 8);
    await prefs.setString(
      _subtitleScanRulesKey,
      jsonEncode(SubtitleScanRules.defaults.toJson()),
    );
    await prefs.setString(
      _lanUploadSettingsKey,
      jsonEncode(LanUploadSettings.defaults().toJson()),
    );
  }
}
