#!/system/bin/sh
# ============================================================================
#  lib.sh —— 共用函数（customize.sh / service.sh / oneclick.sh / applist.sh）
#  调用方需要先设置 ROOT（本模块目录）
# ============================================================================

ROOT=${ROOT:-${0%/*}}
[ -d "$ROOT" ] || ROOT=/data/adb/modules/hide_bundle
PAYLOAD_DIR="$ROOT/payload"
LIST_DIR="$ROOT/lists"
BLOG=${BLOG:-/data/adb/hide_bundle.log}

hlog() { printf '%s %s\n' "$(date '+%m-%d %H:%M:%S' 2>/dev/null)" "$*" >> "$BLOG" 2>/dev/null; }

ui() {
  if command -v ui_print >/dev/null 2>&1; then
    ui_print "$1"
  else
    echo "$1"
  fi
}

load_config() {
  _cfg="$1"
  [ -f "$_cfg" ] || return 0
  if /system/bin/sh -n "$_cfg" 2>/dev/null; then
    _tmp=/data/adb/.hide_bundle_config
    if tr -d '\r' < "$_cfg" > "$_tmp" 2>/dev/null; then
      . "$_tmp"
      rm -f "$_tmp" 2>/dev/null
    fi
  else
    hlog "WARN: config.sh 语法错误，使用默认值"
  fi
}

# ---------------------------------------------------------------------------
# root 管理器识别（Magisk / KernelSU / HuijuiSU / BakaSU / APatch）
# ---------------------------------------------------------------------------
root_manager() {
  if [ -n "$MAGISK_VER_CODE" ] || command -v magisk >/dev/null 2>&1; then
    printf 'Magisk'
    return 0
  fi
  if [ -n "$KSU" ] || [ -x /data/adb/ksud ] || [ -x /data/adb/ksu/bin/ksud ] || command -v ksud >/dev/null 2>&1; then
    _v=$(ksud --version 2>/dev/null | head -n 1)
    case "$_v" in
      *[Hh]uijui*)  printf 'HuijuiSU'; return 0 ;;
      *[Bb]aka*)    printf 'BakaSU';   return 0 ;;
      *[Kk]ernel*)  printf 'KernelSU'; return 0 ;;
    esac
    [ -d /data/adb/ksu ] && { printf 'KernelSU 系(HuijuiSU/BakaSU)'; return 0; }
    printf 'KernelSU 系'
    return 0
  fi
  if [ -n "$APATCH" ] || [ -x /data/adb/apd ]; then
    printf 'APatch'
    return 0
  fi
  printf 'unknown'
}

# ---------------------------------------------------------------------------
# 模块安装
# ---------------------------------------------------------------------------
cleanup_partial() {
  [ -n "$1" ] || return 0
  if [ -d "/data/adb/modules_update/$1" ]; then
    rm -rf "/data/adb/modules_update/$1" 2>/dev/null
    hlog "cleanup partial modules_update/$1"
  fi
}

_run() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 300 "$@" >>"$BLOG" 2>&1
    return $?
  fi
  "$@" >>"$BLOG" 2>&1
}

install_zip() {
  _z="$1"
  _id="$2"
  [ -f "$_z" ] || return 1

  _rc=1
  if command -v magisk >/dev/null 2>&1; then
    _run magisk --install-module "$_z"
    _rc=$?
    [ "$_rc" = "0" ] && return 0
    [ "$_rc" = "124" ] && { hlog "TIMEOUT: $_id"; sleep 2; cleanup_partial "$_id"; return 1; }
  fi
  if command -v ksud >/dev/null 2>&1; then
    _run ksud module install "$_z" && return 0
  fi
  if [ -x /data/adb/ksud ]; then
    _run /data/adb/ksud module install "$_z" && return 0
  fi
  if [ -x /data/adb/ksu/bin/ksud ]; then
    _run /data/adb/ksu/bin/ksud module install "$_z" && return 0
  fi
  if command -v apd >/dev/null 2>&1; then
    _run apd module install "$_z" && return 0
  fi
  if [ -x /data/adb/apd ]; then
    _run /data/adb/apd module install "$_z" && return 0
  fi

  cleanup_partial "$_id"
  return 1
}

module_installed() {
  [ -f "/data/adb/modules/$1/remove" ] && return 1
  [ -f "/data/adb/modules/$1/module.prop" ] && return 0
  [ -f "/data/adb/modules_update/$1/module.prop" ] && return 0
  return 1
}

install_one() {
  _label="$1"
  _file="$2"
  _id="$3"

  if [ ! -f "$_file" ]; then
    ui "! $_label：缺少 $(basename "$_file")"
    hlog "MISSING $_label"
    return 1
  fi

  if module_installed "$_id" && [ "$FORCE_REINSTALL" != "1" ]; then
    ui "- $_label 已安装，跳过"
    hlog "SKIP $_label"
    return 0
  fi

  ui "- 正在安装 $_label ..."
  hlog "INSTALL $_label"

  if install_zip "$_file" "$_id" && module_installed "$_id"; then
    ui "- $_label 安装完成"
    hlog "OK $_label"
    return 0
  fi

  cleanup_partial "$_id"
  ui "! $_label 安装失败"
  hlog "FAIL $_label"
  tail -n 20 "$BLOG" 2>/dev/null | while IFS= read -r _l; do ui "  $_l"; done
  return 1
}

install_all() {
  _failn=0
  install_one "Zygisk Next 1.5.2" "$PAYLOAD_DIR/01-zygisk-next.zip"    "zygisksu"       || _failn=$((_failn + 1))
  install_one "LSPosed 2.2.1"     "$PAYLOAD_DIR/02-lsposed.zip"        "zygisk_lsposed" || _failn=$((_failn + 1))
  install_one "HMA-OSS UID3.1"    "$PAYLOAD_DIR/03-hma-oss-uid.zip"    "hma_oss_zygisk" || _failn=$((_failn + 1))
  install_one "OhMyKeymint"       "$PAYLOAD_DIR/04-oh-my-keymint.zip"  "oh_my_keymint"  || _failn=$((_failn + 1))
  install_one "PlayIntegrityFix"  "$PAYLOAD_DIR/05-pif-dates.zip"       "playintegrityfix" || _failn=$((_failn + 1))
  return "$_failn"
}

all_installed() {
  module_installed zygisksu && module_installed zygisk_lsposed \
    && module_installed hma_oss_zygisk && module_installed oh_my_keymint \
    && module_installed playintegrityfix
}

# ---------------------------------------------------------------------------
# HMA 管理端 APK：优先用自带的 apk/hma-oss.apk，没有才按 HMA_APK_URL 下载
# ---------------------------------------------------------------------------
HMA_PKG=org.frknkrc44.hma_oss
HMA_APK_DONE=/data/adb/hide_bundle.apk_done
HMA_APK_FAIL=/data/adb/hide_bundle.hma_fail

hma_apk_installed() {
  command -v pm >/dev/null 2>&1 || return 1
  pm path "$HMA_PKG" >/dev/null 2>&1 && return 0
  return 1
}

fetch_hma_apk() {
  _dst="$1"
  [ -n "$HMA_APK_URL" ] || return 1
  ui "- 下载 HMA 管理端 APK ..."
  if command -v curl >/dev/null 2>&1; then
    curl -fL --connect-timeout 20 -o "$_dst" "$HMA_APK_URL" >>"$BLOG" 2>&1 && return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -O "$_dst" "$HMA_APK_URL" >>"$BLOG" 2>&1 && return 0
  fi
  return 1
}

install_hma_apk() {
  [ "$INSTALL_HMA_APK" = "1" ] || return 0

  if hma_apk_installed; then
    : > "$HMA_APK_DONE" 2>/dev/null
    hlog "HMA apk already installed"
    return 0
  fi

  # 装成功过又被用户手动卸了 → 尊重用户，不再装回来
  if [ -f "$HMA_APK_DONE" ]; then
    hlog "HMA apk removed by user, skip"
    return 1
  fi

  _fn=$(cat "$HMA_APK_FAIL" 2>/dev/null)
  case "$_fn" in ''|*[!0-9]*) _fn=0 ;; esac
  [ "$_fn" -ge 3 ] && { hlog "HMA apk: give up after $_fn failures"; return 1; }

  _apk="$ROOT/apk/hma-oss.apk"
  if [ ! -s "$_apk" ]; then
    mkdir -p "$ROOT/apk" 2>/dev/null
    fetch_hma_apk "$_apk" || hlog "HMA apk: no bundled apk and download failed"
  fi
  [ -s "$_apk" ] || { ui "! 没有 HMA 管理端 APK"; return 1; }

  # 拷到 /data/local/tmp 再装，避开 pm 读不到 /data/adb 的可能性
  _tmpapk=/data/local/tmp/hma-oss.apk
  cp -f "$_apk" "$_tmpapk" 2>/dev/null || _tmpapk="$_apk"
  chmod 0644 "$_tmpapk" 2>/dev/null

  ui "- 安装 HMA 管理端 APK ..."
  if command -v pm >/dev/null 2>&1; then
    pm install -r -g "$_tmpapk" >>"$BLOG" 2>&1
    rm -f "$_tmpapk" 2>/dev/null
    if hma_apk_installed; then
      ui "- HMA 管理端安装完成"
      hlog "HMA apk installed"
      : > "$HMA_APK_DONE" 2>/dev/null
      rm -f "$HMA_APK_FAIL" 2>/dev/null
      return 0
    fi
  fi

  _fn=$((_fn + 1))
  printf '%s\n' "$_fn" > "$HMA_APK_FAIL" 2>/dev/null
  ui "! HMA 管理端安装失败（第 $_fn 次）"
  ui "  手动装：/data/adb/modules/hide_bundle/apk/hma-oss.apk"
  ui "  提示签名冲突就先卸掉旧版 HMA"
  hlog "HMA apk install failed ($_fn)"
  return 1
}

# ---------------------------------------------------------------------------
# 导入 HMA 配置：/data/misc/hide_my_applist_<rand16>/config.json
#   属主 system:system，文件 0600，目录 0700（见 HMA 的 41-fix-one-click-hide-mess.sh）
# ---------------------------------------------------------------------------
HMA_CFG_SRC="$ROOT/hma/config.json"
HMA_CFG_DONE=/data/adb/hide_bundle.hma_config_done

import_hma_config() {
  [ "$IMPORT_HMA_CONFIG" = "1" ] || return 0
  [ -f "$HMA_CFG_SRC" ] || { hlog "hma cfg: source missing"; return 1; }
  [ -f "$HMA_CFG_DONE" ] && { hlog "hma cfg: already imported"; return 0; }

  _dir=""
  for _d in /data/misc/hide_my_applist_*; do
    [ -d "$_d" ] && _dir="$_d"
  done

  if [ -z "$_dir" ]; then
    _rnd=$(tr -dc 'a-z0-9' < /dev/urandom 2>/dev/null | dd bs=1 count=16 2>/dev/null)
    [ -n "$_rnd" ] || _rnd="r$$"
    _dir="/data/misc/hide_my_applist_$_rnd"
    mkdir -p "$_dir" 2>/dev/null || { hlog "hma cfg: mkdir failed"; return 1; }
  fi

  [ -f "$_dir/config.json" ] && cp -f "$_dir/config.json" "$_dir/config.json.bak.$(date +%s)" 2>/dev/null

  if cp -f "$HMA_CFG_SRC" "$_dir/config.json" 2>/dev/null; then
    chown system:system "$_dir" 2>/dev/null
    chmod 700 "$_dir" 2>/dev/null
    chown system:system "$_dir/config.json" 2>/dev/null
    chmod 600 "$_dir/config.json" 2>/dev/null
    : > "$HMA_CFG_DONE" 2>/dev/null
    ui "- HMA 配置已导入：$_dir/config.json"
    hlog "hma cfg imported to $_dir/config.json"
    return 0
  fi

  ui "! HMA 配置导入失败"
  hlog "hma cfg: copy failed"
  return 1
}

# ---------------------------------------------------------------------------
# 导入 keybox → OhMyKeymint（/data/misc/keystore/omk/keybox.xml，keystore 1017）
# ---------------------------------------------------------------------------
KEYBOX_SRC="$ROOT/keybox/keybox.xml"
KEYBOX_DONE=/data/adb/hide_bundle.keybox_done
OMK_MOD=/data/adb/modules/oh_my_keymint
OMK_DIR=/data/misc/keystore/omk
OMK_KEYBOX="$OMK_DIR/keybox.xml"

import_keybox() {
  [ "$IMPORT_KEYBOX" = "1" ] || return 0
  [ -f "$KEYBOX_SRC" ] || { hlog "keybox: source missing"; return 1; }
  [ -f "$KEYBOX_DONE" ] && return 0

  _ok=0

  # 1) 模块目录（OhMyKeymint 首次开机时 post-fs-data 会拷过去）
  if [ -d "$OMK_MOD" ]; then
    if cp -f "$KEYBOX_SRC" "$OMK_MOD/keybox.xml" 2>/dev/null; then
      chmod 0644 "$OMK_MOD/keybox.xml" 2>/dev/null
      _ok=1
    fi
  fi

  # 2) 运行时目录（已经存在就直接覆盖，先备份）
  if [ -d "$OMK_DIR" ]; then
    [ -f "$OMK_KEYBOX" ] && cp -f "$OMK_KEYBOX" "$OMK_KEYBOX.bak.$(date +%s)" 2>/dev/null
    if cp -f "$KEYBOX_SRC" "$OMK_KEYBOX" 2>/dev/null; then
      chown 1017:1017 "$OMK_KEYBOX" 2>/dev/null
      chmod 0600 "$OMK_KEYBOX" 2>/dev/null
      _ok=1
    fi
  fi

  if [ "$_ok" = "1" ]; then
    : > "$KEYBOX_DONE" 2>/dev/null
    # 让 OhMyKeymint 重新加载 keymint
    mkdir -p /data/adb/omk 2>/dev/null
    : > /data/adb/omk/restart.keymint 2>/dev/null
    ui "- keybox 已导入"
    hlog "keybox imported"
    return 0
  fi

  hlog "keybox: import failed (OMK not installed yet?)"
  return 1
}

# ---------------------------------------------------------------------------
# Zygisk Next 设置
# ---------------------------------------------------------------------------
zn_bin() {
  if [ -x /data/adb/modules/zygisksu/bin/zygiskd ]; then
    printf '%s' /data/adb/modules/zygisksu/bin/zygiskd
    return 0
  fi
  if [ -x /data/adb/modules_update/zygisksu/bin/zygiskd ]; then
    printf '%s' /data/adb/modules_update/zygisksu/bin/zygiskd
    return 0
  fi
  return 1
}

zn_apply() {
  [ "$ZN_APPLY" = "1" ] || return 0

  _bin=$(zn_bin)
  [ -n "$_bin" ] || { hlog "zn: zygiskd not found"; return 1; }

  case "$ZN_ENFORCE_DENYLIST" in
    disabled|enabled|just_umount) ;;
    *) ZN_ENFORCE_DENYLIST=just_umount ;;
  esac
  case "$ZN_MEMORY_TYPE" in
    anonymous|default) ;;
    *) ZN_MEMORY_TYPE=anonymous ;;
  esac
  case "$ZN_LINKER" in
    builtin|system) ;;
    *) ZN_LINKER=builtin ;;
  esac
  case "$ZN_DENYLIST_POLICY" in
    whitelist|default) ;;
    *) ZN_DENYLIST_POLICY=default ;;
  esac

  _ok=0
  for _pair in "enforce-denylist:$ZN_ENFORCE_DENYLIST" \
               "memory-type:$ZN_MEMORY_TYPE" \
               "linker:$ZN_LINKER" \
               "denylist-policy:$ZN_DENYLIST_POLICY"; do
    _cmd=${_pair%%:*}
    _val=${_pair#*:}
    if "$_bin" "$_cmd" "$_val" >>"$BLOG" 2>&1; then
      _ok=$((_ok + 1))
      hlog "zn ok: $_cmd $_val"
    else
      hlog "zn FAIL: $_cmd $_val"
    fi
  done

  [ "$_ok" = "4" ] && return 0
  return 1
}

# ---------------------------------------------------------------------------
# 自动黑白名单
# ---------------------------------------------------------------------------
is_match() {
  # $1 已小写文本   $2 已小写、| 分隔的关键词
  [ -n "$1" ] && [ -n "$2" ] || return 1
  _t=$1
  _oldifs=$IFS
  IFS='|'
  set -f
  for _kw in $2; do
    [ -n "$_kw" ] || continue
    case "$_t" in
      *"$_kw"*) IFS=$_oldifs; set +f; return 0 ;;
    esac
  done
  IFS=$_oldifs
  set +f
  return 1
}

list_packages() {
  command -v pm >/dev/null 2>&1 || return 1
  pm list packages -3 2>/dev/null | cut -d: -f2 | sort
}

gen_app_lists() {
  [ "$AUTO_LIST" = "1" ] || return 0

  mkdir -p "$LIST_DIR" 2>/dev/null

  _pkgs=$(list_packages)
  if [ -z "$_pkgs" ]; then
    hlog "applist: no packages found, skip"
    return 1
  fi

  [ -f "$LIST_DIR/blacklist.txt" ] || printf '# 手动加：一行一个包名，要隐藏的\n' > "$LIST_DIR/blacklist.txt" 2>/dev/null
  [ -f "$LIST_DIR/whitelist.txt" ] || printf '# 手动加：一行一个包名，永远不隐藏\n' > "$LIST_DIR/whitelist.txt" 2>/dev/null

  _bl="$LIST_DIR/generated_blacklist.txt"
  _wl="$LIST_DIR/generated_whitelist.txt"
  : > "$_bl" 2>/dev/null
  : > "$_wl" 2>/dev/null

  _game=$(printf '%s' "$GAME_KEYS"        | tr 'A-Z' 'a-z' | tr ' ' '|')
  _bank=$(printf '%s' "$BANK_KEYS"        | tr 'A-Z' 'a-z' | tr ' ' '|')
  _xbl=$(printf '%s'  "$EXTRA_BLACKLIST"  | tr 'A-Z' 'a-z' | tr ' ' '|')
  _xwl=$(printf '%s'  "$EXTRA_WHITELIST"  | tr 'A-Z' 'a-z' | tr ' ' '|')

  _n=0
  _w=0
  for _p in $_pkgs; do
    _lp=$(printf '%s' "$_p" | tr 'A-Z' 'a-z')
    if is_match "$_lp" "$_xwl"; then
      printf '%s\n' "$_p" >> "$_wl"
      _w=$((_w + 1))
      continue
    fi
    if is_match "$_lp" "$_game" || is_match "$_lp" "$_bank" || is_match "$_lp" "$_xbl"; then
      printf '%s\n' "$_p" >> "$_bl"
      _n=$((_n + 1))
    fi
  done

  hlog "applist: generated blacklist=$_n whitelist=$_w"
  return 0
}

# ---------------------------------------------------------------------------
# denylist 同步
# ---------------------------------------------------------------------------
APPLIED="$LIST_DIR/applied.txt"

add_want() {
  case "$1" in
    *[!a-zA-Z0-9._:]*) return 0 ;;
  esac
  case " $_want " in *" $1 "*) return 0 ;; esac
  case " $_wl_list " in *" $1 "*) return 0 ;; esac
  _want="$_want $1"
}

apply_denylist() {
  [ "$ENABLE_DENYLIST" = "1" ] || return 0
  command -v magisk >/dev/null 2>&1 || { hlog "denylist skipped (no magisk)"; return 0; }

  mkdir -p "$LIST_DIR" 2>/dev/null

  _wl_list=""
  for _f in "$LIST_DIR/whitelist.txt" "$LIST_DIR/generated_whitelist.txt"; do
    [ -f "$_f" ] || continue
    while IFS= read -r _p; do
      [ -n "$_p" ] || continue
      case "$_p" in *[!a-zA-Z0-9._:]*) continue ;; esac
      _wl_list="$_wl_list $_p"
    done < "$_f"
  done

  _want=""
  for _p in $DENY_PKGS; do
    add_want "$_p"
  done

  if [ "$LIST_APPLY_DENYLIST" = "1" ]; then
    for _f in "$LIST_DIR/blacklist.txt" "$LIST_DIR/generated_blacklist.txt"; do
      [ -f "$_f" ] || continue
      while IFS= read -r _p; do
        [ -n "$_p" ] || continue
        add_want "$_p"
      done < "$_f"
    done
  fi

  [ -n "$_want" ] || return 0

  magisk --denylist enable >>"$BLOG" 2>&1

  _old=$(tr '\n' ' ' < "$APPLIED" 2>/dev/null)

  _added=0
  _failed=0
  for _p in $_want; do
    case " $_old " in
      *" $_p "*) ;;
      *)
        if magisk --denylist add "$_p" >>"$BLOG" 2>&1; then
          _added=$((_added + 1))
        else
          _failed=$((_failed + 1))
          hlog "denylist add FAILED: $_p"
        fi
        ;;
    esac
  done

  _removed=0
  for _p in $_old; do
    case " $_want " in
      *" $_p "*) ;;
      *)
        magisk --denylist rm "$_p" >>"$BLOG" 2>&1 && _removed=$((_removed + 1))
        ;;
    esac
  done

  printf '%s\n' $_want > "$APPLIED" 2>/dev/null

  hlog "denylist synced: added=$_added removed=$_removed failed=$_failed"
}

status_all() {
  for _s in "zygisksu:Zygisk Next" "zygisk_lsposed:LSPosed" "hma_oss_zygisk:HMA-OSS" "oh_my_keymint:OhMyKeymint" "playintegrityfix:PlayIntegrityFix"; do
    _id=${_s%%:*}
    _name=${_s#*:}
    if module_installed "$_id"; then
      ui "  [OK] $_name"
    else
      ui "  [--] $_name"
    fi
  done
  if hma_apk_installed; then
    ui "  [OK] HMA 管理端 APK"
  else
    ui "  [--] HMA 管理端 APK"
  fi
}
