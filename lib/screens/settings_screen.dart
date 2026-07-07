import 'package:flutter/material.dart';

import '../models/subtitle_mode.dart';
import '../services/lan_upload_service.dart';
import '../services/settings_service.dart';
import '../widgets/lan_upload_section.dart';
import '../widgets/subtitle_scan_rules_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settingsService,
    required this.lanUploadService,
  });

  final SettingsService settingsService;
  final LanUploadService lanUploadService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmResetAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('恢复默认设置'),
          content: const Text('将恢复所有设置为初始值，此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('恢复'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await widget.settingsService.resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已恢复全部默认设置')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settingsService;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: '字幕'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '默认字幕模式',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                ...SubtitleMode.values.map((mode) {
                  final selected = settings.defaultSubtitleMode == mode;
                  return ListTile(
                    title: Text(mode.settingsLabel),
                    trailing: selected
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => settings.setDefaultSubtitleMode(mode),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '字幕位置（距底部 ${settings.subtitleBottomPadding.round()} px）',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: settings.subtitleBottomPadding,
                    min: 8,
                    max: 80,
                    divisions: 18,
                    label: '${settings.subtitleBottomPadding.round()} px',
                    onChanged: settings.setSubtitleBottomPadding,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '字幕字号（${settings.subtitleFontSize.round()}）',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Slider(
                    value: settings.subtitleFontSize,
                    min: 12,
                    max: 28,
                    divisions: 16,
                    label: settings.subtitleFontSize.round().toString(),
                    onChanged: settings.setSubtitleFontSize,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '双语字幕间距（${settings.subtitleLineSpacing.round()} px）',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '仅在中英双语同时显示时生效',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  Slider(
                    value: settings.subtitleLineSpacing,
                    min: 0,
                    max: 32,
                    divisions: 16,
                    label: '${settings.subtitleLineSpacing.round()} px',
                    onChanged: settings.setSubtitleLineSpacing,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: '扫描文件夹'),
          SubtitleScanRulesSection(settingsService: settings),
          const SizedBox(height: 24),
          const _SectionHeader(title: '局域网传输'),
          LanUploadSection(lanUploadService: widget.lanUploadService),
          const SizedBox(height: 24),
          const _SectionHeader(title: '其他'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('恢复全部默认设置'),
              subtitle: const Text('字幕模式、位置、字号、间距、扫描规则、局域网传输'),
              onTap: () => _confirmResetAll(context),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
