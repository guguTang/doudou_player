# 视频库

## 设计

- **引用式索引**：视频文件保留在用户原路径，应用只记录路径与元数据
- **持久化**：`SharedPreferences`，key=`video_library`（视频）、`video_collections`（合集）
- **排序**：视频按 `addedAt` 倒序（最新在前）；合集按创建时间
- **组织方式**：扁平视频索引 + 可选合集/文件夹分组（M:N 关系）

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

## VideoCollection 字段

| 字段 | 说明 |
|------|------|
| `id` | manual：时间戳 ID；scanRoot：规范化扫描根路径 |
| `name` | 显示名称（manual 用户命名；scanRoot 为目录 basename） |
| `type` | `manual`（自定义合集）或 `scanRoot`（扫描源文件夹） |
| `videoIds` | 关联的 `VideoItem.id` 列表 |
| `createdAt` | 创建时间 |
| `scanRootPath` | 仅 scanRoot，规范化绝对路径 |
| `directoryBookmark` | 仅 scanRoot，macOS 沙盒 bookmark |

模型：`lib/models/video_collection.dart`

## 用户操作 → API

### 视频库（LibraryService）

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

### 合集（CollectionService）

| 操作 | 方法 |
|------|------|
| 创建自定义合集 | `createManualCollection(name)` |
| 重命名合集 | `renameCollection(id, name)`（仅 manual） |
| 删除合集 | `deleteCollection(id)` |
| 添加视频到合集 | `addVideosToCollection(id, videoIds)` |
| 从合集移除视频 | `removeVideosFromCollection(id, videoIds)` |
| 扫描后注册文件夹 | `registerScanRootCollection(rootPath, bookmark, videoIds)` |
| 库移除后清理引用 | `pruneVideoIds(validIds)` |
| 获取合集内视频 | `videosInCollection(id, libraryService)` |

服务：`lib/services/collection_service.dart`

扫描文件夹完成后，`LibraryService` 自动调用 `registerScanRootCollection`，将该次扫描发现且已在库中的视频关联到对应文件夹合集。

## 合集与文件夹行为

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
- 扫描完成后自动创建/更新 **scanRoot** 类型文件夹合集
- 重复扫描同一目录：合并 videoIds 到已有文件夹合集

## 合集边界行为

| 场景 | 行为 |
|------|------|
| 重复扫描同一目录 | 合并到已有 scanRoot 合集 |
| 从库移除视频 | 自动从所有合集中 prune |
| 从合集移除视频 | 仅删关联，视频仍在「全部」 |
| 删除合集 | 仅删分组元数据，视频仍在库中 |
| 单独添加视频 / LAN 上传 | 仅出现在「全部」，需手动加入自定义合集 |
| 升级前已有视频 | 不做回溯分组，仅新扫描产生文件夹合集 |

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
- `lib/services/collection_service.dart`
- `lib/services/library_path.dart`
- `lib/models/video_item.dart`
- `lib/models/video_collection.dart`
- `lib/models/library_scan_progress.dart`
- `lib/screens/local_videos_screen.dart`
- `lib/screens/collection_detail_screen.dart`
- `lib/screens/home_tab_screen.dart`
- `lib/widgets/video_list_tile.dart`
- `lib/widgets/collection_list_tile.dart`
- `lib/services/thumbnail_service.dart`
- `lib/widgets/thumbnail_capture_host.dart`

macOS 沙盒详见 [macos-sandbox.md](macos-sandbox.md)。
