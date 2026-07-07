# 字幕系统

## 字幕模式

| 模式 | 播放器显示 | 设置页显示 |
|------|-----------|-----------|
| `off` | 关 | 关闭 |
| `chinese` | 中 | 仅中文 |
| `english` | 英 | 仅英文 |
| `both` | 双语 | 中英双语 |

循环顺序：`off → chinese → english → both → off`

模型：`lib/models/subtitle_mode.dart`

播放器内切换会同步写入 `SettingsService.defaultSubtitleMode`。

## 自动匹配（SubtitleMatcher）

扫描或添加视频时，在**同目录**按可配置后缀查找字幕：

**默认中文后缀**：`.zh.srt` `.zh-cn.srt` `.zh-hans.srt` `.chinese.srt`  
**默认英文后缀**：`.en.srt` `.eng.srt` `.english.srt`

规则模型：`lib/models/subtitle_scan_rules.dart`  
设置 UI：`lib/widgets/subtitle_scan_rules_section.dart`  
匹配逻辑：`lib/services/subtitle_matcher.dart`

### 通用 `.srt` 处理

若存在 `movie.srt` 且无其他语言后缀：

- 两侧字幕都空 → **不自动分配**（留给用户手动选择）
- 仅一侧有语言字幕 → 将 `.srt` 填到另一侧

### LAN 上传字幕解析

`parseSubtitleFileName()` 从文件名推断 `videoBaseName` 与语言，用于 `attachUploadedSubtitles()` 跨目录关联库内同名视频。

## 字幕解析

`SubtitleParserService`（`lib/services/subtitle_parser_service.dart`）：

- 基于 `subtitle` 包解析 SRT
- 编码：UTF-8，失败回退 Latin1
- `cueAt(Duration)` 返回当前时间点的字幕文本

## 叠加显示

`DualSubtitleOverlay`（`lib/widgets/dual_subtitle_overlay.dart`）：

- 监听 `player.stream.position`，实时取字幕
- 双语模式：**英文在上、中文在下**
- 样式来自 `SettingsService`：距底部、字号、行间距
- 半透明黑底 + 文字阴影
- 播放器禁用 media_kit 内置字幕轨，完全自定义渲染

## 手动选择字幕

入口：本地视频列表长按 →「选择中文字幕」/「选择英文字幕」

- macOS：安全选择器 + bookmark
- 其他：`file_picker` 选 `.srt`
- 调用 `LibraryService.updateSubtitles()`

## 相关文件

- `lib/models/subtitle_mode.dart`
- `lib/models/subtitle_scan_rules.dart`
- `lib/services/subtitle_matcher.dart`
- `lib/services/subtitle_parser_service.dart`
- `lib/widgets/dual_subtitle_overlay.dart`
- `lib/widgets/subtitle_scan_rules_section.dart`

设置项详见 [settings.md](settings.md)。
