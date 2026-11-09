#!/system/bin/sh
# ============================================================================
#  install_detectors.sh —— 安装内置的检测软件（detect/*.apk）
# ============================================================================

MODDIR=${0%/*}
MODROOT=$(dirname "$MODDIR")
DIR="$MODROOT/detect"

[ -d "$DIR" ] || { echo "! 包里没有 detect 目录"; exit 1; }

_ok=0
_fail=0
_list=""

for _f in "$DIR"/*.apk; do
  [ -f "$_f" ] || continue
  _name=$(basename "$_f")
  _tmp=/data/local/tmp/_install.apk
  echo "- 安装 $_name ..."

  if ! cp -f "$_f" "$_tmp" 2>/dev/null; then
    echo "  复制到 /data/local/tmp 失败"
    _fail=$((_fail + 1))
    continue
  fi

  _o=$(pm install -r -g "$_tmp" 2>&1)
  rm -f "$_tmp" 2>/dev/null

  if echo "$_o" | grep -qiE "Success|成功"; then
    echo "  OK"
    _ok=$((_ok + 1))
  else
    echo "  失败：$(echo "$_o" | tail -n 2 | tr '\n' ' ')"
    _fail=$((_fail + 1))
    _list="$_list
  - $_name"
  fi
done

echo ""
echo "完成：成功 $_ok 个，失败 $_fail 个"
if [ "$_fail" -gt 0 ]; then
  echo "失败列表：$_list"
  echo "提示：签名冲突就先卸载同名旧版；空间不足先清一下"
fi
exit 0
