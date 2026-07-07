# macOS 沙盒与安全文件访问

macOS 版运行在 App Sandbox 下，只能访问用户通过系统文件选择器授权的路径。

## Entitlements

`macos/Runner/Release.entitlements`：

- `com.apple.security.app-sandbox`
- `com.apple.security.files.user-selected.read-only`
- `com.apple.security.files.bookmarks.app-scope`
- `com.apple.security.network.server`（局域网上传）

## 组件

| 文件 | 职责 |
|------|------|
| `lib/services/secure_file_access.dart` | bookmark 创建、解析、访问、释放 |
| `lib/services/macos_secure_picker.dart` | Flutter MethodChannel 调用原生选择器 |
| `macos/Runner/SecureFilePickerPlugin.swift` | `NSOpenPanel` 选视频/目录/字幕 |

`SecureFileAccess.enabled` 仅在 `Platform.isMacOS` 时为 true。

## 工作流程

1. **选择文件/目录**：`MacosSecurePicker` → 原生面板 → 立即创建 bookmark
2. **存入 VideoItem**：`fileBookmark`（单文件）或 `directoryBookmark`（目录扫描）
3. **访问前**：`startAccessForPaths()` 恢复 security-scoped 资源
4. **访问后**：`stopAll()` 释放

触发 `ensureAccess()` 的场景：播放视频、生成缩略图。

## 与其他平台的差异

| | macOS | 其他平台 |
|---|-------|----------|
| 文件选择 | 原生 NSOpenPanel + bookmark | `file_picker` |
| 持久访问 | 需要 bookmark | 直接路径 |
| 播放失败 | 无 bookmark 提示重新添加 | 文件不存在则失败 |

## 局域网上传目录

`{ApplicationSupport}/lan_uploads/` 位于应用沙盒容器内，**不需要**用户选择与 bookmark，可直接读写。

与用户原路径的「引用式」视频库是两套存储策略，详见 [video-library.md](video-library.md)、[lan-upload.md](lan-upload.md)。

## 相关文件

- `lib/services/secure_file_access.dart`
- `lib/services/macos_secure_picker.dart`
- `lib/services/library_service.dart`（`ensureAccess` / `_withBookmarks`）
- `macos/Runner/SecureFilePickerPlugin.swift`
