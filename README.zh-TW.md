[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Русский](README.ru.md)

# Snow-Love Module

> 一鍵隱藏模組 —— 刷入即用，不需要逐項設定。

## 這是什麼

把常見的偵測對抗元件打包成一個模組，刷入後自動完成環境準備。

| 元件 | 作用 |
|---|---|
| Zygisk Next | Zygisk 環境 |
| LSPosed | 模組框架 |
| HMA | 隱藏應用程式清單 |
| PIF | Play Integrity 修復 |
| SUSFS 規則 | 路徑 / 掛載點隱藏 |

目標只有一個：**減少手動設定，降低踩坑機率**。

## 特性

- **一鍵安裝**：單一 zip，刷入即完成
- **自動設定**：黑白名單、denylist、掛載隱藏自動產生
- **可回滾**：附帶 `uninstall.sh`，移除後不留殘留
- **相容**：KernelSU / SukiSU / APatch，搭配 Hybrid Mount 效果最佳

## 安裝

1. 確認裝置已刷入核心層 root（KernelSU 系列）
2. 建議先安裝元模組 **Hybrid Mount**
3. 開啟管理器 → 模組 → 安裝 → 選擇本 zip
4. 重新開機生效

## 相容性

| 環境 | 狀態 |
|---|---|
| KernelSU / SukiSU | ✅ 支援 |
| APatch | ✅ 支援 |
| Magisk | ⚠️ 未測試 |
| 非 GKI 4.x 核心 | ⚠️ 部分功能不可用 |

## 免責聲明

本模組用於**個人裝置的環境隔離與隱私保護**，請勿用於規避合法風控。

因使用本模組導致的封鎖、資料遺失、裝置異常，作者不承擔責任。刷機有風險，請先備份 boot 分區。

## 回饋

- Issue：https://github.com/HuijuiSU-NEXT/Snow-love-Module/issues
- Telegram：https://t.me/Huijui123
- 頻道：https://t.me/HuijuiSU
