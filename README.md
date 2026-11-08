[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Русский](README.ru.md)

# Snow-Love Module

> 一键隐藏模块 —— 刷入即用，不需要逐项配置。

## 这是什么

把常见的检测对抗组件打包成一个模块，刷入后自动完成环境准备。

| 组件 | 作用 |
|---|---|
| Zygisk Next | Zygisk 环境 |
| LSPosed | 模块框架 |
| HMA | 隐藏应用列表 |
| PIF | Play Integrity 修复 |
| SUSFS 规则 | 路径 / 挂载点隐藏 |

目标只有一个：**减少手动配置，降低踩坑概率**。

## 特性

- **一键安装**：单个 zip，刷入即完成
- **自动配置**：黑白名单、denylist、挂载隐藏自动生成
- **可回滚**：附带 `uninstall.sh`，卸载不留残留
- **兼容**：KernelSU / SukiSU / APatch，配合 Hybrid Mount 效果最佳

## 安装

1. 确认设备已刷入内核级 root（KernelSU 系）
2. 建议先安装元模块 **Hybrid Mount**
3. 打开管理器 → 模块 → 安装 → 选择本 zip
4. 重启生效

> 部分环境可以热激活，具体看模块是否为纯 VFS 文件计划。

## 兼容性

| 环境 | 状态 |
|---|---|
| KernelSU / SukiSU | ✅ 支持 |
| APatch | ✅ 支持 |
| Magisk | ⚠️ 未测试 |
| 非 GKI 4.x 内核 | ⚠️ 部分功能不可用 |

## 免责声明

本模块用于**个人设备的环境隔离与隐私保护**，请勿用于规避合法风控。

因使用本模块导致的封号、数据丢失、设备异常，作者不承担责任。刷机有风险，请先备份 boot 分区。

## 反馈

- Issue：https://github.com/HuijuiSU-NEXT/Snow-love-Module/issues
- Telegram：https://t.me/Huijui123
- 频道：https://t.me/HuijuiSU

## 仓库结构

```
├── module.prop          模块信息（id / 版本）
├── customize.sh         安装入口
├── oneclick.sh          一键流程
├── lib.sh               公共函数
├── config.sh            配置项
├── applist.sh           应用列表处理
├── service.sh           开机服务
├── action.sh            模块动作
├── status.sh            状态输出
├── uninstall.sh         卸载清理
├── webroot/             WebUI（管理器内打开的网页界面）
├── build.sh             打包脚本 → dist/*.zip
├── MODULE.md            模块使用说明
└── README.*.md          六语言总览
```

## 构建

```bash
sh build.sh
# 产物：dist/hide_bundle-<version>.zip
```

脚本会只打包刷入必需的文件，README 与构建脚本不进 zip。
