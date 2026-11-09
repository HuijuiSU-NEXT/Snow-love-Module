#!/system/bin/sh
# ============================================================================
#  import_hma.sh —— 一键导入 HMA-OSS 配置（config.json）
#  用法：sh import_hma.sh <HMA-OSS_config_xxx.json 路径>
#
#    1. 备份旧配置 → 写入 /data/misc/hide_my_applist_<rand>/config.json
#    2. 重启 / 拉起 HMA
#    3. 同步 denylist 黑白名单
# ============================================================================

SRC="$1"
MODROOT=/data/adb/modules/hide_bundle

[ -n "$SRC" ] || { echo "! 用法：sh import_hma.sh <config.json 路径>"; exit 1; }
if [ ! -f "$SRC" ]; then
  echo "! 文件不存在：$SRC"
  echo "  先把 json 放到 /sdcard/Download/，再把路径填到输入框"
  exit 1
fi

_size=$(wc -c < "$SRC" 2>/dev/null | tr -d ' ')
echo "- 源文件：$SRC（${_size:-?} 字节）"

if ! grep -q '"scope"' "$SRC" 2>/dev/null; then
  echo "! 不是 HMA 配置：没有 scope 字段"
  exit 1
fi
if ! grep -q '"configVersion"' "$SRC" 2>/dev/null; then
  echo "! 不是 HMA 配置：没有 configVersion 字段"
  exit 1
fi

# HMA 装了没
_hma_pkg=""
for p in org.frknkrc44.hma_oss com.tsng.hidemyapplist com.tsng.pzyhrx.hma; do
  if [ -n "$(pm path "$p" 2>/dev/null)" ]; then _hma_pkg="$p"; break; fi
done
if [ -n "$_hma_pkg" ]; then
  echo "- HMA 已安装：$_hma_pkg"
else
  echo "- 没检测到 HMA 管理端（模块自带的 apk 应该会装上；没有也能先写配置）"
fi

# 找 / 建配置目录
_dir=""
for _d in /data/misc/hide_my_applist_*; do
  [ -d "$_d" ] && _dir="$_d"
done

if [ -z "$_dir" ]; then
  _rnd=$(tr -dc 'a-z0-9' < /dev/urandom 2>/dev/null | dd bs=1 count=16 2>/dev/null)
  [ -n "$_rnd" ] || _rnd="r$$"
  _dir="/data/misc/hide_my_applist_$_rnd"
  mkdir -p "$_dir" 2>/dev/null || { echo "! 创建目录失败：$_dir"; exit 1; }
  echo "- 新建配置目录：$_dir"
else
  echo "- 使用配置目录：$_dir"
fi

if [ -f "$_dir/config.json" ]; then
  cp -f "$_dir/config.json" "$_dir/config.json.bak.$(date +%s)" 2>/dev/null && echo "- 旧配置已备份"
fi

if ! cp -f "$SRC" "$_dir/config.json" 2>/dev/null; then
  echo "! 写入失败：$_dir/config.json（权限？）"
  exit 1
fi
chown system:system "$_dir" 2>/dev/null
chmod 0700 "$_dir" 2>/dev/null
chown system:system "$_dir/config.json" 2>/dev/null
chmod 0600 "$_dir/config.json" 2>/dev/null

_newsize=$(wc -c < "$_dir/config.json" 2>/dev/null | tr -d ' ')
echo "- 已写入 $_dir/config.json（${_newsize:-?} 字节）"

# 重启 HMA
for _p in org.frknkrc44.hma_oss com.tsng.hidemyapplist com.tsng.pzyhrx.hma; do
  am force-stop "$_p" 2>/dev/null
done
echo "- 已停掉 HMA 旧进程"

# 拉起 HMA（没有进程时让它读一次新配置）
if [ -n "$_hma_pkg" ]; then
  monkey -p "$_hma_pkg" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 \
    && echo "- 已尝试拉起 HMA" \
    || echo "- 拉起 HMA 失败（手动点开一次即可）"
fi

# 黑白名单
if [ -f "$MODROOT/applist.sh" ]; then
  echo "- 同步黑白名单到 denylist ..."
  sh "$MODROOT/applist.sh" --apply 2>&1 | tail -n 10
else
  echo "- 没有 applist.sh，跳过名单同步"
fi

echo ""
echo "完成。打开 HMA 检查 scope 是否是新配置；看不到就把 HMA 划掉重开一次。"
exit 0
