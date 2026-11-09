#!/system/bin/sh
# ============================================================================
#  disable_wireless_adb.sh —— 关闭「无线调试」
#    先看开发者选项有没有开；没开就说明无线调试本来就没开
#    开了就把 adb_wifi_enabled 置 0 并回读确认
# ============================================================================

_dev=$(settings get global development_settings_enabled 2>/dev/null)
_wifi=$(settings get global adb_wifi_enabled 2>/dev/null)

echo "- 开发者选项：${_dev:-未知}（1 开 / 0 关）"
echo "- 无线调试：  ${_wifi:-未知}（1 开 / 0 关）"

case "$_dev" in
  0)
    echo ""
    echo "开发者选项没开，无线调试本来就不可能开着，不需要处理。"
    exit 0
    ;;
  null|"")
    echo ""
    echo "! 读不到 development_settings_enabled（有些 ROM 换了开关名）"
    ;;
esac

if [ "$_wifi" = "0" ]; then
  echo ""
  echo "无线调试已经是关闭状态，不用再关。"
  exit 0
fi

echo ""
echo "- 正在关闭无线调试 ..."
settings put global adb_wifi_enabled 0 2>/dev/null
settings put global adb_wifi_port -1 2>/dev/null
setprop service.adb.tcp.port "" 2>/dev/null

sleep 1
_v=$(settings get global adb_wifi_enabled 2>/dev/null)
echo "- adb_wifi_enabled = ${_v:-未知}"

if [ "$_v" = "0" ]; then
  echo ""
  echo "完成：无线调试已关闭（USB 调试不受影响）"
else
  echo ""
  echo "! 设置没写进去。有的 ROM 需要先打开开发者选项，或者用「无线调试」开关手动关一次"
fi
exit 0
