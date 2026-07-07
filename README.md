# 豆豆播放器（doudou_player）

跨平台本地视频播放器，支持 SRT 中英双字幕。支持 Android、iOS、macOS、Linux、Windows。

## 功能

- **本地视频库** — 添加视频、文件夹扫描、缩略图列表
- **中英双字幕** — 四种显示模式、样式可调、可配置自动匹配后缀
- **播放器** — 进度控制、全屏、屏幕锁定
- **局域网上传** — 同 Wi-Fi 设备通过浏览器上传视频/字幕
- **macOS 沙盒** — security-scoped bookmark 安全访问用户文件

## 文档

完整功能说明与开发文档见 **[docs/](docs/README.md)**：

| 文档 | 内容 |
|------|------|
| [features.md](docs/features.md) | 全部用户功能总览 |
| [architecture.md](docs/architecture.md) | 架构、依赖、测试 |
| [video-library.md](docs/video-library.md) | 视频库与缩略图 |
| [subtitles.md](docs/subtitles.md) | 字幕系统 |
| [player.md](docs/player.md) | 播放器 |
| [settings.md](docs/settings.md) | 设置与偏好 |
| [macos-sandbox.md](docs/macos-sandbox.md) | macOS 沙盒 |
| [lan-upload.md](docs/lan-upload.md) | 局域网上传 |

## 开发

```bash
flutter pub get
flutter run        # 选择目标平台
flutter test       # 运行测试
./scripts/build_multi.sh -p android-apk,ios --no-codesign  # 多平台打包
./scripts/build_multi.sh -p android-apk,ios -o dist         # 产物集中输出到 dist/
```

Flutter 入门：[docs.flutter.dev](https://docs.flutter.dev/)
