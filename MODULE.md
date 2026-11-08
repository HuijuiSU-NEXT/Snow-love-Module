> 模块自身说明（安装/配置细节）。仓库总览见 [README.md](README.md)。

# 一键隐藏 v1.3（91 模块整合）

作者：恋雪 ｜ 版本：v1.3

| 顺序 | 模块 | id | 说明 |
|---|---|---|---|
| 1 | Zygisk Next 1.5.2 | `zygisksu` | 独立 Zygisk 实现 |
| 2 | LSPosed 2.2.1 | `zygisk_lsposed` | Xposed 框架 |
| 3 | HMA-OSS UID3.1 (arm64) | `hma_oss_zygisk` | 隐藏应用列表 |
| 4 | OhMyKeymint R1 1.3.6 | `oh_my_keymint` | KeyMint / Play 完整性 |
| 5 | PlayIntegrityFix-Dates v4.9 | `playintegrityfix` | PIF（本地日期模式） |
| + | HMA 管理端 APK | `org.frknkrc44.hma_oss` | HMA 界面 |

装完自动：装 HMA 管理端 → 导入 keybox → 应用 Zygisk Next 设置（`enforce-denylist just_umount` / `memory-type anonymous` / `linker builtin`）→ 扫描应用生成黑白名单并写 denylist。

## 命令

```sh
su -c 'sh /data/adb/modules/hide_bundle/oneclick.sh'
su -c 'sh /data/adb/modules/hide_bundle/oneclick.sh --force'
su -c 'sh /data/adb/modules/hide_bundle/oneclick.sh --reimport'
su -c 'sh /data/adb/modules/hide_bundle/applist.sh --apply'
su -c 'sh /data/adb/modules/hide_bundle/status.sh'
su -c 'cat /data/adb/hide_bundle.log'
```

## 注意

- 只能从 Magisk / KernelSU / HuijuiSU 管理器装（recovery 没 magiskd）
- PIF 安装时会检查 Zygisk（装完 Zygisk Next 后能找到 libzygisk.so，能过）
- 这个包没带 HMA 的 config.json，`IMPORT_HMA_CONFIG` 默认 0；要用就把 json 放到 `hma/config.json` 再改成 1
- denylist 与 HMA 的取舍：`enabled` 下进 denylist 的应用 Zygisk 不注入，HMA 也失效；默认 `just_umount` 是折中
- 仅供自己本机使用，别外传（Zygisk Next 禁止再分发）
