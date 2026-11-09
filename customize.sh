#!/system/bin/sh
# ============================================================================
#  customize.sh —— 安装时执行
#    1. 按顺序装 5 个模块（ZN 1.5.2 → LSPosed → HMA-UID3.1 → OhMyKeymint → PIF-Dates）
#    2. 装 HMA 管理端 APK（自带；缺了可按 HMA_APK_URL 下载）
#    3. 导入 HMA 配置（config.json）和 keybox.xml
#    4. 应用 Zygisk Next 设置（仅还原挂载 / 匿名内存 / ZN 链接器）
#    5. 扫描应用生成黑白名单并写 denylist
#  只能在 Magisk / KernelSU / APatch 管理器里装
# ============================================================================

SKIPUNZIP=0

# 兜底：有的管理器只解压 module.prop + customize.sh 就先跑我们
if [ -n "$ZIPFILE" ] && [ -f "$ZIPFILE" ]; then
  if [ ! -f "$MODPATH/lib.sh" ] || [ ! -d "$MODPATH/payload" ]; then
    unzip -o -q "$ZIPFILE" 'lib.sh' 'config.sh' 'payload/*' 'apk/*' 'hma/*' 'keybox/*' 'scripts/*' -d "$MODPATH" >/dev/null 2>&1
  fi
fi

if ! command -v ui_print >/dev/null 2>&1; then
  ui_print() { echo "$1"; }
fi
if ! command -v abort >/dev/null 2>&1; then
  abort() { echo "$1" >&2; exit 1; }
fi

if [ ! -f "$MODPATH/lib.sh" ]; then
  abort "! 解压 lib.sh 失败，请重新下载本包"
fi

# 默认值（config.sh 丢了也能跑）
DENY_PKGS=""
ENABLE_DENYLIST=1
LIST_APPLY_DENYLIST=1
AUTO_LIST=1
GAME_KEYS="tmgp|smoba|pubg|sgame|honor|mihoyo|hypergryph|roblox|minecraft|supercell|netease|tencent.tmgp"
BANK_KEYS="bank|icbc|ccb|abchina|boc|cmb|unionpay|alipay|tenpay|wallet"
EXTRA_BLACKLIST=""
EXTRA_WHITELIST="com.tencent.mm com.tencent.mobileqq"
INSTALL_HMA_APK=1
HMA_APK_URL=""
IMPORT_HMA_CONFIG=0
IMPORT_KEYBOX=1
ZN_APPLY=1
ZN_ENFORCE_DENYLIST="just_umount"
ZN_MEMORY_TYPE="anonymous"
ZN_LINKER="builtin"
ZN_DENYLIST_POLICY="default"
FORCE_REINSTALL=0
AUTO_RETRY=1
AUTO_RETRY_MAX=3
KEEP_PAYLOAD=1

ROOT="$MODPATH"
. "$ROOT/lib.sh"
load_config "$MODPATH/config.sh"

ui_print "==================================================="
ui_print " 一键隐藏 v1.4（78 整合 · 恋雪）"
ui_print " ZN 1.5.2 → LSPosed → HMA-UID3.1 → OhMyKeymint → PIF-Dates"
ui_print "==================================================="

if [ "$BOOTMODE" != true ] && [ -z "$KSU" ] && [ -z "$APATCH" ]; then
  ui_print "! 不是从管理器安装（recovery 里没有 magiskd）"
  abort "! 请用 Magisk / KernelSU / APatch 管理器安装"
fi

if [ ! -d "$PAYLOAD_DIR" ]; then
  abort "! payload 目录不存在，包可能损坏"
fi

hlog "===== v1.4 install begin (bootmode=$BOOTMODE ksu=$KSU apatch=$APATCH) ====="
ui_print "- 运行环境：$(root_manager)"

_bad=0
install_all || _bad=$?

install_hma_apk

import_hma_config
import_keybox

if zn_apply; then
  ui_print "- Zygisk Next 设置已写入（重启后生效）"
else
  ui_print "- Zygisk Next 设置这次没写全，开机后 service.sh 会再来一次"
fi

gen_app_lists
if [ -f "$LIST_DIR/generated_blacklist.txt" ]; then
  ui_print "- 自动扫描：黑名单 $(grep -c . "$LIST_DIR/generated_blacklist.txt" 2>/dev/null) 个，白名单 $(grep -c . "$LIST_DIR/generated_whitelist.txt" 2>/dev/null) 个"
  ui_print "  名单目录：$LIST_DIR/"
fi

apply_denylist

ui_print "- 当前状态："
status_all

if [ "$_bad" = "0" ]; then
  ui_print "- 五个模块全部安装成功"
  if [ "$KEEP_PAYLOAD" != "1" ]; then
    rm -rf "$PAYLOAD_DIR" 2>/dev/null
    ui_print "- 已删除 payload/ 释放空间"
  fi
else
  ui_print "- 有 $_bad 个没装上，详见 /data/adb/hide_bundle.log"
  ui_print "- 开机后可补装：su -c 'sh /data/adb/modules/hide_bundle/oneclick.sh'"
fi

ui_print "- 装完重启一次；重启后到 LSPosed 里启用 HMA-OSS"
hlog "===== v1.4 install end fail=$_bad ====="
