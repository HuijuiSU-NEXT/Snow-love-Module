[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Русский](README.ru.md)

# Snow-Love Module

> ワンクリック隠蔽モジュール — 焼くだけで使えます。

## これは何か

よく使われる検出対策コンポーネントを 1 つのモジュールにまとめ、
フラッシュ後に自動で環境を整えます。

| コンポーネント | 役割 |
|---|---|
| Zygisk Next | Zygisk 実行環境 |
| LSPosed | モジュールフレームワーク |
| HMA | アプリ一覧の隠蔽 |
| PIF | Play Integrity 修正 |
| SUSFS ルール | パス / マウントポイントの隠蔽 |

目的は 1 つ：**手作業を減らし、つまずきを減らす**。

## 特徴

- **ワンクリック導入** — zip 1 つ、焼くだけ
- **自動設定** — 許可 / 拒否リスト、denylist、マウント隠蔽を自動生成
- **元に戻せる** — `uninstall.sh` 同梱、痕跡を残さない
- **対応** — KernelSU / SukiSU / APatch、Hybrid Mount 併用が最佳

## インストール

1. カーネルレベルの root（KernelSU 系）があることを確認
2. メタモジュール **Hybrid Mount** を先に導入
3. マネージャー → モジュール → インストール → この zip を選択
4. 再起動

## 互換性

| 環境 | 状態 |
|---|---|
| KernelSU / SukiSU | ✅ 対応 |
| APatch | ✅ 対応 |
| Magisk | ⚠️ 未検証 |
| 非 GKI 4.x カーネル | ⚠️ 一部機能は利用不可 |

## 免責事項

本モジュールは**個人端末の環境分離とプライバシー保護**のためのものです。
合法的なリスク管理を回避する目的では使用しないでください。

本モジュールの使用による BAN、データ損失、端末異常について作者は責任を負いません。
フラッシュにはリスクがあります。boot パーティションを必ずバックアップしてください。

## フィードバック

- Issue: https://github.com/HuijuiSU-NEXT/Snow-love-Module/issues
- Telegram: https://t.me/Huijui123
- チャンネル: https://t.me/HuijuiSU
