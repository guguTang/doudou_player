# 豆豆播放器文档索引

本目录包含应用功能、架构与模块说明。**功能变更时，必须同步更新对应文档**（见下方映射表）。

## 文档列表

| 文档 | 内容 |
|------|------|
| [features.md](features.md) | **总览**：全部用户功能、屏幕、服务关系 |
| [architecture.md](architecture.md) | 启动流程、服务依赖、目录结构、测试 |
| [video-library.md](video-library.md) | 视频库、合集/文件夹、扫描、缩略图、路径规范化 |
| [subtitles.md](subtitles.md) | 字幕模式、匹配、解析、叠加显示 |
| [player.md](player.md) | 播放器 UI、全屏、控制层、chrome |
| [settings.md](settings.md) | 全部用户偏好与持久化 key |
| [macos-sandbox.md](macos-sandbox.md) | macOS 沙盒、bookmark、安全文件选择 |
| [lan-upload.md](lan-upload.md) | 局域网上传（HTTP 服务、API、安全） |

项目入口：[README.md](../README.md)

## 功能 → 文档映射（变更时必查）

| 功能区域 | 主要代码路径 | 需更新的文档 |
|----------|-------------|-------------|
| 导航 / 首页 / 本地视频列表 | `lib/screens/main_shell.dart`, `home_tab_screen.dart`, `local_videos_screen.dart`, `collection_detail_screen.dart` | `features.md` |
| 视频库增删扫 | `lib/services/library_service.dart`, `lib/models/video_item.dart` | `features.md`, `video-library.md` |
| 合集 / 文件夹 | `lib/services/collection_service.dart`, `lib/models/video_collection.dart`, `collection_list_tile.dart` | `features.md`, `video-library.md` |
| 路径去重 | `lib/services/library_path.dart` | `video-library.md` |
| 扫描进度 UI | `lib/widgets/library_scan_progress_overlay.dart` | `features.md`, `video-library.md` |
| 缩略图 | `lib/services/thumbnail_*.dart`, `lib/widgets/thumbnail_capture_host.dart` | `video-library.md` |
| 字幕模式 / 叠加 / 解析 | `lib/models/subtitle_mode.dart`, `lib/widgets/dual_subtitle_overlay.dart`, `lib/services/subtitle_parser_service.dart` | `features.md`, `subtitles.md`, `player.md` |
| 字幕匹配 / 扫描规则 | `lib/services/subtitle_matcher.dart`, `lib/models/subtitle_scan_rules.dart`, `subtitle_scan_rules_section.dart` | `subtitles.md`, `settings.md` |
| 播放器 | `lib/screens/player_screen.dart`, `player_controls.dart`, `player_seek_bar.dart` | `features.md`, `player.md` |
| 全屏 / 沉浸式 | `lib/services/player_chrome.dart` | `player.md` |
| 设置页 | `lib/screens/settings_screen.dart` | `features.md`, `settings.md` |
| 设置持久化 | `lib/services/settings_service.dart` | `settings.md` |
| 局域网上传 | `lib/services/lan_upload_*.dart`, `lan_upload_section.dart` | `features.md`, `lan-upload.md` |
| macOS 沙盒 | `secure_file_access.dart`, `macos_secure_picker.dart`, `macos/Runner/*` | `macos-sandbox.md`, `video-library.md` |
| 应用入口 / 服务注入 | `lib/main.dart`, `lib/app.dart` | `architecture.md` |
| 平台权限 | `android/`, `ios/`, `macos/` 配置 | 对应模块文档 + `architecture.md` |
| 测试 | `test/*.dart` | `architecture.md`（测试表） |
| 构建/打包脚本 | `scripts/*.sh` | `architecture.md` |

## 文档维护约定

1. **新增用户可见功能** → 更新 `features.md`；若属已有模块则同时更新专题文档
2. **新增/修改服务 API** → 更新对应专题文档的 API 表
3. **新增设置项** → 更新 `settings.md` 的 key/默认值表
4. **平台权限变更** → 更新 `architecture.md` 或模块文档中的平台表
5. **README.md** → 仅保留一句话简介 + 链到 `docs/`，不重复细节
6. 专题文档（如 `lan-upload.md`）可写实现细节；`features.md` 保持用户视角简洁

## Cursor 规则

- `.cursor/rules/documentation.mdc` — 文档同步总则（全局）
- `.cursor/rules/lan-upload.mdc` — 局域网上传模块约定
