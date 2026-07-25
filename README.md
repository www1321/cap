# Cap

> 汉化优化的中文版 — 去除登录限制，完整中文界面，完全免费

## 功能特点

- **完整中文界面** — 所有 UI 元素已中文化
- **去除登录限制** — 打开即用，无需注册账号
- **完全免费** — 无任何功能限制，所有功能均可使用
- **多种录制模式** — 屏幕录制、窗口录制、区域录制
- **摄像头画中画** — 支持录制时叠加摄像头画面
- **内置视频编辑器** — 剪辑、字幕、特效一站式处理
- **多种导出格式** — 支持视频、GIF、剪贴板等多种导出方式

## 快速开始

### Windows

下载最新版本的 `Cap-CN_*.exe` 安装包并运行即可。

### 从源码构建

```bash
# 1. 克隆仓库
git clone https://github.com/www1321/cap.git
cd cap

# 2. 安装依赖
pnpm install

# 3. 构建桌面应用
cd apps/desktop
pnpm build:sidecar
pnpm build:tauri
```

## 技术栈

- [Tauri v2](https://tauri.app/) — Rust 后端 + WebView 前端
- [SolidJS](https://www.solidjs.com/) — 响应式前端框架
- [Rust](https://www.rust-lang.org/) — 高性能原生代码

## 关于本项目

本项目基于 [Cap](https://github.com/CapSoftware/Cap) 原版进行汉化优化。

Cap 是一个开源的屏幕录制工具，是 Loom 的优秀替代品。原版采用 AGPLv3 许可证，本汉化版同样遵循该许可证。

## 许可证

AGPLv3 — 详见 [LICENSE](./LICENSE) 文件

---

> 原版项目：[CapSoftware/Cap](https://github.com/CapSoftware/Cap)
