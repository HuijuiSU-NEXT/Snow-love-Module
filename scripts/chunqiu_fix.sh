#!/system/bin/sh
# ============================================================================
#  chunqiu_fix.sh —— 春秋检测修复工具（衿蓓 JinBeiChunQiuFixToolPro2）
#  这是一个交互式菜单脚本，不能在 WebUI 里跑，所以这里做的是：
#    1. 把内置脚本复制到 /sdcard/Download（保留原始文件名）
#    2. 校验 sha256，告诉你去 MT 里怎么运行
# ============================================================================

MODDIR=${0%/*}
MODROOT=$(dirname "$MODDIR")
SRC="$MODDIR/jinbei_chunqiu_fix.sh"
DST=/sdcard/Download/JinBeiChunQiuFixToolPro2.sh

if [ ! -f "$SRC" ]; then
  echo "! 包里没带 JinBeiChunQiuFixToolPro2.sh"
  exit 1
fi

mkdir -p /sdcard/Download 2>/dev/null
if cp -f "$SRC" "$DST" 2>/dev/null; then
  chmod 0755 "$DST" 2>/dev/null
  echo "- 已复制到 $DST"
else
  echo "! 复制到 /sdcard/Download 失败，试试用 root 文件管理器手动复制"
  echo "  源文件：$SRC"
  exit 1
fi

_sha=$(sha256sum "$DST" 2>/dev/null | cut -d' ' -f1)
[ -n "$_sha" ] && echo "- sha256: $_sha"

echo ""
echo "怎么用（这是交互菜单，必须手动跑）："
echo "  1. 打开 MT 管理器 → 设置里勾选「ROOT」"
echo "  2. 长按 $DST → 以 ROOT 运行"
echo "  3. 按它自己的菜单序号选修复项（先跑一次「自动体检」更稳）"
echo ""
echo "提示：脚本自带完整性校验，别用编辑器改它，改过会拒绝运行。"
exit 0
