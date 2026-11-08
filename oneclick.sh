#!/system/bin/sh
# ============================================================================
#  oneclick.sh —— 手动补装 / 重装 / 重新导入 / 应用设置
#   su -c 'sh /data/adb/modules/hide_bundle/oneclick.sh'
#   su -c 'sh /data/adb/modules/hide_bundle/oneclick.sh --force'
#   su -c 'sh /data/adb/modules/hide_bundle/oneclick.sh --reimport'   # 强制重导配置和 keybox
# ============================================================================

MODDIR=${0%/*}
[ -d "$MODDIR" ] || MODDIR=/data/adb/modules/hide_bundle
ROOT="$MODDIR"

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

. "$MODDIR/lib.sh"
load_config "$MODDIR/config.sh"

[ "$1" = "--force" ] && FORCE_REINSTALL=1
if [ "$1" = "--reimport" ]; then
  rm -f /data/adb/hide_bundle.hma_config_done /data/adb/hide_bundle.keybox_done 2>/dev/null
fi

echo "==================================================="
echo " 一键隐藏 v2.0"
echo " ZN 1.5.2 → LSPosed → HMA-UID3.1 → OhMyKeymint → PIF-Dates"
echo "==================================================="

if ! command -v magisk >/dev/null 2>&1 && ! command -v ksud >/dev/null 2>&1 \
   && [ ! -x /data/adb/ksud ] && ! command -v apd >/dev/null 2>&1 && [ ! -x /data/adb/apd ]; then
  echo "! 没找到 magisk / ksud / apd，确认手机已经 root"
  exit 1
fi

if [ ! -d "$PAYLOAD_DIR" ]; then
  echo "! payload 目录不存在（安装时选了不保留），重刷一次本包"
  exit 1
fi

hlog "===== oneclick begin (force=$FORCE_REINSTALL) ====="

_bad=0
install_all || _bad=$?

install_hma_apk
import_hma_config
import_keybox

if zn_apply; then
  echo "- ZN 设置：denylist=$ZN_ENFORCE_DENYLIST 内存=$ZN_MEMORY_TYPE 链接器=$ZN_LINKER"
else
  echo "- ZN 设置没全写进去（daemon 没起？重启后会自动再试）"
fi

gen_app_lists
[ -f "$LIST_DIR/generated_blacklist.txt" ] && \
  echo "- 自动扫描：黑名单 $(grep -c . "$LIST_DIR/generated_blacklist.txt" 2>/dev/null) 个"

apply_denylist

echo "- 当前状态："
status_all

if [ "$_bad" = "0" ]; then
  echo ""
  echo "- 全部就绪，重启一次生效"
else
  echo ""
  echo "- 有 $_bad 个没装上，日志：/data/adb/hide_bundle.log"
fi

hlog "===== oneclick end fail=$_bad ====="
