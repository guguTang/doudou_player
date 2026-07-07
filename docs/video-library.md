# 视频库

## 设计

- **引用式索引**：视频文件保留在用户原路径，应用只记录路径与元数据
- **持久化**：`SharedPreferences`，key=`video_library`
- **排序**：按 `addedAt` 倒序（最新在前）

## VideoItem 字段

| 字段 | 说明 |
|------|------|
| `id` / `filePath` | 规范化后的绝对路径 |
| `title` | 文件名（无扩展名） |
| `zhSubPath` / `enSubPath` | 关联字幕路径 |
| `fileBookmark` / `directoryBookmark` | macOS security-scoped bookmark |
| `zhSubBookmark` / `enSubBookmark` | 字幕 bookmark |
| `thumbnailPath` | 缓存缩略图路径 |
| `addedAt` | 添加时间 |

模型：`lib/models/video_item.dart`

## 用户操作 → API

| 操作 | 方法 |
|------|------|
| 选择视频文件 | `pickAndAddVideos()` |
| 选择文件夹递归扫描 | `pickAndScanDirectory()` |
| 程序化添加 | `addVideoPaths(paths)` |
| 手动选中/英文字幕 | `updateSubtitles()` / `pickSubtitleFile()` |
| 从列表移除 | `removeVideo()` / `removeVideos()` |
| 播放前授权 | `ensureAccess(item)` |
| 播放后释放 | `releaseAccess()` |
| LAN 字幕关联 | `attachUploadedSubtitles()` |

服务：`lib/services/library_service.dart`

## 支持的视频扩展名

`.mp4` `.mkv` `.avi` `.mov` `.wmv` `.flv` `.webm` `.m4v`

定义于 `SubtitleMatcher.isVideoFile()`。

## 添加流程

1. 用户选择文件或扫描目录
2. macOS：`MacosSecurePicker` + 即时创建 bookmark
3. 其他平台：`file_picker`
4. `normalizeLibraryPath()` 去重（含 `/private` 前缀处理）
5. `SubtitleMatcher.findSubtitles()` 同目录自动匹配字幕
6. `ThumbnailService` 生成缩略图
7. 写入 `_items` 并 `_save()`

路径工具：`lib/services/library_path.dart`

## 文件夹扫描

- 递归遍历，`followLinks: false`
- 两阶段进度（`LibraryScanProgress`）：
  - `scanningDirectory` — 已检查条目数、已发现视频数
  - `importingVideos` — 当前/总数 + 文件名
- UI：`lib/widgets/library_scan_progress_overlay.dart`

## 缩略图

| 项 | 说明 |
|----|------|
| 缓存路径 | `{ApplicationSupport}/thumbnails/{pathHash}.jpg` |
| 截图策略 | 长视频随机 4–10 秒；短视频取中间；失败回退 0 秒 |
| 生成时机 | 添加视频时；`load()` 后补全缺失 |
| 删除时机 | 从库移除时 |
| 实现 | `ThumbnailService` + 根部隐藏 `ThumbnailCaptureHost`（mpv screenshot） |

## 移除行为

从列表移除**不会删除**磁盘上的视频或字幕文件，仅删除缩略图缓存和索引记录。

## 外部文件变更

应用**不监听**文件系统。用户在外部移动/删除文件后，播放可能失败，需从列表移除后重新添加。

## 相关文件

- `lib/services/library_service.dart`
- `lib/services/library_path.dart`
- `lib/models/video_item.dart`
- `lib/models/library_scan_progress.dart`
- `lib/screens/local_videos_screen.dart`
- `lib/screens/home_tab_screen.dart`
- `lib/widgets/video_list_tile.dart`
- `lib/services/thumbnail_service.dart`
- `lib/widgets/thumbnail_capture_host.dart`

macOS 沙盒详见 [macos-sandbox.md](macos-sandbox.md)。
