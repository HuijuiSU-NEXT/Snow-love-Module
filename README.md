# 一键隐藏（78 整合 · 恋雪） v1.4

> 一次刷入，装齐隐藏 root 所需的全部组件：Zygisk Next、LSPosed、HMA-OSS、OhMyKeymint、PlayIntegrityFix。
> 不用自己逐个装模块、导配置、写名单。

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Русский](README.ru.md)

---

## 一、它解决什么问题

想绕过检测，通常要手动完成这些步骤：

1. 装 Zygisk Next → 重启
2. 装 LSPosed → 重启
3. 装 HMA-OSS → 装管理端 → 导入配置 → 配黑白名单
4. 装 OhMyKeymint → 导入 keybox
5. 装 PIF-Dates → 选指纹
6. 手动写 denylist、处理挂载点

任何一步顺序错了、版本不匹配，就会出现「装了但不过检测」。

本模块把这些**全部打包并自动执行**，只需刷一次。

---

## 二、包含什么

### 内置模块（按顺序安装）

| 顺序 | 模块 | 作用 |
|---|---|---|
| 1 | **Zygisk Next 1.5.2** | Zygisk 运行环境，LSPosed 与 HMA 都依赖它 |
| 2 | **LSPosed** | 模块框架，HMA 依赖它生效 |
| 3 | **HMA-OSS UID3.1** | 隐藏应用列表 |
| 4 | **OhMyKeymint** | 提供新 keybox，改善 Play Integrity |
| 5 | **PIF-Dates** | Play Integrity 修复，按日期匹配指纹 |

### 随包附带

| 文件 | 说明 |
|---|---|
| `apk/hma-oss.apk` | HMA 管理端（配黑白名单用） |
| `hma/config.json` | 预置 HMA 配置，安装时自动导入 |
| `keybox/keybox.xml` | 预置 keybox，自动导入给 OhMyKeymint |
| `scripts/*.sh` | 春秋修复、关无线调试、导入配置、换 keybox |

### 自动完成的配置

| 项 | 说明 |
|---|---|
| Zygisk Next 设置 | 仅还原挂载 / 匿名内存 / 内置链接器 |
| denylist | 按扫描结果自动写入 |
| 黑白名单 | 扫描已装应用，按游戏、银行关键词归类 |
| HMA 配置 | 写入 `/data/misc/hide_my_applist_*/config.json` |
| keybox | 写入 OhMyKeymint 目录 |
| 挂载隐藏 | 隐藏 `/data/adb` 相关路径与挂载点 |

---

## 三、WebUI 功能

管理器 → 模块 → `hide_bundle` → 打开 WebUI。

### 状态区

顶部实时显示 9 个状态：Zygisk Next、LSPosed、HMA-OSS、OhMyKeymint、PlayIntegrityFix、HMA 管理端、HMA 配置、keybox。绿灯表示就绪。

### 核心功能

| 按钮 | 作用 | 什么时候用 |
|---|---|---|
| **补装 / 应用设置** | 重新执行完整安装流程 | 某模块没装上、换内核后 |
| **重扫名单** | 重新扫描应用并生成黑白名单 | 装了新游戏 / 银行 App |
| **刷新状态** | 重新读取就绪情况 | 界面显示滞后 |
| **查看日志** | 打开 `/data/adb/hide_bundle.log` | 排错必看 |

### 密钥与配置

| 功能 | 说明 |
|---|---|
| **替换 keybox** | 选 `/sdcard/Download/keybox.xml` 等文件替换 |
| **导入 HMA 配置** | 选外部 `config.json` 覆盖 |
| **用包内自带配置** | 恢复成模块自带配置 |
| **重新导入模块配置** | `oneclick.sh --reimport`，强制重导 HMA 配置与 keybox |

### 检测与环境

| 功能 | 说明 |
|---|---|
| **关闭无线调试** | 关掉无线 ADB，少一个被检测面 |
| **春秋修复工具** | 复制修复脚本到 Download，按提示用 MT 以 root 运行 |

---

## 四、配置文件

`config.sh` 可改行为，改完重启或执行 `oneclick.sh` 生效。

### 名单

| 配置 | 默认 | 说明 |
|---|---|---|
| `DENY_PKGS` | 空 | 手动补充要隐藏的包名，空格分隔 |
| `ENABLE_DENYLIST` | 1 | 是否写 denylist |
| `AUTO_LIST` | 1 | 是否自动扫描生成黑白名单 |
| `GAME_KEYS` / `BANK_KEYS` | 关键词 | 命中的应用归入黑名单 |
| `EXTRA_BLACKLIST` / `EXTRA_WHITELIST` | 微信 / QQ 在白名单 | 手动追加 |

> `generated_*` 每次开机重扫；`blacklist.txt` / `whitelist.txt` 是手写的，不会被覆盖。

### 组件

| 配置 | 默认 | 说明 |
|---|---|---|
| `INSTALL_HMA_APK` | 1 | 是否安装 HMA 管理端 |
| `HMA_APK_URL` | 空 | 包内 APK 缺失时的下载地址 |
| `IMPORT_HMA_CONFIG` | 1 | 是否导入 `hma/config.json` |
| `IMPORT_KEYBOX` | 1 | 是否导入 keybox |

### Zygisk Next

| 配置 | 默认 | 说明 |
|---|---|---|
| `ZN_APPLY` | 1 | 是否应用 ZN 设置 |
| `ZN_ENFORCE_DENYLIST` | `just_umount` | `disabled` / `enabled` / `just_umount` |
| `ZN_MEMORY_TYPE` | `anonymous` | `anonymous` / `default` |
| `ZN_LINKER` | `builtin` | `builtin` / `system` |
| `ZN_DENYLIST_POLICY` | `default` | `default` / `whitelist` |

### 安装行为

| 配置 | 默认 | 说明 |
|---|---|---|
| `FORCE_REINSTALL` | 0 | 强制重装已存在的模块 |
| `AUTO_RETRY` / `AUTO_RETRY_MAX` | 1 / 3 | 失败自动重试 |
| `KEEP_PAYLOAD` | 1 | 保留 payload（补装要用） |

---

## 五、安装

1. 确认已有内核级 root（KernelSU / SukiSU / APatch）
2. 管理器 → 模块 → 安装 → 选择 `hide_bundle_v1.4.zip`
3. 等待安装（会依次装 5 个模块）
4. **重启**
5. 打开 WebUI 刷新状态，全绿即完成

---

## 六、v1.4 修复了什么

| # | 问题 | 修复 |
|---|---|---|
| 1 | `scripts/chunqiu_fix.sh` 找的是 `JinBeiChunQiuFixToolPro2.sh`，包内实际叫 `jinbei_chunqiu_fix.sh` | 改成实际文件名 |
| 2 | `customize.sh` 兜底解压列表缺 `scripts/*`，部分管理器解压不全时脚本会缺失 | 补齐 `scripts/*` |

---

## 七、常见问题

### 装完检测还是不过

1. WebUI 看状态是否全绿
2. 检查 Zygisk Next：`su -c 'ls /data/adb/modules/zygisksu'`
3. 点「重扫名单」重新生成
4. 换 keybox 试试
5. 看日志 `/data/adb/hide_bundle.log`

### 某个模块没装上

- WebUI 点「补装 / 应用设置」重试
- 检查空间：`su -c 'df -h /data'`
- 签名冲突：先卸载同名旧版再补装

### 开机卡 logo

- 多半是 Zygisk / LSPosed 与内核不兼容
- `su -c 'touch /data/adb/modules/zygisksu/disable'` 禁用后重启

### 春秋修复工具点了没反应

- 它只是把脚本复制到 `/sdcard/Download/JinBeiChunQiuFixToolPro2.sh`
- 必须用 MT 管理器「以 ROOT 运行」，脚本是交互式的

---

## 八、目录结构

```
hide_bundle/
├── module.prop
├── customize.sh        安装入口
├── oneclick.sh         补装 / 重装
├── lib.sh              公共函数
├── config.sh           配置项
├── service.sh          开机服务
├── action.sh           管理器动作
├── status.sh           状态输出
├── uninstall.sh        卸载清理
├── payload/            5 个模块 zip
├── apk/hma-oss.apk     HMA 管理端
├── hma/config.json     HMA 配置
├── keybox/keybox.xml   keybox
├── scripts/            工具脚本
└── webroot/            WebUI
```

---

## 九、日志与排错

| 内容 | 位置 |
|---|---|
| 模块主日志 | `/data/adb/hide_bundle.log` |
| 补装输出 | WebUI「输出」区域 |
| 模块状态 | `su -c 'sh /data/adb/modules/hide_bundle/status.sh'` |

---

## 十、免责声明

本模块用于**个人设备的环境隔离与隐私保护**，请勿用于规避合法风控。

因使用本模块导致的封号、数据丢失、设备异常，作者不承担责任。刷机有风险，请先备份 boot 分区。

---

## 十一、反馈

- Issue：https://github.com/HuijuiSU-NEXT/Snow-love-Module/issues
- Telegram 群：https://t.me/Huijui123
- Telegram 频道：https://t.me/HuijuiSU
- QQ 群：763278354

---

## 十二、许可

**GPL-3.0**，详见 [LICENSE](LICENSE)。二次分发请保留原作者署名。
