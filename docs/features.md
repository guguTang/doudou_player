# 应用功能总览

豆豆播放器是一款跨平台本地视频播放器，支持 SRT 中英双字幕。支持 **Android、iOS、macOS、Linux、Windows**。

## 用户功能一览

### 首页

- 应用简介与功能说明
- 显示本地视频数量，一键跳转视频列表
- 快捷「添加视频」「扫描文件夹」

→ 详见 [video-library.md](video-library.md)

### 本地视频

- 列表展示：缩略图、标题、中/英文字幕是否已关联（✓/✗）
- 点击播放；FAB 添加视频或扫描文件夹
- 长按：多选、选择中/英文字幕、从列表移除
- 多选批量移除（**不删除磁盘上的原文件**）

→ 详见 [video-library.md](video-library.md)

### 播放器

- 基于 media_kit（mpv）播放本地视频
- 自定义 SRT 字幕叠加（中、英、双语、关闭四种模式循环）
- 播放/暂停、进度拖拽、时间显示
- 手动为当前视频选择中/英字幕文件
- 全屏（移动端横屏 + 沉浸式）、屏幕锁定、控制层自动隐藏
- 字幕样式跟随设置（距底部、字号、双语间距）

→ 详见 [player.md](player.md)、[subtitles.md](subtitles.md)

### 设置

| 分区 | 功能 |
|------|------|
| 字幕 | 默认字幕模式、距底部距离、字号、双语间距 |
| 扫描文件夹 | 自定义中/英文字幕后缀规则（如 `.zh.srt`） |
| 局域网传输 | 开关 HTTP 服务、端口、PIN、浏览器上传 |
| 其他 | 恢复全部默认设置 |

→ 详见 [settings.md](settings.md)、[subtitles.md](subtitles.md)、[lan-upload.md](lan-upload.md)

### 局域网上传

同 Wi-Fi 设备通过浏览器访问 `http://<本机IP>:<端口>`，输入 PIN 上传视频/字幕，自动导入视频库。

→ 详见 [lan-upload.md](lan-upload.md)

## 屏幕导航

```
MainShell（底部三 Tab）
├── [0] HomeTabScreen      首页
├── [1] LocalVideosScreen  本地视频 → PlayerScreen（push）
└── [2] SettingsScreen     设置
```

全局遮罩：`LibraryScanProgressOverlay`（文件夹扫描/导入进度）

## 核心服务

| 服务 | 职责 | 文档 |
|------|------|------|
| `LibraryService` | 视频库 CRUD、扫描、缩略图、沙盒访问 | [video-library.md](video-library.md) |
| `SettingsService` | 用户偏好持久化 | [settings.md](settings.md) |
| `LanUploadService` | 局域网 HTTP 上传 | [lan-upload.md](lan-upload.md) |
| `SubtitleMatcher` | 字幕文件名匹配 | [subtitles.md](subtitles.md) |
| `SubtitleParserService` | SRT 解析 | [subtitles.md](subtitles.md) |
| `ThumbnailService` | 列表缩略图生成 | [video-library.md](video-library.md) |
| `SecureFileAccess` | macOS bookmark（仅 macOS） | [macos-sandbox.md](macos-sandbox.md) |
| `PlayerChrome` | 全屏与系统 UI | [player.md](player.md) |

## 平台差异摘要

| 平台 | 特别说明 |
|------|----------|
| macOS | App Sandbox；文件访问靠用户授权 + bookmark |
| iOS | 全屏横屏；局域网需本地网络权限；后台可能暂停 LAN 服务 |
| Android | 全屏横屏；需 INTERNET 权限（LAN 上传） |
| Windows / Linux | 标准桌面；防火墙可能拦截 LAN 端口 |

→ 详见 [architecture.md](architecture.md)、[macos-sandbox.md](macos-sandbox.md)

## 支持格式

- **视频**：`.mp4` `.mkv` `.avi` `.mov` `.wmv` `.flv` `.webm` `.m4v`
- **字幕**：`.srt`（按可配置后缀区分中/英）

## 不在范围内

- 在线流媒体 / 网络播放
- 非 SRT 字幕格式（ASS、VTT 等）
- 视频转码
- 云同步
