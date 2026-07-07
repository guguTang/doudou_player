# 设置与偏好

服务：`lib/services/settings_service.dart`（`ChangeNotifier` + `SharedPreferences`）

UI：`lib/screens/settings_screen.dart`

## 设置分区

### 字幕

| 设置项 | Key | 默认值 | UI 范围 |
|--------|-----|--------|---------|
| 默认字幕模式 | `default_subtitle_mode` | `both` | 关闭 / 仅中文 / 仅英文 / 中英双语 |
| 字幕距底部 | `subtitle_bottom_padding` | 24 px | 8–80 |
| 字幕字号 | `subtitle_font_size` | 16 | 12–28 |
| 双语间距 | `subtitle_line_spacing` | 8 px | 0–32（仅双语模式） |

### 扫描文件夹

中/英文字幕后缀列表，影响**后续**添加/扫描时的自动匹配，不会重扫已有条目。

详见 [subtitles.md](subtitles.md)。

### 局域网传输

| 字段 | 默认 | 说明 |
|------|------|------|
| `enabled` | `false` | 服务是否运行 |
| `port` | `8765` | 1024–65535 |
| `autoStart` | `false` | 应用启动时自动开启 |
| `token` | 随机 6 位 PIN | 浏览器上传鉴权 |

详见 [lan-upload.md](lan-upload.md)。

### 其他

「恢复全部默认设置」→ `SettingsService.resetAll()`，重置所有偏好（含扫描规则、局域网配置）。

## API

| 方法 | 说明 |
|------|------|
| `load()` | 启动时加载 |
| `setDefaultSubtitleMode()` | 更新字幕模式 |
| `setSubtitleBottomPadding()` | 更新距底部 |
| `setSubtitleFontSize()` | 更新字号 |
| `setSubtitleLineSpacing()` | 更新双语间距 |
| `setSubtitleScanRules()` | 更新扫描后缀 |
| `resetSubtitleScanRules()` | 恢复默认后缀 |
| `setLanUploadSettings()` | 更新局域网配置 |
| `regenerateLanUploadToken()` | 重新生成 PIN |
| `resetAll()` | 恢复全部默认 |

## 模型

- `SubtitleMode` — `lib/models/subtitle_mode.dart`
- `SubtitleScanRules` — `lib/models/subtitle_scan_rules.dart`
- `LanUploadSettings` — `lib/models/lan_upload_settings.dart`

## 相关 Widget

- `SubtitleScanRulesSection` — `lib/widgets/subtitle_scan_rules_section.dart`
- `LanUploadSection` — `lib/widgets/lan_upload_section.dart`
