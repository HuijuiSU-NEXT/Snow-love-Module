#!/system/bin/sh
# ============================================================================
#  set_keybox.sh —— 替换 keybox.xml（OhMyKeymint）
#  用法：sh set_keybox.sh <keybox.xml 路径>
# ============================================================================

SRC="$1"
MODDIR=${0%/*}
[ -d "$MODDIR" ] || MODDIR=/data/adb/modules/hide_bundle
MODDIR=$(dirname "$MODDIR")

[ -n "$SRC" ] || { echo "! 用法：sh set_keybox.sh <keybox.xml 路径>"; exit 1; }
[ -f "$SRC" ] || { echo "! 文件不存在：$SRC"; exit 1; }

# 粗略校验：XML + 关键字
if ! head -c 4096 "$SRC" | grep -qi '<'; then
  echo "! 不像 XML 文件"
  exit 1
fi
if ! grep -qiE 'keybox|attestation|android' "$SRC"; then
  echo "! 内容里没有 keybox/attestation 关键字，可能不是 keybox"
  exit 1
fi

_ok=0

# 1) OhMyKeymint 模块目录（首次开机 post-fs-data 会拷到运行时目录）
if [ -d /data/adb/modules/oh_my_keymint ]; then
  if cp -f "$SRC" /data/adb/modules/oh_my_keymint/keybox.xml 2>/dev/null; then
    chmod 0644 /data/adb/modules/oh_my_keymint/keybox.xml 2>/dev/null
    echo "- 已更新 /data/adb/modules/oh_my_keymint/keybox.xml"
    _ok=1
  fi
fi

# 2) 运行时目录
mkdir -p /data/misc/keystore/omk 2>/dev/null
if [ -d /data/misc/keystore/omk ]; then
  [ -f /data/misc/keystore/omk/keybox.xml ] && \
    cp -f /data/misc/keystore/omk/keybox.xml "/data/misc/keystore/omk/keybox.xml.bak.$(date +%s)" 2>/dev/null
  if cp -f "$SRC" /data/misc/keystore/omk/keybox.xml 2>/dev/null; then
    chown 1017:1017 /data/misc/keystore/omk/keybox.xml 2>/dev/null
    chmod 0600 /data/misc/keystore/omk/keybox.xml 2>/dev/null
    echo "- 已更新 /data/misc/keystore/omk/keybox.xml"
    _ok=1
  fi
fi

if [ "$_ok" = "1" ]; then
  mkdir -p /data/adb/omk 2>/dev/null
  : > /data/adb/omk/restart.keymint 2>/dev/null
  echo "- 已触发 OhMyKeymint 重新加载"
  echo "  建议重启一次确保生效"
  exit 0
fi

echo "! 替换失败（OhMyKeymint 没装？）"
exit 1
