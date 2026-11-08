#!/system/bin/sh
# ============================================================================
#  配置（改完重启，或者 su -c 'sh /data/adb/modules/hide_bundle/oneclick.sh'）
#  注意：用 LF 换行的编辑器保存；Windows 记事本存成 CRLF 也能用，脚本会清 \r
# ============================================================================

# ---------------------------------------------------------------------------
# 一、denylist / 隐藏名单
# ---------------------------------------------------------------------------
# 手动补充要隐藏 root 的包名（空格分隔）
DENY_PKGS=""

ENABLE_DENYLIST=1
LIST_APPLY_DENYLIST=1

# ---------------------------------------------------------------------------
# 二、自动扫描应用 → 黑名单 / 白名单
#   generated_* 每次开机重扫；blacklist.txt / whitelist.txt 是你手写的，不会被覆盖
# ---------------------------------------------------------------------------
AUTO_LIST=1

GAME_KEYS="tmgp|smoba|pubg|sgame|honor|mihoyo|hypergryph|roblox|minecraft|supercell|netease|tencent.tmgp"
BANK_KEYS="bank|icbc|ccb|abchina|boc|cmb|unionpay|alipay|tenpay|wallet"

EXTRA_BLACKLIST=""
EXTRA_WHITELIST="com.tencent.mm com.tencent.mobileqq"

# ---------------------------------------------------------------------------
# 三、HMA 管理端 APK
# ---------------------------------------------------------------------------
# 1 = 装（模块里自带 apk/hma-oss.apk，HMA 模块自身的安装脚本也会装）
INSTALL_HMA_APK=1

# 自带的 APK 不存在时，从这个地址下载（留空 = 不下载）
# 例：HMA_APK_URL="https://example.com/HMA-OSS_5398de45-UID3.1.apk"
HMA_APK_URL=""

# ---------------------------------------------------------------------------
# 四、导入 HMA 配置 / keybox
# ---------------------------------------------------------------------------
# 1 = 把 hma/config.json 导入 /data/misc/hide_my_applist_*/config.json（只导一次）
# 这个整合包没带 json，默认 0；要用就把 config.json 放到 hma/ 再改成 1
IMPORT_HMA_CONFIG=0

# 1 = 把 keybox/keybox.xml 导入 OhMyKeymint（只导一次）
IMPORT_KEYBOX=1

# ---------------------------------------------------------------------------
# 五、Zygisk Next 设置（重启后生效）
# ---------------------------------------------------------------------------
ZN_APPLY=1
ZN_ENFORCE_DENYLIST="just_umount"   # disabled / enabled / just_umount(仅还原挂载)
ZN_MEMORY_TYPE="anonymous"          # anonymous / default
ZN_LINKER="builtin"                 # builtin / system
ZN_DENYLIST_POLICY="default"        # default / whitelist

# ---------------------------------------------------------------------------
# 六、安装行为
# ---------------------------------------------------------------------------
FORCE_REINSTALL=0
AUTO_RETRY=1
AUTO_RETRY_MAX=3
KEEP_PAYLOAD=1
