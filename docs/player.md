# 播放器

## 技术栈

- `media_kit` `Player` + `VideoController`
- 禁用内置字幕轨，使用 `DualSubtitleOverlay` 渲染 SRT

屏幕：`lib/screens/player_screen.dart`

## 用户功能

| 功能 | 说明 |
|------|------|
| 播放/暂停 | 控制栏按钮 |
| 进度拖拽 | `PlayerSeekBar` |
| 时间显示 | 当前 / 总时长 |
| 字幕模式 | 点击循环：关 → 中 → 英 → 双语 |
| 选手幕 | 为当前视频指定中/英 SRT 文件 |
| 全屏 | 见下方平台差异 |
| 屏幕锁定 | 锁定后仅显示解锁按钮 |
| 控制层隐藏 | 全屏下 4 秒无操作自动隐藏（移动端） |
| 返回 | 全屏先退全屏；锁定时提示先解锁 |

## 组件

| 文件 | 职责 |
|------|------|
| `player_screen.dart` | 播放逻辑、状态、导航 |
| `player_controls.dart` | 底部控制栏 |
| `player_seek_bar.dart` | 可拖拽进度条 |
| `dual_subtitle_overlay.dart` | 字幕叠加 |
| `player_chrome.dart` | 全屏与系统 UI |

## 全屏与 Chrome（PlayerChrome）

| 平台 | 行为 |
|------|------|
| Android / iOS | 强制横屏 + `SystemUiMode.immersiveSticky` |
| macOS / Windows / Linux | 仅 `immersiveSticky`（不锁方向） |

`PlayerChrome.locksOrientation` 用于判断是否移动端全屏策略。

## 沙盒访问

播放前：`libraryService.ensureAccess(item)`  
退出播放器：`libraryService.releaseAccess()`

macOS 无 bookmark 的条目会播放失败并提示重新添加。详见 [macos-sandbox.md](macos-sandbox.md)。

## 相关文档

- 字幕渲染：[subtitles.md](subtitles.md)
- 视频库访问：[video-library.md](video-library.md)
