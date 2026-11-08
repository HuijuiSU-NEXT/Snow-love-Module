#!/system/bin/sh
# ============================================================================
#  status.sh —— 给 WebUI / action.sh 用的状态输出
#  每行格式：OK <key> <显示名> | -- <key> <显示名>
# ============================================================================

MODDIR=${0%/*}
[ -d "$MODDIR" ] || MODDIR=/data/adb/modules/hide_bundle

for _p in "zygisksu:Zygisk Next" "zygisk_lsposed:LSPosed" "hma_oss_zygisk:HMA-OSS" "oh_my_keymint:OhMyKeymint" "playintegrityfix:PlayIntegrityFix"; do
  _id=${_p%%:*}
  _name=${_p#*:}
  if [ -f "/data/adb/modules/$_id/module.prop" ] && [ ! -f "/data/adb/modules/$_id/remove" ]; then
    printf 'OK %s %s\n' "$_id" "$_name"
  else
    printf -- '-- %s %s\n' "$_id" "$_name"
  fi
done

if command -v pm >/dev/null 2>&1 && pm path org.frknkrc44.hma_oss >/dev/null 2>&1; then
  printf 'OK hma_apk HMA 管理端\n'
else
  printf -- '-- hma_apk HMA 管理端\n'
fi

if ls /data/misc/hide_my_applist_*/config.json >/dev/null 2>&1; then
  printf 'OK hma_cfg HMA 配置\n'
else
  printf -- '-- hma_cfg HMA 配置\n'
fi

if [ -f /data/misc/keystore/omk/keybox.xml ]; then
  printf 'OK keybox keybox\n'
else
  printf -- '-- keybox keybox\n'
fi
