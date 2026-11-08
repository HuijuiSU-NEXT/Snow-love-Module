#!/system/bin/sh
# 卸载本包时执行。
# 默认不删那四个子模块（各有自己的 uninstall.sh），只清理本包的标记和日志。
# 想一起删就把 REMOVE_ALL 改成 1。

REMOVE_ALL=0

rm -f /data/adb/hide_bundle.log \
      /data/adb/hide_bundle.retry \
      /data/adb/hide_bundle.pending_reboot \
      /data/adb/hide_bundle.apk_done \
      /data/adb/hide_bundle.hma_fail \
      /data/adb/hide_bundle.hma_config_done \
      /data/adb/hide_bundle.keybox_done \
      /data/adb/.hide_bundle_config 2>/dev/null

if [ "$REMOVE_ALL" = "1" ]; then
  for _m in zygisksu zygisk_lsposed hma_oss_zygisk oh_my_keymint; do
    if [ -d "/data/adb/modules/$_m" ]; then
      if [ -f "/data/adb/modules/$_m/uninstall.sh" ]; then
        MODPATH="/data/adb/modules/$_m" sh "/data/adb/modules/$_m/uninstall.sh" 2>/dev/null
      fi
      rm -rf "/data/adb/modules/$_m" 2>/dev/null
      rm -rf "/data/adb/modules_update/$_m" 2>/dev/null
    fi
  done
fi

exit 0
