#!/system/bin/sh
# ============================================================================
#  action.sh —— KernelSU / HuijuiSU 模块列表里点「操作」时执行
#  作用：快速补装 + 重新应用设置，然后把结果打到 stdout（管理器会显示）
# ============================================================================

MODDIR=${0%/*}
[ -d "$MODDIR" ] || MODDIR=/data/adb/modules/hide_bundle

echo "==== 一键隐藏 · 快速操作 ===="
echo "- 时间：$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)"
echo ""

sh "$MODDIR/oneclick.sh" 2>&1

echo ""
echo "==== 状态 ===="
sh "$MODDIR/status.sh" 2>&1

echo ""
echo "- 日志：/data/adb/hide_bundle.log"
