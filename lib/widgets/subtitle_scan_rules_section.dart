import 'package:flutter/material.dart';

import '../models/subtitle_scan_rules.dart';
import '../services/settings_service.dart';

class SubtitleSuffixEditor extends StatefulWidget {
  const SubtitleSuffixEditor({
    super.key,
    required this.title,
    required this.hint,
    required this.suffixes,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final List<String> suffixes;
  final ValueChanged<List<String>> onChanged;

  @override
  State<SubtitleSuffixEditor> createState() => _SubtitleSuffixEditorState();
}

class _SubtitleSuffixEditorState extends State<SubtitleSuffixEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSuffix() {
    final normalized = SubtitleScanRules.normalizeSuffix(_controller.text);
    if (!SubtitleScanRules.isValidSuffix(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效后缀，例如 .zh.srt')),
      );
      return;
    }
    if (widget.suffixes.contains(normalized)) {
      _controller.clear();
      return;
    }

    widget.onChanged([...widget.suffixes, normalized]);
    _controller.clear();
  }

  void _removeSuffix(String suffix) {
    if (widget.suffixes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少保留一条后缀规则')),
      );
      return;
    }
    widget.onChanged(
      widget.suffixes.where((item) => item != suffix).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          widget.hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 12),
        if (widget.suffixes.isEmpty)
          Text(
            '暂无规则',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suffix in widget.suffixes)
                InputChip(
                  label: Text(suffix),
                  onDeleted: () => _removeSuffix(suffix),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '例如 .zh.srt',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _addSuffix(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _addSuffix,
              child: const Text('添加'),
            ),
          ],
        ),
      ],
    );
  }
}

class SubtitleScanRulesSection extends StatelessWidget {
  const SubtitleScanRulesSection({super.key, required this.settingsService});

  final SettingsService settingsService;

  Future<void> _updateRules({
    List<String>? zhSuffixes,
    List<String>? enSuffixes,
  }) async {
    final current = settingsService.subtitleScanRules;
    await settingsService.setSubtitleScanRules(
      current.copyWith(
        zhSuffixes: zhSuffixes,
        enSuffixes: enSuffixes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rules = settingsService.subtitleScanRules;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SubtitleSuffixEditor(
              title: '中文字幕后缀',
              hint: '扫描时按优先级匹配：视频名 + 后缀，例如 movie.zh.srt',
              suffixes: rules.zhSuffixes,
              onChanged: (suffixes) => _updateRules(zhSuffixes: suffixes),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SubtitleSuffixEditor(
              title: '英文字幕后缀',
              hint: '扫描时按优先级匹配：视频名 + 后缀，例如 movie.en.srt',
              suffixes: rules.enSuffixes,
              onChanged: (suffixes) => _updateRules(enSuffixes: suffixes),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: settingsService.resetSubtitleScanRules,
              child: const Text('恢复默认扫描规则'),
            ),
          ),
        ),
      ],
    );
  }
}
