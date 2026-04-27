# 新闻速递 APK 项目

这是一个基于 Flutter 的新闻聚合应用，支持按分类一键获取最新资讯，并通过 GitHub Actions 自动构建 APK。

## 功能

- 一键刷新新闻
- 分类查看：国内、国际、军事、科技、财经
- 点击新闻跳转原文
- 下拉刷新
- 自动按发布时间排序

## 本地运行（可选）

```bash
flutter pub get
flutter run
```

## GitHub 自动构建 APK

1. 新建 GitHub 仓库（比如 `news-app`）
2. 上传本目录全部文件
3. 推送到 `main` 分支
4. 打开仓库的 **Actions** 页面，等待 `构建 Android APK` 完成
5. 在：
   - Actions 的 Artifacts 下载 `app-release.apk`，或
   - Releases 页面下载正式 APK

## 常见问题

### 1) Actions 失败：Flutter 版本问题
在 `.github/workflows/build.yml` 改 `flutter-version`。

### 2) 某些 RSS 源失效
在 `lib/services/rss_service.dart` 替换对应 URL。

### 3) 安装时报风险
Android 会提示未知来源安装，属于正常现象，允许后即可安装。
