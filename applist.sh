#!/system/bin/sh
# ============================================================================
#  applist.sh —— 自动扫描已安装应用，生成黑名单 / 白名单
#   su -c 'sh /data/adb/modules/hide_bundle/applist.sh'
#   su -c 'sh /data/adb/modules/hide_bundle/applist.sh --apply'
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
INSTALL_HMA_APK=0
IMPORT_HMA_CONFIG=0
IMPORT_KEYBOX=0
ZN_APPLY=0

. "$MODDIR/lib.sh"
load_config "$MODDIR/config.sh"

# 只做扫描（放在 load_config 之后，避免被 config 覆盖回去）
INSTALL_HMA_APK=0
IMPORT_HMA_CONFIG=0
IMPORT_KEYBOX=0
ZN_APPLY=0

gen_app_lists || { echo "! 扫描失败（pm 不可用？）"; exit 1; }

for _f in generated_blacklist.txt blacklist.txt; do
  echo "==================================================="
  echo " 黑名单：$LIST_DIR/$_f"
  echo "==================================================="
  grep -v '^#' "$LIST_DIR/$_f" 2>/dev/null | grep .
  echo ""
done

for _f in generated_whitelist.txt whitelist.txt; do
  echo "==================================================="
  echo " 白名单：$LIST_DIR/$_f"
  echo "==================================================="
  grep -v '^#' "$LIST_DIR/$_f" 2>/dev/null | grep .
  echo ""
done

echo "改规则：config.sh 里的 GAME_KEYS / BANK_KEYS / EXTRA_BLACKLIST / EXTRA_WHITELIST"

if [ "$1" = "--apply" ]; then
  apply_denylist
  echo "- 已同步 Magisk denylist"
fi
