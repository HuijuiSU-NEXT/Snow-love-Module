#!/system/bin/sh
# ============================================================================
#  service.sh —— 每次开机跑一次：
#    1. 检查五个模块 + HMA 管理端，缺的补装（最多 AUTO_RETRY_MAX 次）
#    2. 首次开机补做：导入 HMA 配置 / keybox（安装时没做成的话）
#    3. 应用 Zygisk Next 设置
#    4. 重扫应用、同步 denylist
#  不做常驻
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

_w=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
  sleep 2
  _w=$((_w + 2))
  [ "$_w" -ge 120 ] && break
done

RETRY_FILE=/data/adb/hide_bundle.retry
PENDING_FILE=/data/adb/hide_bundle.pending_reboot

case "$AUTO_RETRY_MAX" in ''|*[!0-9]*) AUTO_RETRY_MAX=3 ;; esac
[ "$AUTO_RETRY_MAX" -gt 10 ] && AUTO_RETRY_MAX=10

hlog "boot: bundle service start (root=$(root_manager))"

[ -f "$PENDING_FILE" ] && { hlog "previous retry install is active"; rm -f "$PENDING_FILE"; }

if all_installed; then
  hlog "status: all 5 modules installed"
  rm -f "$RETRY_FILE" 2>/dev/null
else
  hlog "status: some modules missing"
  if [ "$AUTO_RETRY" = "1" ]; then
    _rc=$(cat "$RETRY_FILE" 2>/dev/null)
    case "$_rc" in ''|*[!0-9]*) _rc=0 ;; esac
    if [ "$_rc" -lt "$AUTO_RETRY_MAX" ]; then
      _rc=$((_rc + 1))
      printf '%s\n' "$_rc" > "$RETRY_FILE" 2>/dev/null
      hlog "auto retry #$_rc / $AUTO_RETRY_MAX"
      install_all >>"$BLOG" 2>&1
      if all_installed; then
        hlog "retry ok, ONE MORE REBOOT needed"
        printf '1\n' > "$PENDING_FILE" 2>/dev/null
        rm -f "$RETRY_FILE" 2>/dev/null
      else
        hlog "retry incomplete"
      fi
    else
      hlog "retry limit reached, 请手动跑 oneclick.sh"
    fi
  fi
fi

install_hma_apk >/dev/null 2>&1
import_hma_config >/dev/null 2>&1
import_keybox >/dev/null 2>&1

zn_apply || hlog "zn: settings not fully applied"

gen_app_lists >/dev/null 2>&1
apply_denylist

exit 0
