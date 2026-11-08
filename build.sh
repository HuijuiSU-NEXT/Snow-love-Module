#!/system/bin/sh
# 打包脚本：把当前源码打成可刷入的模块 zip
#
# 用法：sh build.sh
# 产物：dist/hide_bundle-<版本>.zip

set -e

VERSION=$(grep -m1 '^version=' module.prop | cut -d= -f2- | tr -d ' \r')
NAME=$(grep -m1 '^id=' module.prop | cut -d= -f2- | tr -d ' \r')
OUT="dist/${NAME}-${VERSION:-dev}.zip"

mkdir -p dist
rm -f "$OUT"

# 只打包刷入必需的内容；README / 多语言文档 / 构建脚本都不进 zip
zip -qr "$OUT" \
  module.prop \
  customize.sh oneclick.sh lib.sh config.sh applist.sh \
  service.sh action.sh status.sh uninstall.sh \
  webroot \
  $( [ -d apk ] && echo apk ) \
  $( [ -d payload ] && echo payload ) \
  $( [ -d keybox ] && echo keybox ) \
  -x '*.git*' '*.md' 'build.sh' 'dist/*'

echo "built: $OUT"
unzip -l "$OUT" | tail -5
