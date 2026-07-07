# 局域网上传（LAN Upload）

> 文档索引：[README.md](README.md) | 功能总览：[features.md](features.md)

同 Wi-Fi 下的设备可通过浏览器，将视频/字幕上传到运行豆豆播放器的设备，并自动导入本地视频库。

## 用户功能

| 能力 | 说明 |
|------|------|
| 开关服务 | 设置 → **局域网传输** → 启用/关闭 |
| 自动启动 | 「应用启动时自动开启」；需保持应用在前台（iOS 后台可能暂停） |
| 端口配置 | 默认 `8765`，范围 1024–65535；运行中不可改端口 |
| PIN 鉴权 | 6 位数字 PIN；浏览器页可记住；支持重新生成 |
| 访问地址 | 设置页展示本机 IPv4 列表与 `http://<IP>:<端口>`，可一键复制 |
| 浏览器上传 | 打开上传页，输入 PIN，拖拽或选择多文件上传，显示进度与导入摘要 |
| 视频导入 | 上传的视频自动进入本地视频库，并尝试同目录匹配字幕 |
| 字幕补传 | 单独上传 `.zh.srt` / `.en.srt` 等，按文件名关联库内同名视频 |

## 架构与数据流

```
浏览器 (同 LAN)
    │ GET /              → 内嵌 HTML 上传页
    │ POST /api/upload   → multipart + PIN
    ▼
LanUploadService (shelf HttpServer, 0.0.0.0)
    │ 校验 PIN / 扩展名 / 文件名
    ▼
LanUploadStorage → {ApplicationSupport}/lan_uploads/
    │
    ├─ 视频 → LibraryService.addVideoPaths()
    └─ 字幕 → LibraryService.attachUploadedSubtitles()
```

### 服务注入（`lib/app.dart`）

```dart
SettingsService
    └── LibraryService
    └── LanUploadService(libraryService, settingsService)
            └── MainShell → SettingsScreen → LanUploadSection
```

`LanUploadService` 与 `LibraryService` 同级创建；`initialize()` 在 settings/library `load()` 之后执行，若 `enabled` 或 `autoStart` 为真则 `start()`。

## 文件与职责

| 路径 | 职责 |
|------|------|
| `lib/models/lan_upload_settings.dart` | 配置模型：`enabled`、`port`、`autoStart`、`token`；持久化 JSON |
| `lib/services/settings_service.dart` | `lanUploadSettings` 读写；key=`lan_upload_settings`；`resetAll()` 一并重置 |
| `lib/services/lan_upload_storage.dart` | 应用专属目录、文件名消毒、流式写入、同名 `_1` 后缀 |
| `lib/services/lan_upload_service.dart` | HTTP 服务生命周期、路由、上传编排 |
| `lib/services/lan_upload_page.dart` | 内嵌 HTML 上传页（`r'''...'''` 常量，无 assets） |
| `lib/services/library_service.dart` | `attachUploadedSubtitles()` 跨目录按 basename 关联字幕 |
| `lib/services/subtitle_matcher.dart` | `isAllowedUploadFile`、`parseSubtitleFileName` |
| `lib/widgets/lan_upload_section.dart` | 设置页 UI |
| `test/lan_upload_service_test.dart` | 存储、字幕关联、handler 集成测试 |

## HTTP API

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/` | HTML 上传页 |
| GET | `/api/status` | `{ running, port, addresses, tokenRequired }` |
| POST | `/api/upload` | multipart 字段名 `files` 或 `file`；PIN 通过 `X-Upload-Token` 或 `?token=` |

成功响应示例：

```json
{
  "videosAdded": 1,
  "subtitlesAttached": 0,
  "skipped": 0,
  "errors": []
}
```

错误：无效 PIN → `401`；非 multipart → `400`。

## 存储位置

- 目录：`getApplicationSupportDirectory()/lan_uploads/`
- 沙盒内可写，**无需** macOS security-scoped bookmark
- 与「用户原路径引用式」视频库不同：上传文件复制/保存在应用数据目录

## 安全边界

- PIN 必填（6 位数字）
- 绑定 `InternetAddress.anyIPv4`（局域网访问，非公网穿透）
- 文件名：拒绝 `..`、`/`、`\`；仅 `basename`；扩展名白名单（视频 + `.srt`）
- 单文件上限 4GB；流式写入，避免整文件读入内存
- 同名文件自动重命名为 `name_1.ext`

## 字幕匹配规则

1. **视频 + 同批字幕**：`addVideoPaths` 时 `SubtitleMatcher.findSubtitles` 扫描同目录
2. **单独字幕**：`parseSubtitleFileName` 按 `SettingsService.subtitleScanRules` 判定中/英
3. **库内匹配**：`basenameWithoutExtension(video)` 与字幕解析出的 `videoBaseName` 忽略大小写匹配
4. **不自动处理**：仅 `movie.srt` 无语言后缀 → 跳过并记入 `errors`

## 依赖（pubspec.yaml）

| 包 | 用途 |
|----|------|
| `shelf` | HTTP 服务 |
| `shelf_router` | 路由 |
| `shelf_multipart` | multipart 解析（`request.formData()`） |
| `mime` | Content-Type（传递依赖，已显式声明） |
| `path_provider` | Application Support 目录 |

本机 IP：`dart:io` `NetworkInterface.list()`，无额外包。

## 平台权限

| 平台 | 配置 |
|------|------|
| macOS Release | `com.apple.security.network.server`（`Release.entitlements`） |
| macOS Debug | 同上（`DebugProfile.entitlements` 已有） |
| Android | `INTERNET`（`AndroidManifest.xml`） |
| iOS | `NSLocalNetworkUsageDescription`（`Info.plist`） |
| Windows / Linux | 无额外配置；系统防火墙可能拦截 |

## 编码注意事项

### 生命周期与状态

- `LanUploadService` 监听 `SettingsService`：`enabled` 变化自动启停；端口变化会 restart
- `start()` 成功后会写回 `enabled: true`；`stop()` 写回 `enabled: false`
- 避免在 `dispose()` 后继续使用；`app.dart` 中 `dispose` 时调用 `_lanUploadService.dispose()`

### 与视频库集成

- 新视频走 `addVideoPaths`，不要重复实现扫描/缩略图逻辑
- 字幕补传走 `attachUploadedSubtitles`，不要直接改 `_items`
- 上传目录文件在 macOS 上通常不需要 bookmark；用户原路径视频仍走 `SecureFileAccess`

### shelf_multipart

- 使用 `request.formData()`（非旧版 `multipartFormData`）
- `FormData` 的 `part` 是 `Stream<List<int>>`，直接传给 `LanUploadStorage.saveUploadedFile`
- 测试 multipart body 须用 `\r\n` 行尾，否则 `MimeMultipartException`

### 测试

- **不要**用 `HttpClient` 打真实端口（Flutter test binding 会拦截返回 400）
- 用 `lanUpload.handler(Request(...))` 直接测 shelf handler
- 存储测试注入 `uploadDirectoryProvider` 与 `maxFileSizeBytes`（避免 4GB 内存测试）
- 相关测试：`test/lan_upload_service_test.dart`、`test/settings_service_test.dart`

### HTML 内嵌页

- 使用 `r'''...'''` 原始字符串，避免 Dart 对 `$`、`\` 的插值/转义问题
- JS 正则写 `/^\d{6}$/`，不要 `\\d`（在 raw string 中）

## 不在本期范围

- 二维码 / mDNS / Bonjour 服务发现
- 用户自选保存目录
- 上传收件箱自动清理
- iOS Background Modes 保活

## 后续可扩展点

- `qr_flutter` 生成扫码链接
- 设置页展示已上传文件占用空间
- 上传完成后可选「仅保存不导入」
- `network_info_plus` 改善复杂网络环境下的 IP 展示
