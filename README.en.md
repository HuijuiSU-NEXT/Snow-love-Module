[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Русский](README.ru.md)

# Snow-Love Module

> One-click hiding module — flash and go, no manual setup.

## What it is

A single module that bundles the usual anti-detection components and prepares the
environment automatically after flashing.

| Component | Purpose |
|---|---|
| Zygisk Next | Zygisk runtime |
| LSPosed | Module framework |
| HMA | Hide app list |
| PIF | Play Integrity fix |
| SUSFS rules | Path / mount hiding |

The only goal: **less manual work, fewer pitfalls**.

## Features

- **One-click install** — single zip, flash once
- **Auto-config** — allow/deny lists, denylist, mount hiding generated for you
- **Reversible** — ships `uninstall.sh`, leaves nothing behind
- **Compatible** — KernelSU / SukiSU / APatch, best with Hybrid Mount

## Install

1. Make sure the device has kernel-level root (KernelSU family)
2. Install the meta-module **Hybrid Mount** first
3. Manager → Modules → Install → pick this zip
4. Reboot

## Compatibility

| Environment | Status |
|---|---|
| KernelSU / SukiSU | ✅ Supported |
| APatch | ✅ Supported |
| Magisk | ⚠️ Untested |
| Non-GKI 4.x kernels | ⚠️ Partially unavailable |

## Disclaimer

This module is for **personal device isolation and privacy**. Do not use it to bypass lawful risk controls.

The author is not responsible for bans, data loss or device issues caused by its use. Flashing is risky — back up your boot partition first.

## Feedback

- Issues: https://github.com/HuijuiSU-NEXT/Snow-love-Module/issues
- Telegram: https://t.me/Huijui123
- Channel: https://t.me/HuijuiSU
