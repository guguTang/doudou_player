import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/lan_upload_service.dart';

class LanUploadSection extends StatefulWidget {
  const LanUploadSection({super.key, required this.lanUploadService});

  final LanUploadService lanUploadService;

  @override
  State<LanUploadSection> createState() => _LanUploadSectionState();
}

class _LanUploadSectionState extends State<LanUploadSection> {
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(
      text: widget.lanUploadService.settings.port.toString(),
    );
    widget.lanUploadService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    widget.lanUploadService.removeListener(_onServiceChanged);
    _portController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) {
      return;
    }
    final port = widget.lanUploadService.settings.port.toString();
    if (_portController.text != port) {
      _portController.text = port;
    }
    setState(() {});
  }

  Future<void> _copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }

  void _applyPort() {
    final parsed = int.tryParse(_portController.text.trim());
    if (parsed == null || parsed < 1024 || parsed > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('端口需在 1024–65535 之间')),
      );
      _portController.text = widget.lanUploadService.settings.port.toString();
      return;
    }
    widget.lanUploadService.setPort(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.lanUploadService;
    final settings = service.settings;
    final port = service.boundPort ?? settings.port;
    final addresses = service.addresses;
    final urls = addresses.map((address) => 'http://$address:$port').toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('启用局域网传输'),
              subtitle: const Text('关闭后同 Wi-Fi 设备将无法上传'),
              value: settings.enabled,
              onChanged: service.isStarting
                  ? null
                  : (value) => service.setEnabled(value),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portController,
              enabled: !service.isRunning && !service.isStarting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '端口',
                hintText: '8765',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _applyPort(),
              onEditingComplete: _applyPort,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('应用启动时自动开启'),
              subtitle: const Text('需保持应用运行；iOS 后台可能会暂停服务'),
              value: settings.autoStart,
              onChanged: (value) => service.setAutoStart(value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  service.isRunning ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: service.isRunning ? Colors.greenAccent : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  service.isStarting
                      ? '正在启动...'
                      : service.isRunning
                          ? '服务运行中'
                          : '服务未运行',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            if (service.error != null) ...[
              const SizedBox(height: 8),
              Text(
                service.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '上传 PIN',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    settings.token,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          letterSpacing: 4,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => service.regenerateToken(),
                  child: const Text('重新生成'),
                ),
              ],
            ),
            if (urls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '在浏览器中打开',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...urls.map(
                (url) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(url),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: '复制链接',
                    onPressed: () => _copyText(context, url),
                  ),
                ),
              ),
            ] else if (service.isRunning) ...[
              const SizedBox(height: 8),
              Text(
                '未检测到可用 IPv4 地址，请检查网络连接。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '仅限同一 Wi-Fi 下的设备访问。上传的文件保存在应用数据目录，并自动导入本地视频库。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
