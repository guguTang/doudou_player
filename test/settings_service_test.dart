import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doudou_player/models/lan_upload_settings.dart';
import 'package:doudou_player/models/subtitle_mode.dart';
import 'package:doudou_player/models/subtitle_scan_rules.dart';
import 'package:doudou_player/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SubtitleMode defaults to both when name is missing', () {
    expect(SubtitleMode.fromName(null), SubtitleMode.both);
    expect(SubtitleMode.fromName('unknown'), SubtitleMode.both);
    expect(SubtitleMode.fromName('english'), SubtitleMode.english);
  });

  test('SettingsService persists subtitle preferences', () async {
    final settings = SettingsService();
    await settings.load();

    expect(settings.defaultSubtitleMode, SubtitleMode.both);
    expect(settings.subtitleBottomPadding, 24);
    expect(settings.subtitleFontSize, 16);
    expect(settings.subtitleLineSpacing, 8);

    await settings.setDefaultSubtitleMode(SubtitleMode.chinese);
    await settings.setSubtitleBottomPadding(32);
    await settings.setSubtitleFontSize(20);
    await settings.setSubtitleLineSpacing(16);

    final restored = SettingsService();
    await restored.load();

    expect(restored.defaultSubtitleMode, SubtitleMode.chinese);
    expect(restored.subtitleBottomPadding, 32);
    expect(restored.subtitleFontSize, 20);
    expect(restored.subtitleLineSpacing, 16);
  });

  test('SettingsService persists subtitle scan rules', () async {
    final settings = SettingsService();
    await settings.load();

    const customRules = SubtitleScanRules(
      zhSuffixes: ['.zh.srt', '.cn.srt'],
      enSuffixes: ['.en.srt', '.eng.srt'],
    );
    await settings.setSubtitleScanRules(customRules);

    final restored = SettingsService();
    await restored.load();

    expect(restored.subtitleScanRules.zhSuffixes, customRules.zhSuffixes);
    expect(restored.subtitleScanRules.enSuffixes, customRules.enSuffixes);

    await settings.resetSubtitleScanRules();
    expect(
      settings.subtitleScanRules.zhSuffixes,
      SubtitleScanRules.defaults.zhSuffixes,
    );
  });

  test('SettingsService persists lan upload settings', () async {
    final settings = SettingsService();
    await settings.load();

    const custom = LanUploadSettings(
      enabled: true,
      port: 9123,
      autoStart: true,
      token: '112233',
    );
    await settings.setLanUploadSettings(custom);

    final restored = SettingsService();
    await restored.load();

    expect(restored.lanUploadSettings.enabled, isTrue);
    expect(restored.lanUploadSettings.port, 9123);
    expect(restored.lanUploadSettings.autoStart, isTrue);
    expect(restored.lanUploadSettings.token, '112233');
  });

  test('SettingsService resetAll restores every preference', () async {
    final settings = SettingsService();
    await settings.load();
    await settings.setDefaultSubtitleMode(SubtitleMode.off);
    await settings.setSubtitleBottomPadding(48);
    await settings.setSubtitleFontSize(22);
    await settings.setSubtitleLineSpacing(20);
    await settings.setSubtitleScanRules(
      const SubtitleScanRules(
        zhSuffixes: ['.cn.srt'],
        enSuffixes: ['.eng.srt'],
      ),
    );
    await settings.setLanUploadSettings(
      const LanUploadSettings(
        enabled: true,
        port: 9999,
        autoStart: true,
        token: '445566',
      ),
    );

    await settings.resetAll();

    expect(settings.defaultSubtitleMode, SubtitleMode.both);
    expect(settings.subtitleBottomPadding, 24);
    expect(settings.subtitleFontSize, 16);
    expect(settings.subtitleLineSpacing, 8);
    expect(settings.subtitleScanRules.zhSuffixes,
        SubtitleScanRules.defaults.zhSuffixes);
    expect(settings.subtitleScanRules.enSuffixes,
        SubtitleScanRules.defaults.enSuffixes);
    expect(settings.lanUploadSettings.enabled, isFalse);
    expect(settings.lanUploadSettings.port, LanUploadSettings.defaultPort);
    expect(settings.lanUploadSettings.autoStart, isFalse);

    final restored = SettingsService();
    await restored.load();
    expect(restored.defaultSubtitleMode, SubtitleMode.both);
    expect(restored.subtitleBottomPadding, 24);
    expect(restored.subtitleFontSize, 16);
    expect(restored.subtitleLineSpacing, 8);
    expect(restored.subtitleScanRules.zhSuffixes,
        SubtitleScanRules.defaults.zhSuffixes);
    expect(restored.subtitleScanRules.enSuffixes,
        SubtitleScanRules.defaults.enSuffixes);
  });
}
