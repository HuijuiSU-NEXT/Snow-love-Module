#!/system/bin/sh
# =====================================================================
#  JinBeiChunQiuFixToolPro2
#  春秋检测项 · 纯 sh 可解项修复工具（Pro2）
#
#  作者 ：酷安衿蓓
#  版本 ：2.4.0
#  适配 ：春秋检测项解决方案正文 4.5.5(68)
#
#  设计原则
#   1) 只处理「用 MT 管理器以 ROOT 执行 sh 脚本就能完成」的修复：
#      文件属主/权限、目录重建、挂载卸载、属性重置、tricky_store 配置、
#      存储区异常文件清理、service.d 开机脚本部署。
#   2) 明确不处理需要内核补丁 / KPM / SUSFS / PathMask / Zygisk /
#      Xposed / 模块替换 / 只读分区写入的检测项（这些 sh 做不到）。
#   3) 启动流程：ROOT 自检 -> 脚本哈希与来源自检 -> 法律声明与同意
#      -> 环境报告 -> 主页修复菜单（修复项平铺，序号即执行）-> 分步执行。
#
#  MT 里怎么跑
#   MT 设置勾选 ROOT -> 长按本 .sh -> 以 ROOT 运行；
#   或 MT 终端执行： sh /sdcard/JinBeiChunQiuFixToolPro2.sh
#
#  融合说明（v2.4.0）
#   与「衿蓓春秋 FIXTOOL 1.1.0」融合，新增其具备而本工具原先没有的能力：
#     · 模块临时隔离 / 恢复（移出 /data/adb/modules，不删除，可回滚）
#     · 内置 Inode-Hijacker v2.3.1（离线可跑，执行前校验 SHA-256）
#     · /apex 内 su 二进制的执行位处理（只读时如实报告失败）
#     · PID 回绕 + Zygote 重启（实验性，三重确认）
#     · 按检测结果路径删除（目录白名单）、复制脚本到 service.d
#     · 自动体检（把本机状态映射为菜单序号）、来源提示（酷安）
#   内置的 Inode-Hijacker 为第三方 MIT 代码（作者 YiJieqwq，
#   https://github.com/YiJieqwq/Inode-Hijacker ，Copyright (c) 2026 YiJieqwq）。
#   按其许可要求，内嵌副本的 shebang 之后已插入版权声明与 MIT 许可全文
#   （共 27 行注释）；去掉该许可头后与上游官方 v2.3.1 发布资产逐字节一致
#   （JB_INODE_UPSTREAM_SHA），可用 --license 打印完整声明。
#   它位于 #@@PAYLOAD-ALLOW 放行区内，运行前会用 JB_INODE_SHA 再校验一次。
#
#   另有改编自「春秋检测项解决方案」（mingzun09/Chunqiu-Detector-Problem-solution，
#   MIT，Copyright (c) 2026 Su xiaoming）的内容：File/shamiko_Plus.sh、
#   File/Found property.sh、File/Tampered Attestation Key(26)Pass.sh，以及
#   language/answer_zh.md（正文命令、附录 B/C 清单、词条标题与 L#### 行号）
#   —— 均已改写/重排为 POSIX sh 实现；其版权声明与 MIT 全文同样随副本保留
#   （见 --license）。
#
#  完整性自检的边界（重要）
#   SELF_SHA256 / JB_DISPATCH_SHA / JB_INODE_SHA 都写在脚本自身里，
#   因此它们只能发现「误改、传输损坏、忘记重签的二次打包」，
#   挡不住有决心的篡改者——对方可以一并改掉摘要、甚至删掉校验代码。
#   想真正可信，必须让「期望摘要」来自脚本之外：
#     · 从发布页/仓库复制原始文件摘要，用 --verify <摘要> 运行；
#     · 或 --verify-remote（可配合 --strict 做 fail-closed）；
#     · 或在电脑上用独立工具核对：sha256sum JinBeiChunQiuFixToolPro2.sh
#   摘要请以发布页公布的「原始文件摘要」为准（--print-hash 第一行）。
#   站点/发布方需满足《哈希云端校验 · 网站侧技术要求》：
#     File/Doc/hash_cloud_verify_spec.md（URL/清单字段/HTTP/签名/防回滚/验收清单）
#
#  完整性自检说明
#   本脚本用 SELF_SHA256 做防篡改/防注入校验，计算方式为：
#     把本行  SELF_SHA256=...  归零为  SELF_SHA256=''
#     之后对整份文件求 SHA-256。
#   修改脚本后请执行：  sh 本脚本 --print-hash
#   再把输出的 64 位十六进制写回本行即可。
# =====================================================================

JB_NAME='JinBeiChunQiuFixToolPro2'
JB_AUTHOR='酷安衿蓓'
JB_VER='2.4.0'
JB_LICENSE_VER='1.0'
JB_UPDATED='2026-09'
SELF_SHA256='c61533cc81cffa8b4373fdf10e1c4c90880d5c45179f68de2f1c3186cf474c0f'
# 关键区分发（run_item 菜单 -> 动作映射）独立哈希：由 --print-hash 生成后写回；
# 即使有人只改了菜单映射（把某个序号指向别的动作），也会被单独发现。
JB_DISPATCH_SHA='417b71bfcba9451bb7aa7e57e1f820ae543e419bb3ce951bacc6201a9dbcddbd'


# 在线来源校验（可选）：填一个「只包含 64 位 sha256 文本」的地址，
# 例如作者发布的官方校验文件；留空则只做本地完整性校验。
# 也可在运行时用环境变量覆盖： JB_OFFICIAL_HASH_URL=... sh 本脚本
JB_OFFICIAL_HASH_URL=''

JB_PROJECT_URL='https://github.com/mingzun09/Chunqiu-Detector-Problem-solution'

# 春秋检测包名：固定为 com.chunqiunativecheck
JB_DETECTOR_PKG='com.chunqiunativecheck'
# 已核实命的外部脚本版本与哈希：作为 GitHub API 不可用时的回退，并在下载后校验
JB_KNOWN_INODE_VER='Inode-Hijacker v2.3.1'
JB_KNOWN_INODE_URL='https://github.com/YiJieqwq/Inode-Hijacker/releases/download/v2.3.1/Inode-Hijacker-v2.3.1.sh'
JB_KNOWN_INODE_SHA='06b343a1d7ea7c98fce2fbde9f73e3baee3817c651afdc797e8b3a7342f64a9a'
JB_KNOWN_ADB_VER='DebugTraceCleanup v1.0'
JB_KNOWN_ADB_URL='https://github.com/YiJieqwq/ADB-Trace-Cleaner/releases/download/release/BilingualVersion-.DebugTraceCleanup.sh'
JB_KNOWN_ADB_SHA='09eb1893a42cab398df5c76047611998cd66f7f92adc65822ed260f735bd28ee'

# ---- 与 FIXTOOL 1.1.0 融合的新增能力 ----
# 模块临时隔离批次目录（必须与被移动的 /data/adb/modules 同分区）
JB_QUARANTINE_ROOT='/data/adb/JinBeiChunQiuFixToolPro2/module-quarantine'
# 内置 Inode-Hijacker 运行时目录与已核实哈希（= 官方 v2.3.1 release 资产）
JB_INODE_RUNTIME='/data/adb/JinBeiChunQiuFixToolPro2/runtime'
JB_INODE_VER='Inode-Hijacker v2.3.1'
JB_INODE_SHA='dc0908e1330370033a11a429a38552f32fc97cb750448107f922eca7621ce5c3'
# 内嵌副本 = 上游官方 v2.3.1 原文 + shebang 后的 MIT 许可头（27 行）
JB_INODE_UPSTREAM_SHA='06b343a1d7ea7c98fce2fbde9f73e3baee3817c651afdc797e8b3a7342f64a9a'
JB_INODE_LICENSE_LAST_LINE=28
# 第三方代码许可声明（MIT：版权声明与许可全文必须随副本保留）
JB_THIRD_PARTY_PROJECT='Inode-Hijacker'
JB_THIRD_PARTY_AUTHOR='YiJieqwq'
JB_THIRD_PARTY_URL='https://github.com/YiJieqwq/Inode-Hijacker'
JB_THIRD_PARTY_COPYRIGHT='Copyright (c) 2026 YiJieqwq'
JB_THIRD_PARTY_LICENSE='MIT License'
JB_THIRD_PARTY_NOTICE='THIRD-PARTY-NOTICES.txt'
# 组件 2：春秋检测项解决方案（改编引用；MIT，Copyright (c) 2026 Su xiaoming）
JB_THIRD_PARTY2_PROJECT='Chunqiu-Detector-Problem-solution'
JB_THIRD_PARTY2_AUTHOR='Su xiaoming'
JB_THIRD_PARTY2_URL='https://github.com/mingzun09/Chunqiu-Detector-Problem-solution'
JB_THIRD_PARTY2_COPYRIGHT='Copyright (c) 2026 Su xiaoming'
JB_THIRD_PARTY2_LICENSE='MIT License'

# ---- 第三方代码许可声明（MIT：版权声明与许可全文随副本保留）----
third_party_notice(){
  cat <<'__JB_THIRD_PARTY_NOTICE__'
第三方代码许可声明（THIRD-PARTY NOTICES）
============================================================
本工具随副本分发以下 MIT 许可的第三方作品。按 MIT 许可要求，其版权
声明与许可声明全文随每一份副本一并保留。

【组件 1】Inode-Hijacker v2.3.1 —— 完整内嵌
 作者    ：YiJieqwq（异界）
 仓库    ：https://github.com/YiJieqwq/Inode-Hijacker
 许可    ：MIT License
 版权    ：Copyright (c) 2026 YiJieqwq
 方式    ：完整内嵌于本脚本 #@@PAYLOAD-ALLOW 区，运行时提取执行；
           内嵌副本 shebang 之后即带本节许可头

【组件 2】春秋检测项解决方案 —— 改编引用
 项目    ：Chunqiu-Detector-Problem-solution
 作者    ：Su xiaoming（铭鐏 / mingzun09）
 仓库    ：https://github.com/mingzun09/Chunqiu-Detector-Problem-solution
 许可    ：MIT License
 版权    ：Copyright (c) 2026 Su xiaoming
 改编自  ：File/shamiko_Plus.sh
             -> 本工具生成的 shamiko_Plus.sh 与属性伪装属性表（35 条）
           File/Found property.sh
             -> 菜单 1「清理 logd 缓冲区属性」
           File/Tampered Attestation Key(26)Pass.sh
             -> 菜单 14「生成 security_patch.txt」
           language/answer_zh.md（正文与附录 B / C）
             -> 各修复项的命令与判据、高危路径清单（57 条）、被检查属性
                清单（32 条）、30 个词条标题与 L#### 行号参考
 说明    ：上述内容已改写 / 重排为 POSIX sh 实现，不是逐字节复制；
           版权与许可仍归原作者。
 溯源说明：shamiko_Plus.sh 的属性集与 Shamiko / MagiskHide 族常见属性集一致（社区通行做法）
           —— 属性名与多个同族项目相互重合，属社区长期共享的接口数据；
           本工具未内嵌 Shamiko（LSPosed）的代码，Shamiko 仅作为兼容与检测对象。
           属性表的直接来源即上述春秋仓库文件。

------------------------------------------------------------
组件 1 的 MIT 许可全文：

MIT License

Copyright (c) 2026 YiJieqwq

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

------------------------------------------------------------
组件 2 的 MIT 许可全文：

MIT License

Copyright (c) 2026 Su xiaoming

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

------------------------------------------------------------

 转载、二次打包或把本工具内置到其它项目时，请把以上声明与两份许可全文
 一并保留。本工具其余部分（作者：酷安衿蓓）为独立作品；其中改编自上述
 来源的部分仍受本节约束。
__JB_THIRD_PARTY_NOTICE__
}
write_third_party_notice(){ # $1 目标路径；缺省写到 $JB_BASE/$JB_THIRD_PARTY_NOTICE
  _wn="$1"
  [ -n "$_wn" ] || _wn="$JB_BASE/$JB_THIRD_PARTY_NOTICE"
  third_party_notice > "$_wn" 2>/dev/null || return 1
  return 0
}
third_party_notice_check(){ # 分发闸门：文件里必须留着两份版权声明与 MIT 全文
  [ -f "$SELF_PATH" ] || return 1
  grep -q "$JB_THIRD_PARTY_PROJECT" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "$JB_THIRD_PARTY_AUTHOR" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "$JB_THIRD_PARTY_URL" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "$JB_THIRD_PARTY_COPYRIGHT" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "$JB_THIRD_PARTY2_PROJECT" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "$JB_THIRD_PARTY2_AUTHOR" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "$JB_THIRD_PARTY2_URL" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "$JB_THIRD_PARTY2_COPYRIGHT" "$SELF_PATH" 2>/dev/null || return 1
  grep -q 'File/shamiko_Plus.sh' "$SELF_PATH" 2>/dev/null || return 1
  grep -q 'Permission is hereby granted, free of charge' "$SELF_PATH" 2>/dev/null || return 1
  grep -q 'The above copyright notice and this permission notice shall be included in all' "$SELF_PATH" 2>/dev/null || return 1
  grep -q 'WITHOUT WARRANTY OF ANY KIND' "$SELF_PATH" 2>/dev/null || return 1
  return 0
}
notice_line(){ # 每次启动都落盘一份声明，并在屏幕上点明位置
  write_third_party_notice 2>/dev/null || true
  pln "        内置第三方代码：$JB_THIRD_PARTY_PROJECT（$JB_THIRD_PARTY_AUTHOR 作品）· $JB_THIRD_PARTY_LICENSE · $JB_THIRD_PARTY_COPYRIGHT"
  pln "        完整许可声明：菜单「致谢与开源许可」或 --license（随附 $JB_THIRD_PARTY_NOTICE）"
}

# 来源提示（仅线索，非完整性校验）
JB_SOURCE_COOLAPK='com.coolapk.market'

# ---------------------------------------------------------------------
# 0. 全局状态
# ---------------------------------------------------------------------
JB_MODE='menu'
JB_ARGS="$*"
DRY_RUN=0
JB_ASSUME_YES=0
JB_ACCEPT=0
JB_FAST=0
JB_CLEAR=0
JB_COLOR=0
JB_STEP_PAUSE=0
JB_WIDTH_ENV="${JB_WIDTH:-}"
JB_WIDTH=80
JB_SHOW_ALL=0
JB_VERIFY_EXPECT=''
JB_VERIFY_REMOTE=0
JB_VERIFY_REMOTE_URL=''
JB_ALLOW_UNVERIFIED=0
JB_STRICT=0
JB_UPDATE_URL=''
JB_WV_DEX_B64='ZGV4CjAzNwCRi5+FYAdjjD+OAVYfUK6h4+t8Z9cpdEDQGQAAcAAAAHhWNBIAAAAAAAAAAAwZAACKAAAAcAAAACAAAACYAgAAHgAAABgDAAAHAAAAgAQAAC4AAAC4BAAAAQAAACgGAACIEwAASAYAAC4QAAAxEAAANRAAADoQAABAEAAAQxAAAEsQAABWEAAAYxAAAGsQAABuEAAAehAAAH0QAACAEAAAiBAAAIwQAACQEAAAlBAAAJkQAACdEAAAyBAAAOIQAAALEQAAIREAADwRAABbEQAAchEAAIcRAACZEQAArBEAAL8RAADUEQAA5hEAAPoRAAAOEgAAIRIAADUSAABQEgAAZBIAAHsSAACcEgAAtxIAANMSAADxEgAAAxMAABMTAAArEwAANxMAAD0TAABAEwAARRMAAEkTAABOEwAAVRMAAFkTAABtEwAAcBMAAHQTAAB4EwAAjBMAAKETAAC2EwAAvRMAAM8TAADrEwAABBQAAB0UAABAFAAAaBQAAIgUAACQFAAAoBQAAK4UAAC8FAAAzxQAAOgUAADyFAAA+hQAAAEVAAAKFQAADxUAABkVAAAiFQAAOhUAAEwVAABhFQAAbRUAAHgVAACGFQAAmxUAAKcVAAC2FQAAvxUAAMwVAADWFQAA3hUAAOgVAAD0FQAA/xUAABMWAAAsFgAAMxYAAEUWAABaFgAAZxYAAHcWAACUFgAAmhYAAKEWAACoFgAAtRYAALsWAADOFgAA2xYAAOAWAADtFgAA8hYAAPsWAAAHFwAADxcAABgXAAAjFwAALBcAAEIXAABaFwAAXxcAAG4XAACGFwAAlxcAAKoXAAC7FwAAxhcAANAXAADXFwAA3BcAAOQXAADrFwAA9BcAAAkAAAALAAAAEwAAABQAAAAVAAAAFgAAABcAAAAYAAAAGQAAABoAAAAbAAAAHAAAAB4AAAAfAAAAIAAAACEAAAAiAAAAIwAAACQAAAAlAAAAJgAAACcAAAAoAAAAKQAAACoAAAArAAAAMAAAADcAAAA5AAAAOgAAADsAAAA8AAAACQAAAAAAAAAAAAAACwAAAAEAAAAAAAAADAAAAAIAAAAAAAAAEgAAAAkAAACsDwAADAAAAAsAAAAAAAAAEAAAAAsAAAC0DwAADgAAAAwAAAC8DwAADwAAAA0AAADEDwAAEAAAAA8AAADMDwAAEAAAAA8AAADUDwAAEQAAAA8AAADcDwAAEAAAAA8AAADkDwAADAAAABEAAAAAAAAADgAAABIAAAC8DwAAEAAAABIAAAC0DwAAEAAAABUAAADsDwAAEAAAABYAAAC0DwAAEQAAABcAAAD0DwAAMAAAABoAAAAAAAAAMQAAABoAAAD8DwAANAAAABoAAAAEEAAAMwAAABoAAAAQEAAAMgAAABoAAAC0DwAAMgAAABoAAAAYEAAANQAAABoAAACsDwAAMgAAABoAAAAgEAAAMgAAABoAAAAoEAAANwAAABsAAAAAAAAAOAAAABsAAAC8DwAADAAAABwAAAAAAAAABgAPAIYAAAAJAAsALwAAAAoACwAvAAAADAALAC8AAAANAAsALwAAABAACwAvAAAAEwAIAHEAAAACAB0AUQAAAAMAFwAFAAAAAwAZAEgAAAADAAAAVAAAAAMAAgBYAAAAAwAdAHAAAAADABIAeQAAAAUAAABrAAAABQAAAGwAAAAGABIABQAAAAYACAA9AAAABgASAEwAAAAGABYAXAAAAAYAEgBgAAAABgAaAGoAAAAGABQAfAAAAAgAEgBNAAAACAAWAHQAAAAJABsARwAAAAkAAwCIAAAACwAFAE4AAAALAA8AUgAAAAsAEABTAAAACwARAFYAAAALAAwAWgAAAAwABgCIAAAADQABAGEAAAANAAcAiAAAAA4AAABdAAAADgABAGEAAAAPABIABQAAAA8ABABQAAAAEgASAAUAAAASAA0ARQAAABIADgBFAAAAEgAMAIMAAAAUAAwAVQAAABUACwBtAAAAFgAJAE8AAAAWAAAAVwAAABYABABbAAAAFgAVAHwAAAAWABgAfQAAABcACgBeAAAAGAAcAF8AAAAZABMABQAAAAYAAAABAAAADwAAAAAAAAA2AAAA7BgAALcYAAAAAAAABgABAAMAAgD+DgAAMAAAABIAIwEdAG4gFQAVAAwBIwIeAG4gJQAhAAwFEQUNAWIBAABuEB8AAQAMARoCPgASEyMzHQAcBAsATQQDAG4wFwAhAwwAYgEAACQQHgAFAAwFbjArABAFDAURBQ0FEgURBQEAAAAMAAEADwAAAB0AAwACAA4ALQAAAAEAAQABAAAACA8AAAQAAABwEB4AAAAOAAcAAAADAAEADA8AADQAAAAaAEoAcRAUAAAADAAaAVkAEgIjIx0AbjAXABADDAEjIx4AEgRuMCsAQQMMARoDfgASFCNFHQAcBh8ATQYFAm4wFwAwBQwAI0MeACNEHwAaBQwATQUEAk0EAwJuMCsAEAMoAg0AAAAOAAAAAAAwAAEAAQAxAAgAAQAEAAEAFg8AAMYAAAAaAD8AcRAUAAAADABxEAoAAAAMARoCewASA3FADwADEhoCQwBxEBQAAgAMAnEQCgACAAwEGgVyAHFADwAkdRoFhQBxAAgAAAAKBnEQGQAGAAwGcUAPACRlGgVzAHEABwAAAAoGcRAZAAYADAZxQA8AJGUaBUYAcUAPACQ1GgVLABIGcRAZAAYADAZxQA8AJGUaBW4AcUAPACQ1GgV6AHFADwAkNRoFhABxQA8AJDUaAkIAcRAUAAIADAJxEAoAAgAMBRoGYwBxQA8AJUYaBGcAcUAPACU0GgRpAHFADwAlNBoCQQBxEBQAAgAMAnEQCgACAAwDGgRiAHFADwAjVBoEaABxQA8AI3QaBGUAcUAPACN0GgdAAHEQFAAHAAwHcRAKAAcADAcaAkQAcRAUAAIADAIaBGQAcUAPACc0GgJmAHFADwABcigiDQdiAAYAIgESAHAQIAABABoCCgBuICIAIQAMAW4QHwAHAAwHbhAYAAcADAduICIAcQAMB24QIwAHAAwHbiARAHAADgAAAAAAowABAAEApAECAAAAAgABADsPAAAbAAAAGgCBAHEQFAAAAAwAGgGCAG4gFgAQAAwAEhFuICoAEAASAW4gJgAQAAwAaQAAACgCDQAAAA4AAAAAAAAAFwABAAEAGAAFAAEABQAMAEMPAAD2AAAAcQANAAAAcQALAAAAGgRJAHEQDAAEACIEGQAYAM5K1nmpi+/tGALtIR3V3CfIo3BTLQAEIQAAEgAiAQMAcCABAEEAcQADAAAACgQoAw0EEuRiAAYAIgISAHAQIAACABoDDQBuICIAMgAMAm4gIQBCAAwEbhAjAAQADARuIBEAQABuEAUAAQAMBGIABgAaAi4AbiARACAAbiACAEEAKAINBChaDQRiAAYAIgISAHAQIAACABoDLABuICIAMgAMAm4QHwAEAAwEbhAYAAQADARuICIAQgAMBG4QIwAEAAwEbiARAEAAKDgNBGIEBgAaAC0AbiARAAQAbhAEAAEADARuEAAABAAMBGIABgAiAhIAcBAgAAIAGgMGAG4gIgAyAAwCOQQEABL0KAIhRG4gIQBCAAwEbhAjAAQADARuIBEAQAAosA0EYgQGABoABwBuIBEABAAop24QBgABACg6DQQoOA0EBxAoAg0EYgEGACICEgBwECAAAgAaAwgAbiAiADIADAJuEB8ABAAMA24QGAADAAwDbiAiADIADAIaAwQAbiAiADIADAJuECQABAAMBG4gIgBCAAwEbhAjAAQADARuIBEAQQA4AAUAbhAGAAAAYgQGAG4QEAAEAA4ADQQ4AAcAbhAGAAAAKAINACcEHAAAAAUAAQAhAAAABAAEACgAAAAYAAYAQAAAAAsACQBLAAAAAwANAFIAAAApAAYAewAAACUADwCiAAAABwAGAKoAAAADABIAtAAAAC4AFQDkAAAAAwASAPAAAAADABgACQCzAQAmALABfwRzUQBPAKEBAK4BAO0BAPQBAAwABAADAAIAcA8AAHsBAAASEG4gFgCpAAwBbiAqAAEAbhAnAAEACgJxECwAAgAKAjgCBwASAm4wKQAhCygEbjApAIELDgANAW4gFgCpAAwJbhAnAAkACgpxECwACgAKChIBOApBAGIIAABuEB8ACAAMCBoKgAAjAh0AHAMWAE0DAgFuMBcAqAIMCGIKAAAkEB4ACQAMAm4wKwCoAgwIHwgNAG4QGgAIAAsCYggAAG4QHwAIAAwIGgp/ACMEHQAcBRYATQUEAW4wFwCoBAwIYgoAACQQHgAJAAwEbjArAKgEDAgoJGIKAABuEB8ACgAMChoCbwAjAx0AHAQWAE0EAwFuMBcAKgMMCmICAAAkEB4ACQAMA24wKwAqAwwKHwoNAG4QGgAKAAsCAABuECgACQAMCWIKAwASJBI1MqmtAGIKBQAyqakAYgoCADOpBAApAKMAYgoEADOpOQBiCQAAbhAfAAkADAkaCncAI1YdABwHDwBNBwYBYgcEAE0HBgBiBwQATQcGBG4wFwCpBgwJYgoAACNVHgBNCAUBcSAbADIADAhNCAUAHwsOAG4QHQALAAsAcSAbABAADAhNCAUEbjArAKkFKQCfAGIKAQAzqTgAYgkAAG4QHwAJAAwJGgp1ACNWHQAcBw8ATQcGAWIHBABNBwYAYgcBAE0HBgRuMBcAqQYMCWIKAAAjVR4ATQgFAXEgGwAyAAwITQgFAB8LCQBuEBIACwAKCHEQEwAIAAwITQgFBG4wKwCpBShkYgkAAG4QHwAJAAwJGgp4ACNWHQAcBw8ATQcGAWIHBABNBwYAHAcPAE0HBgRuMBcAqQYMCWIKAAAjVR4ATQgFAXEgGwAyAAwITQgFAE0LBQRuMCsAqQUoOGIJAABuEB8ACQAMCRoKdgAjVh0AHAcPAE0HBgFiBwQATQcGAGIHAwBNBwYEbjAXAKkGDAliCgAAI1UeAE0IBQFxIBsAMgAMCE0IBQAfCw4AbhAcAAsACghxEBkACAAMCE0IBQRuMCsAqQUoAg0IAAAOAAAAAQAAABkAAQAcAAAAWwEDAAIAGwD4Ah4BAA7hHgEeDwAKAA4AFwAOaf8BGw8tAEsBAA5pS2ppS1rS0lqlWlpbaUtaWltpS1paW2lLtFwbHgEgEAAPAA5ppYctAHABAA48PFrwH2p4ARgQS3gCC1kbHgJ3ASEOHnmHAR0RGx6OZUsBLhBbWhqHACcEAAAAAA5aPPA8Hh9NtAEiDwEdEAEiDx9LARARSwEgDwEXD0sBIA8BFhABIA8CdsIBIA8CCwEWDi0AAAEAAAAbAAAAAQAAABEAAAABAAAAAAAAAAEAAAABAAAAAQAAAAsAAAABAAAADwAAAAIAAAAPAB4AAQAAAB4AAAABAAAAHQAAAAIAAAARAB0AAgAAAAEAAQAEAAAADwALABEADwACAAAADwAPAAEAAAAZAAAAAQAAABwAAAABAAAAHwABKAACKVYAAyo+OwAEKj47KQABOgAGPGluaXQ+AAlEQVRBX0xFTj0AC0RBVEFfTEVOPS0yAAZFUlJPUj0AAUkACklOSVRfRkFJTD0AAUoAAUwABkxFVkVMPQACTEkAAkxKAAJMTAADTExMAAJMWgApTGFuZHJvaWQvbWVkaWEvTWVkaWFEcm0kUHJvdmlzaW9uUmVxdWVzdDsAGExhbmRyb2lkL21lZGlhL01lZGlhRHJtOwAnTGFuZHJvaWQvbWVkaWEvTm90UHJvdmlzaW9uZWRFeGNlcHRpb247ABRMYW5kcm9pZC9vcy9Qcm9jZXNzOwAZTGNvbS94aWFmYS9XaWRldmluZVByb2JlOwAdTGRhbHZpay9hbm5vdGF0aW9uL1NpZ25hdHVyZTsAFUxqYXZhL2lvL1ByaW50U3RyZWFtOwATTGphdmEvbGFuZy9Cb29sZWFuOwAQTGphdmEvbGFuZy9CeXRlOwARTGphdmEvbGFuZy9DbGFzczsAEUxqYXZhL2xhbmcvQ2xhc3M8ABNMamF2YS9sYW5nL0ludGVnZXI7ABBMamF2YS9sYW5nL0xvbmc7ABJMamF2YS9sYW5nL051bWJlcjsAEkxqYXZhL2xhbmcvT2JqZWN0OwARTGphdmEvbGFuZy9TaG9ydDsAEkxqYXZhL2xhbmcvU3RyaW5nOwAZTGphdmEvbGFuZy9TdHJpbmdCdWlsZGVyOwASTGphdmEvbGFuZy9TeXN0ZW07ABVMamF2YS9sYW5nL1Rocm93YWJsZTsAH0xqYXZhL2xhbmcvcmVmbGVjdC9Db25zdHJ1Y3RvcjsAGUxqYXZhL2xhbmcvcmVmbGVjdC9GaWVsZDsAGkxqYXZhL2xhbmcvcmVmbGVjdC9NZXRob2Q7ABxMamF2YS9sYW5nL3JlZmxlY3QvTW9kaWZpZXI7ABBMamF2YS91dGlsL1VVSUQ7AA5TRVNTSU9OPWVycm9yOgAWU0VTU0lPTj1ub3Rwcm92aXNpb25lZAAKU0VTU0lPTj1vawAEVFlQRQABVgADVkpKAAJWTAADVkxMAAVWTExMTAACVloAEldpZGV2aW5lUHJvYmUuamF2YQABWgACWkkAAltCABJbTGphdmEvbGFuZy9DbGFzczsAE1tMamF2YS9sYW5nL09iamVjdDsAE1tMamF2YS9sYW5nL1N0cmluZzsABWFsbG9jABBhbGxvY2F0ZUluc3RhbmNlABphbmRyb2lkLmFwcC5BY3Rpdml0eVRocmVhZAAXYW5kcm9pZC5hcHAuQXBwbGljYXRpb24AF2FuZHJvaWQuYXBwLkNvbnRleHRJbXBsACFhbmRyb2lkLmNvbnRlbnQuQXR0cmlidXRpb25Tb3VyY2UAJmFuZHJvaWQuY29udGVudC5BdHRyaWJ1dGlvblNvdXJjZVN0YXRlAB5hbmRyb2lkLmNvbnRlbnQuQ29udGV4dFdyYXBwZXIABmFwcGVuZAAOYXR0cmlidXRpb25UYWcADGJvb2xlYW5WYWx1ZQAMY2xvc2VTZXNzaW9uABFjb20uYW5kcm9pZC5zaGVsbAAXZGFsdmlrLnN5c3RlbS5WTVJ1bnRpbWUACGRldmljZUlkAAZleGVtcHQABWZsdXNoAAdmb3JOYW1lAANnZXQACGdldENsYXNzAAdnZXREYXRhABZnZXREZWNsYXJlZENvbnN0cnVjdG9yABBnZXREZWNsYXJlZEZpZWxkABNnZXRNYXhTZWN1cml0eUxldmVsAApnZXRNZXNzYWdlAAlnZXRNZXRob2QADGdldE1vZGlmaWVycwATZ2V0UHJvdmlzaW9uUmVxdWVzdAAKZ2V0UnVudGltZQANZ2V0U2ltcGxlTmFtZQAHZ2V0VHlwZQALaW5pdFBhY2thZ2UACGludFZhbHVlAAZpbnZva2UACGlzU3RhdGljAApsb2FkVW5zYWZlAAlsb25nVmFsdWUAEm1BdHRyaWJ1dGlvblNvdXJjZQAXbUF0dHJpYnV0aW9uU291cmNlU3RhdGUABW1CYXNlABBtQmFzZVBhY2thZ2VOYW1lABNtSW5pdGlhbEFwcGxpY2F0aW9uAAttTmV4dENhY2hlZAAObU9wUGFja2FnZU5hbWUAG21SZW5vdW5jZWRQZXJtaXNzaW9uc0NhY2hlZAAEbWFpbgAFbXlQaWQABW15VWlkAAtuZXdJbnN0YW5jZQAEbmV4dAARb2JqZWN0RmllbGRPZmZzZXQAC29wZW5TZXNzaW9uAANvdXQAC3BhY2thZ2VOYW1lAANwaWQAB3ByaW50bG4ACnB1dEJvb2xlYW4ABnB1dEludAAHcHV0TG9uZwAJcHV0T2JqZWN0AAdyZWxlYXNlABRyZW5vdW5jZWRQZXJtaXNzaW9ucwAWc0N1cnJlbnRBY3Rpdml0eVRocmVhZAADc2V0AA1zZXRBY2Nlc3NpYmxlABZzZXRIaWRkZW5BcGlFeGVtcHRpb25zAA9zdGF0aWNGaWVsZEJhc2UAEXN0YXRpY0ZpZWxkT2Zmc2V0AA9zdW4ubWlzYy5VbnNhZmUACXRoZVVuc2FmZQAIdG9TdHJpbmcABXRva2VuAAN1aWQABnVuc2FmZQAFdmFsdWUAB3ZhbHVlT2YAnAF+fkQ4eyJiYWNrZW5kIjoiZGV4IiwiY29tcGlsYXRpb24tbW9kZSI6ImRlYnVnIiwiaGFzLWNoZWNrc3VtcyI6ZmFsc2UsIm1pbi1hcGkiOjI0LCJzaGEtMSI6ImZhY2VkZjQxYmJkMjhiNTYzZDFlOWUwOWM1ZjcyZDdjNWNhNTk4ZDUiLCJ2ZXJzaW9uIjoiOC4yLjItZGV2In0AAgcBhwEcBBcAFx0XAxchAgcBhwEcBxcAFyEXHRcCFyMXIRcBAQAHAAAICYGABNANAQjIDAEI6A0BCOwOAQiUEgEJ6BIBCOAXAAEAAACTGAAAAQAAAKIYAAAAAAAAAAAAAAIAAAAAAAAACgAAANwYAAAPAAAA5BgAABAAAAAAAAAAAQAAAAAAAAABAAAAigAAAHAAAAACAAAAIAAAAJgCAAADAAAAHgAAABgDAAAEAAAABwAAAIAEAAAFAAAALgAAALgEAAAGAAAAAQAAACgGAAABIAAABwAAAEgGAAADIAAABwAAAP4OAAABEAAAEAAAAKwPAAACIAAAigAAAC4QAAAEIAAAAgAAAJMYAAAAIAAAAQAAALcYAAADEAAAAgAAANwYAAAGIAAAAQAAAOwYAAAAEAAAAQAAAAwZAAA='
JB_UPDATE_CHECK=1
JB_STATS_URL=''
JB_STATS_DEFAULT=0
JB_STATS_FORCE=''
STATS_LAST=''
STATS_NEWID=0
UP_STATE=''
UP_LATEST=''
UP_SEQ=''
UP_MIN=''
UP_URL=''
UP_NOTES=''
UP_RAW=''
RAW_HASH=''
PAY_HASH=''
DIS_HASH=''

ESC=$(printf '\033')
C_R="${ESC}[31m"; C_G="${ESC}[32m"; C_Y="${ESC}[33m"; C_B="${ESC}[36m"; C_D="${ESC}[90m"; C_0="${ESC}[0m"

SELF_PATH=''
SELF_HASH=''
LOG=''
JB_BASE=''
JB_TMP=''
JB_BACKUP=''

RP_MODE='none'
RP_BIN=''
RP_DESC='未检测'

TS='/data/adb/tricky_store'
SERVICE_D='/data/adb/service.d'

JB_LIST_P1='ev'"al"
JB_LIST_P2='base64'" -d"
JB_LIST_P3='[|][[:space:]]*sh([[:space:]]|$)'
JB_LIST_P4='cur'"l "
JB_LIST_P5='wg'"et "
JB_LIST_P6='n'"c -"

# ---------------------------------------------------------------------
# 1. 输出与日志
# ---------------------------------------------------------------------
log(){ [ -n "$LOG" ] && printf '%s\n' "$*" >>"$LOG" 2>/dev/null; return 0; }
logcmd(){ log "[CMD] $*"; }
detect_width(){
  _wsrc='detect'; _w=''
  if [ -n "${JB_WIDTH_OVERRIDE:-}" ]; then _w="$JB_WIDTH_OVERRIDE"; _wsrc='fixed'
  elif [ -n "${JB_WIDTH_ENV:-}" ]; then _w="$JB_WIDTH_ENV"; _wsrc='env'
  elif [ -n "${COLUMNS:-}" ]; then _w="$COLUMNS"
  else
    _w="$(stty size 2>/dev/null | awk '{print $2}')"
    case "$_w" in ''|*[!0-9]*) _w="$(tput cols 2>/dev/null)" ;; esac
  fi
  case "$_w" in ''|*[!0-9]*) _w=80; _wsrc='default' ;; esac
  [ "$_w" -lt 24 ] && _w=24
  [ "$_w" -gt 200 ] && _w=200
  if [ "$_wsrc" = 'default' ] && has_cmd stty; then
    stty cols 80 rows 40 2>/dev/null && _w=80
  fi
  JB_WIDTH="$_w"
}
disp_width(){
  _db="$(printf '%s' "$1" | wc -c | tr -d ' ')"
  _dc="$(printf '%s' "$1" | wc -m | tr -d ' ')"
  case "$_db" in ''|*[!0-9]*) _db=0 ;; esac
  case "$_dc" in ''|*[!0-9]*) _dc="$_db" ;; esac
  _d=$(( (_db - _dc) / 2 + _dc ))
  [ "$_d" -lt 0 ] && _d="$_db"
  printf '%s' "$_d"
}
pad_to(){
  printf '%s' "$1"
  _pn=$(( $2 - $(disp_width "$1") ))
  while [ "$_pn" -gt 0 ]; do printf ' '; _pn=$((_pn - 1)); done
}
pln(){ printf '%s\n' "$1"; }
print_entry(){ # $1 序号  $2 完整标签（不截断）  $3 行号参考
  _pe_body="$(printf '%3s) %s' "$1" "$2")"
  case "$3" in
    ''|'-') printf '%s\n' "$_pe_body"; return 0 ;;
  esac
  _pe_lw="$(disp_width "$3")"
  if [ "$(disp_width "$_pe_body")" -le $(( JB_WIDTH - _pe_lw - 2 )) ]; then
    if [ $(( JB_WIDTH - _pe_lw )) -ge 58 ]; then
      pad_to "$_pe_body" $(( JB_WIDTH - _pe_lw )); printf '%s\n' "$3"
    else
      printf '%s  %s\n' "$_pe_body" "$3"
    fi
  else
    printf '%s\n' "$_pe_body"
    printf '      %s\n' "$3"
  fi
}
hr(){ _hi=2; while [ "$_hi" -lt "$JB_WIDTH" ]; do printf '-'; _hi=$((_hi + 1)); done; printf '\n'; }
tt(){ printf '\n%s%s%s\n' "$C_B" "$1" "$C_0"; }
msg(){ # $1 标签  $2 文本（按标点安全折行：不切断多字节字符）
  _mg_rest="$2"; _mg_first=1; _mg_i=0
  while [ -n "$_mg_rest" ] && [ "$_mg_i" -lt 12 ]; do
    if [ "$_mg_first" = 1 ]; then _mg_pad=8; else _mg_pad=12; fi
    _mg_avail=$(( JB_WIDTH - _mg_pad - 10 ))
    [ "$_mg_avail" -lt 12 ] && _mg_avail=12
    _mg_more=0
    if [ "$(disp_width "$_mg_rest")" -le "$_mg_avail" ]; then
      _mg_chunk="$_mg_rest"
    else
      _mg_win="$(printf '%s' "$_mg_rest" | head -c $(( _mg_avail * 3 + 2 )))"
      _mg_chunk=''
      for _mg_sep in '｜' '，' '。' '；' '、' '：' '）' '/' ' '; do
        case "$_mg_win" in
          *"$_mg_sep"*) _mg_try="${_mg_win%%"$_mg_sep"*}" ;;
          *) continue ;;
        esac
        [ "$(disp_width "$_mg_try")" -ge 6 ] || continue
        if [ -z "$_mg_chunk" ] || [ "$(disp_width "$_mg_try")" -gt "$(disp_width "$_mg_chunk")" ]; then
          _mg_chunk="${_mg_try%$_mg_sep}${_mg_sep}"
        fi
      done
      if [ -z "$_mg_chunk" ]; then
        _mg_chunk="$_mg_rest"
      else
        _mg_more=1
      fi
    fi
    if [ "$_mg_first" = 1 ]; then
      printf '%*s%s%s\n' "$_mg_pad" '' "$1" "$_mg_chunk"; _mg_first=0
    else
      printf '%*s%s\n' "$_mg_pad" '' "$_mg_chunk"
    fi
    [ "$_mg_more" = 1 ] || break
    _mg_rest="${_mg_rest#"$_mg_chunk"}"
    _mg_i=$((_mg_i + 1))
  done
}
ok(){ msg '[成功] ' "$1"; }
ng(){ msg '[失败] ' "$1"; }
info(){ msg '[信息] ' "$1"; }
warn(){ msg '[注意] ' "$1"; }
yt(){ printf '\n  %s%s%s\n' "$C_B" "$1" "$C_0"; }

clear_screen(){ [ "$JB_CLEAR" = 1 ] && printf '\033[2J\033[H'; return 0; }

pause(){
  [ "$JB_FAST" = 1 ] && return 0
  [ -t 0 ] || return 0
  printf '\n  %s-- 按回车继续 --%s' "$C_D" "$C_0"
  read -r _JB_X 2>/dev/null || true
  printf '\n'
  return 0
}
step_pause(){
  [ "$JB_STEP_PAUSE" = 1 ] || return 0
  pause
}

# run 命令 参数...
run(){
  logcmd "$@"
  if [ "$DRY_RUN" = 1 ]; then info "[演练模式] 跳过实际执行：$*"; return 0; fi
  JB_OUT="$JB_TMP/out.$$"
  "$@" >"$JB_OUT" 2>&1
  _rc=$?
  if [ -s "$JB_OUT" ]; then cat "$JB_OUT"; cat "$JB_OUT" >>"$LOG" 2>/dev/null; fi
  if [ "$_rc" = 0 ]; then ok "已执行：$1"; else ng "执行失败(rc=$_rc)：$1"; fi
  step_pause
  return "$_rc"
}

confirm_exact(){ # $1 提示 $2 需原样输入的词
  pln "  $1"
  pln "  确认请输入：$2"
  printf '  > '
  read -r _JB_A 2>/dev/null || return 1
  [ "$_JB_A" = "$2" ]
}
ask_yn(){
  pln "  $1"
  printf '  [y/N] '
  read -r _JB_A 2>/dev/null || return 1
  case "$_JB_A" in y|Y|yes|YES) return 0;; *) return 1;; esac
}
read_line(){ # $1 提示 $2 默认值 -> 结果写入 JB_ANSWER
  pln "  $1"
  printf '  > '
  read -r JB_ANSWER 2>/dev/null || JB_ANSWER=''
  [ -z "$JB_ANSWER" ] && JB_ANSWER="$2"
  return 0
}

TASK_STEP=0
begin_task(){ # $1 任务名 $2 检测词条 $3 正文行号 $4 风险 $5 是否需重启
  TASK_STEP=0
  printf '\n'
  hr
  printf '  %s任务%s %s\n' "$C_B" "$C_0" "$1"
  [ -n "$2" ] && printf '  对应检测项：%s（正文 L%s）\n' "$2" "$3"
  [ -n "$4" ] && printf '  风险等级：%s    重启需求：%s\n' "$4" "$5"
  hr
  log "== 任务开始：$1 | 检测项：$2 (L$3) | 风险：$4 | 重启：$5"
}
step(){
  TASK_STEP=$((TASK_STEP + 1))
  printf '\n  %s[步骤 %02d]%s %s\n' "$C_B" "$TASK_STEP" "$C_0" "$1"
}
done_task(){
  printf '\n'
  msg '>>> 任务结束：' "$1"
  log "== 任务结束：$1"
  pause
}

# ---------------------------------------------------------------------
# 2. 平台能力探测
# ---------------------------------------------------------------------
has_cmd(){ command -v "$1" >/dev/null 2>&1; }

sha256_pipe(){
  if has_cmd sha256sum; then sha256sum | awk '{print $1}'
  elif has_cmd toybox; then toybox sha256sum | awk '{print $1}'
  elif has_cmd busybox; then busybox sha256sum | awk '{print $1}'
  elif has_cmd openssl; then openssl dgst -sha256 | awk '{print $NF}'
  else return 1; fi
}
sha256_file(){ sha256_pipe <"$1"; }
verify_sha(){ # $1 file  $2 expected sha256
  _h="$(sha256_file "$1" 2>/dev/null)"
  if [ "$_h" = "$2" ]; then ok "SHA-256 校验通过：$_h"; return 0; fi
  ng "SHA-256 不一致 —— 期望 $2 / 实际 $_h"
  return 1
}
hash_tool_name(){
  if has_cmd sha256sum; then printf 'sha256sum'
  elif has_cmd toybox; then printf 'toybox sha256sum'
  elif has_cmd busybox; then printf 'busybox sha256sum'
  elif has_cmd openssl; then printf 'openssl dgst -sha256'
  else printf '无'; fi
}
self_hash(){ sed "s/^SELF_SHA256=.*/SELF_SHA256=''/" "$SELF_PATH" 2>/dev/null | sha256_pipe; }
raw_hash(){ sha256_file "$SELF_PATH"; }
payload_stream(){ # 打印内嵌 Inode-Hijacker 正文（不含起止行）
  _ph_a='__JB_INODE_HIJACKER_'; _ph_b='V2_3_1__'; _ph_d="$_ph_a$_ph_b"
  awk -v d="$_ph_d" 'index($0,"<<\047" d "\047")>0 { if(!s){s=1;next} } s && $0==d {exit} s' "$SELF_PATH"
}
payload_hash(){ payload_stream | sha256_pipe; }
payload_upstream_hash(){ # 去掉许可头后应等于上游官方 v2.3.1 原文
  { payload_stream | sed -n '1p'; payload_stream | sed "1,${JB_INODE_LICENSE_LAST_LINE}d"; } | sha256_pipe
}
hash_all(){ RAW_HASH="$(raw_hash)"; SELF_HASH="$(self_hash)"; PAY_HASH="$(payload_hash)"; DIS_HASH="$(dispatch_hash)"; }
dispatch_hash(){
  awk '/^run_item\(\)\{/{f=1} f{print} f&&/^\}$/{exit}' "$SELF_PATH" | sha256_pipe
}

detect_resetprop(){
  RP_MODE='none'; RP_BIN=''; RP_DESC='不可用'
  if [ -x /data/adb/magisk/resetprop ]; then
    RP_MODE='binary'; RP_BIN='/data/adb/magisk/resetprop'; RP_DESC='Magisk resetprop'
  elif has_cmd resetprop; then
    RP_MODE='binary'; RP_BIN="$(command -v resetprop)"; RP_DESC='resetprop (PATH)'
  elif [ -x /data/adb/ksud ]; then
    RP_MODE='ksud'; RP_DESC='ksud resetprop'
  fi
}

rp(){ # resetprop 统一入口（失败时自动回退重试，兼容 Magisk / KSU 的 CLI 差异）
  case "$RP_MODE" in
    binary) run "$RP_BIN" "$@" && return 0 ;;
    ksud)   run /data/adb/ksud resetprop "$@" && return 0 ;;
    *)      ng 'resetprop / ksud 均不可用：无法修改只读属性（ro.*）'; return 127 ;;
  esac
  case "$1" in
    -n|-N|-p|-P) warn "带 $1 执行失败，去掉该选项重试"; shift ;;
    --delete)    warn '--delete 失败，改用 -d 重试'; shift; set -- -d "$@" ;;
    *)           warn '写入失败；若是删除属性，可改用 setprop <名称> "" 后重启复测'; return 1 ;;
  esac
  case "$RP_MODE" in
    binary) run "$RP_BIN" "$@" ;;
    ksud)   run /data/adb/ksud resetprop "$@" ;;
  esac
}

root_manager(){
  if [ -d /data/adb/magisk ] || has_cmd magisk; then printf 'Magisk'
  elif [ -f /data/adb/ksud ] || [ -d /data/adb/ksu ]; then printf 'KernelSU'
  elif [ -f /data/adb/apd ] || [ -d /data/adb/ap ]; then printf 'APatch / FolkPatch'
  elif [ -d /data/adb/modules ]; then printf '未知（存在 /data/adb/modules）'
  else printf '未知 / 无'; fi
}

# 网络能力模块：本段被注入扫描显式放行（仅此处允许出现下载工具名）
#@@NET-ALLOW-BEGIN
net_tool_name(){
  if has_cmd curl; then printf 'curl'
  elif has_cmd wget; then printf 'wget'
  elif has_cmd toybox; then printf 'toybox wget'
  else printf '无'; fi
}
stats_get(){ # $1 url -> stdout（一次性 GET，仅供匿名统计）
  if has_cmd curl; then curl -fsS --connect-timeout 4 --max-time 8 "$1" 2>/dev/null; return $?
  elif has_cmd wget; then wget -q -O - -T 6 "$1" 2>/dev/null; return $?
  elif has_cmd toybox; then toybox wget -q -O - "$1" 2>/dev/null; return $?
  else return 127; fi
}
fetch_url_quick(){ # $1 url $2 out（短超时，供版本检测用）
  if has_cmd curl; then curl -fsSL --connect-timeout 4 --max-time 10 "$1" -o "$2"; return $?
  elif has_cmd wget; then wget -q -T 6 -O "$2" "$1"; return $?
  elif has_cmd toybox; then toybox wget -O "$2" "$1" >/dev/null 2>&1; return $?
  else return 127; fi
}
fetch_url(){ # $1 url $2 out
  if has_cmd curl; then curl -fsSL --connect-timeout 8 --max-time 30 "$1" -o "$2"; return $?
  elif has_cmd wget; then wget -q -T 10 -O "$2" "$1"; return $?
  elif has_cmd toybox; then toybox wget -O "$2" "$1" >/dev/null 2>&1; return $?
  else return 127; fi
}
gh_latest_asset(){ # $1 owner/repo  -> 打印最新 release 的第一个下载直链
  fetch_url "https://api.github.com/repos/$1/releases/latest" "$JB_TMP/gh.json" || return 1
  tr ',' '\n' <"$JB_TMP/gh.json" | grep -F 'browser_download_url' | head -n 1 \
    | sed 's/.*"browser_download_url":[ ]*"//; s/".*//'
}
#@@NET-ALLOW-END

# ---------------------------------------------------------------------
# 3. 初始化
# ---------------------------------------------------------------------
resolve_self(){
  case "$0" in
    */*) SELF_PATH="$0" ;;
    *)   SELF_PATH="$(command -v "$0" 2>/dev/null || printf '%s' "$0")" ;;
  esac
}
init_dirs(){
  [ -n "$JB_BASE" ] || JB_BASE="${JB_BASE_OVERRIDE:-/sdcard/JinBeiChunQiuFixToolPro2}"
  [ -n "$JB_TMP" ] || JB_TMP="${JB_TMP_OVERRIDE:-/data/local/tmp/.JinBeiChunQiuFixToolPro2}"
  mkdir -p "$JB_TMP" 2>/dev/null
  [ -d "$JB_TMP" ] || JB_TMP="${TMPDIR:-/tmp}/.JinBeiChunQiuFixToolPro2"
  mkdir -p "$JB_TMP" 2>/dev/null
  mkdir -p "$JB_BASE/logs" "$JB_BASE/backup" "$JB_BASE/downloads" 2>/dev/null
  [ -d "$JB_BASE/logs" ] || JB_BASE="$JB_TMP"
  mkdir -p "$JB_BASE/logs" "$JB_BASE/backup" "$JB_BASE/downloads" 2>/dev/null
  LOG="$JB_BASE/logs/fix-$(date +%Y%m%d-%H%M%S).log"
  : >"$LOG" 2>/dev/null || LOG="$JB_TMP/fix.log"
  JB_BACKUP="$JB_BASE/backup/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$JB_BACKUP" 2>/dev/null
  return 0
}
backup_path(){
  [ -e "$1" ] || { info "无需备份（不存在）：$1"; return 0; }
  _d="${JB_BACKUP}$1"
  mkdir -p "$(dirname "$_d")" 2>/dev/null
  cp -a "$1" "$_d" 2>/dev/null || cp -r "$1" "$_d" 2>/dev/null
  if [ -e "$_d" ]; then ok "已备份：$1 -> $_d"; else warn "备份失败：$1"; fi
  return 0
}

need_root(){
  if [ "$(id -u 2>/dev/null)" = 0 ]; then return 0; fi
  printf '\n  当前不是 ROOT，尝试用 su 提权重新进入...\n'
  if has_cmd su; then exec su -c "sh '$SELF_PATH' $JB_ARGS"; fi
  printf '  未找到 su。请在 MT 管理器中「以 ROOT 执行」本脚本。\n'
  exit 1
}

# ---------------------------------------------------------------------
# 4. 脚本自检（完整性 + 来源 + 注入）
# ---------------------------------------------------------------------
identity_check(){
  grep -q "JB_NAME='$JB_NAME'" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "JB_AUTHOR='$JB_AUTHOR'" "$SELF_PATH" 2>/dev/null || return 1
  grep -q "JB_VER='$JB_VER'" "$SELF_PATH" 2>/dev/null || return 1
  return 0
}
injection_scan(){
  _jb_bm='#@@NET-ALLOW-'"BEGIN"
  _jb_em='#@@NET-ALLOW-'"END"
  _jb_pat="($JB_LIST_P1|$JB_LIST_P2|$JB_LIST_P3|$JB_LIST_P4|$JB_LIST_P5|$JB_LIST_P6)"
  _jb_pb='#@@PAYLOAD-ALLOW-'"BEGIN"
  _jb_pe='#@@PAYLOAD-ALLOW-'"END"
  awk -v bm="$_jb_bm" -v em="$_jb_em" -v pb="$_jb_pb" -v pe="$_jb_pe" -v pat="$_jb_pat" \
    '$0 ~ bm || $0 ~ pb {s=1;next} $0 ~ em || $0 ~ pe {s=0;next} !s && $0 !~ /^[[:space:]]*#/ && $0 ~ pat {print NR ": " $0}' \
    "$SELF_PATH" 2>/dev/null | head -n 20
}
self_check_local(){
  tt '脚本完整性自检（防误改 / 防传输损坏）'
  info '说明：内嵌摘要与校验代码都在同一份文件里，改脚本的人可以一并改掉——'
  info '它挡得住手滑误改、传输损坏、忘了重签的二次打包，挡不住有决心的篡改者。'
  info '要真正可信，请用 --verify <发布页摘要> 或 --verify-remote，摘要从独立渠道获取。'
  if [ ! -f "$SELF_PATH" ]; then ng '脚本文件不可读，无法自检'; return 2; fi
  hash_all
  _raw="$RAW_HASH"; _norm="$SELF_HASH"; _pay="$PAY_HASH"; _dis="$DIS_HASH"
  printf '        原始文件 SHA-256：\n          %s\n' "$_raw"
  pln '        （这一行请与发布页/仓库公布的原始文件摘要逐一比对）'
  if identity_check; then ok '身份标记完整（名称 / 作者 / 版本）'; else ng '身份标记缺失或与官方版本不符'; fi
  _bad=0
  if [ -z "$SELF_SHA256" ]; then ng '内嵌总哈希为空（开发副本）'; _bad=1
  elif [ "$_norm" = "$SELF_SHA256" ]; then ok '总哈希一致（全文件，忽略本哈希行）'
  else ng "总哈希不一致：期望 $SELF_SHA256 / 实际 $_norm"; _bad=1; fi
  if [ -z "$JB_DISPATCH_SHA" ]; then warn '未写入分发区哈希（开发副本）'; _bad=1
  elif [ "$_dis" = "$JB_DISPATCH_SHA" ]; then ok '分发区哈希一致（菜单序号 -> 动作映射未被改动）'
  else ng "分发区哈希不一致：期望 $JB_DISPATCH_SHA / 实际 $_dis"; _bad=1; fi
  if [ -z "$JB_INODE_SHA" ]; then warn '未写入内置载荷哈希'; _bad=1
  elif [ "$_pay" = "$JB_INODE_SHA" ]; then ok "内置载荷哈希一致（$JB_INODE_VER）"
  else ng "内置载荷哈希不一致：期望 $JB_INODE_SHA / 实际 $_pay"; _bad=1; fi
  _hit="$(injection_scan)"
  if [ -n "$_hit" ]; then
    ng '注入特征扫描发现可疑构造：'
    printf '%s\n' "$_hit"
    _bad=1
  else
    ok '注入特征扫描通过（未发现远程执行 / 解码执行类构造）'
  fi
  if third_party_notice_check; then
    ok '第三方许可声明完整（项目 / 作者 / 仓库 / MIT 全文随副本保留）'
  else
    ng '第三方许可声明缺失或不完整（MIT 要求随副本保留）：请从官方渠道重新获取'; _bad=1
  fi
  if [ -n "$JB_INODE_UPSTREAM_SHA" ]; then
    if [ "$(payload_upstream_hash)" = "$JB_INODE_UPSTREAM_SHA" ]; then
      ok "内嵌副本 = 上游官方 v2.3.1 原文 + 许可头（去掉许可头后逐字节一致）"
    else
      warn '去掉许可头后与上游官方摘要不一致：内嵌副本可能被改动过'
    fi
  fi
  [ "$_bad" = 0 ] && source_provenance_hint
  [ "$_bad" = 0 ] || return 1
  return 0
}
self_check_online(){
  tt '来源在线校验'
  if [ -z "${JB_OFFICIAL_HASH_URL:-}" ]; then
    info '未配置官方校验地址（JB_OFFICIAL_HASH_URL 为空）：跳过在线校验'
    info "官方项目：$JB_PROJECT_URL"
    return 0
  fi
  if [ "$(net_tool_name)" = '无' ]; then warn '设备无下载工具（缺少下载器）：跳过'; return 0; fi
  info '正在获取官方校验清单（摘要）…'
  if fetch_url "$JB_OFFICIAL_HASH_URL" "$JB_TMP/official.txt"; then
    _m="$JB_TMP/official.txt"
    _bare="$(tr -d ' \t\r\n' <"$_m" | head -c 64)"
    _raw="$(sed -n 's/^[[:space:]]*raw_sha256[[:space:]]*=[[:space:]]*//p' "$_m" 2>/dev/null | head -1 | tr -d ' \r')"
    _selfm="$(sed -n 's/^[[:space:]]*self_sha256[[:space:]]*=[[:space:]]*//p' "$_m" 2>/dev/null | head -1 | tr -d ' \r')"
    hash_all
    _want="$SELF_HASH"; _got="$_bare"
    if [ -n "$_raw" ]; then _want="$RAW_HASH"; _got="$_raw"
    elif [ -n "$_selfm" ]; then _want="$SELF_HASH"; _got="$_selfm"; fi
    printf '        官方哈希：%s\n' "$_got"
    if [ "$_got" = "$_want" ]; then ok '在线来源校验通过：与官方发布哈希一致'
    else ng '在线来源校验不通过：哈希不一致，请勿使用本副本'; return 1; fi
  else
    warn '联网失败或地址不可用：跳过在线校验（不影响本地校验结论）'
  fi
  return 0
}
self_check(){
  [ -n "${JB_VERIFY_EXPECT:-}" ] && verify_expected
  [ "${JB_VERIFY_REMOTE:-0}" = 1 ] && verify_remote
  if ! self_check_local; then
    printf '\n'
    ng '自检未通过：本副本与官方发布版本不一致，或缺少校验信息。'
    pln '  请从官方渠道重新获取，并用独立工具核对原始文件 SHA-256：'
    pln '    电脑/终端： sha256sum JinBeiChunQiuFixToolPro2.sh'
    if [ "$JB_ALLOW_UNVERIFIED" = 1 ]; then
      warn '已按 --allow-unverified 继续执行（风险自负）。'
    else
      pln '  确要继续（例如这是你自己改过的副本）：加 --allow-unverified 重新运行。'
      exit 1
    fi
  fi
  self_check_online
  return 0
}
verify_expected(){
  hash_all
  tt '外部摘要校验（--verify）'
  _want="$(printf '%s' "$JB_VERIFY_EXPECT" | tr 'A-Z' 'a-z' | tr -d ' \r\n')"
  pln "  期望摘要：$_want"
  pln "  原始文件：$RAW_HASH"
  pln "  总哈希  ：$SELF_HASH"
  if [ "$_want" = "$RAW_HASH" ] || [ "$_want" = "$SELF_HASH" ]; then
    ok '外部摘要一致：文件与你在独立渠道看到的摘要相同'
  else
    ng '外部摘要不一致：不要运行这个副本！'
    exit 1
  fi
}
verify_remote(){
  hash_all
  tt '在线摘要校验（--verify-remote）'
  _url="${JB_VERIFY_REMOTE_URL:-$JB_OFFICIAL_HASH_URL}"
  if [ -z "$_url" ]; then
    warn '未提供校验地址（JB_OFFICIAL_HASH_URL 或 --verify-remote <url>）'
    [ "${JB_STRICT:-0}" = 1 ] && { ng '严格模式：无法校验，拒绝执行'; exit 1; }
    return 0
  fi
  if [ "$(net_tool_name)" = '无' ]; then
    warn '设备无下载工具，无法在线校验'
    [ "${JB_STRICT:-0}" = 1 ] && { ng '严格模式：无法校验，拒绝执行'; exit 1; }
    return 0
  fi
  pln "  校验地址：$_url"
  if ! fetch_url "$_url" "$JB_TMP/remote.manifest"; then
    warn '联网失败，无法完成在线校验'
    [ "${JB_STRICT:-0}" = 1 ] && { ng '严格模式：无法校验，拒绝执行'; exit 1; }
    return 0
  fi
  _mf="$JB_TMP/remote.manifest.lc"
  tr 'A-Z' 'a-z' <"$JB_TMP/remote.manifest" >"$_mf" 2>/dev/null
  _mf_get(){ sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$_mf" 2>/dev/null | head -n 1 | tr -d ' \r'; }
  _m_tool="$(_mf_get tool)"; _m_ver="$(_mf_get version)"; _m_seq="$(_mf_get release_seq)"
  _m_raw="$(_mf_get raw_sha256)"; _m_self="$(_mf_get self_sha256)"
  _m_disp="$(_mf_get dispatch_sha256)"; _m_pay="$(_mf_get payload_sha256)"
  if [ -n "$_m_tool$_m_ver$_m_seq" ]; then
    pln "  清单：tool=$_m_tool version=$_m_ver release_seq=$_m_seq"
  fi
  if [ -z "$_m_raw$_m_self$_m_disp$_m_pay" ]; then
    _m_raw="$(grep -m1 -oE '[0-9a-f]{64}' "$_mf" 2>/dev/null | tr -d ' \r')"
    _m_self=''; _m_disp=''; _m_pay=''
    warn '未发现清单字段，按纯摘要列表处理（兼容模式）'
  fi
  # 清单是对同一个文件的一次断言：凡出现的字段都必须一致，出现一个错即判不可信
  _mo=1; _provided=0
  if [ -n "$_m_raw" ];  then _provided=1; [ "$_m_raw"  = "$RAW_HASH" ]  || _mo=0; fi
  if [ -n "$_m_self" ]; then _provided=1; [ "$_m_self" = "$SELF_HASH" ] || _mo=0; fi
  if [ -n "$_m_disp" ]; then _provided=1; [ "$_m_disp" = "$DIS_HASH" ]  || _mo=0; fi
  if [ -n "$_m_pay" ];  then _provided=1; [ "$_m_pay"  = "$PAY_HASH" ]  || _mo=0; fi
  [ "$_provided" = 0 ] && _mo=0
  # min_client：低于要求时按失败处理（strict 直接拒绝）
  _m_min="$(_mf_get min_client)"
  if [ -n "$_m_min" ]; then
    _mc_num="$(printf '%s' "$_m_min" | tr -cd '0-9.')"; _my_num="$(printf '%s' "$JB_VER" | tr -cd '0-9.')"
    if [ -n "$_mc_num" ] && [ "$(printf '%s\n%s\n' "$_my_num" "$_mc_num" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1)" = "$_mc_num" ] && [ "$_my_num" != "$_mc_num" ]; then
      warn "清单要求客户端 ≥ $_m_min（当前 $JB_VER）"
      [ "${JB_STRICT:-0}" = 1 ] && { ng '严格模式：客户端版本过低，拒绝执行'; exit 1; }
    fi
  fi
  case "$_m_seq" in ''|*[!0-9]*) _m_seq='' ;; esac
  _floor=''
  [ -f "$JB_BASE/.release_seq" ] && _floor="$(cat "$JB_BASE/.release_seq" 2>/dev/null | tr -d ' \r')"
  case "$_floor" in ''|*[!0-9]*) _floor='' ;; esac
  if [ -n "$_m_seq" ] && [ -n "$_floor" ] && [ "$_m_seq" -lt "$_floor" ]; then
    ng "清单 release_seq=$_m_seq 低于本机记录 $_floor（疑似回滚/重放），判为不可信"
    _mo=0
  fi
  if [ "$_mo" = 1 ]; then
    ok '在线摘要命中：本副本与发布清单一致'
    if [ -n "$_m_seq" ]; then printf '%s\n' "$_m_seq" >"$JB_BASE/.release_seq" 2>/dev/null; fi
  else
    ng '在线摘要未命中：本副本或清单与发布内容不一致，已停止'
    pln "  本地 raw=$RAW_HASH"
    pln "  清单 raw=${_m_raw:-（无）}"
    exit 1
  fi
}

# ---------------------------------------------------------------------
# 5. 环境报告
# ---------------------------------------------------------------------
env_report(){
  detect_resetprop
  tt '环境报告'
  pln "  Android ：$(getprop ro.build.version.release 2>/dev/null) （SDK $(getprop ro.build.version.sdk 2>/dev/null)）"
  pln "  机型    ：$(getprop ro.product.brand 2>/dev/null) $(getprop ro.product.model 2>/dev/null)"
  pln "  内核    ：$(uname -r 2>/dev/null)"
  pln "  ROOT    ：uid=$(id -u 2>/dev/null) ，管理器=$(root_manager)"
  pln "  SELinux ：$(getenforce 2>/dev/null || printf '未知')"
  printf '  模块数  ：%s\n' "$(ls /data/adb/modules 2>/dev/null | wc -l | tr -d ' ')"
  printf '  resetprop：%s\n' "$RP_DESC"
  printf '  tricky_store：%s\n' "$([ -d "$TS" ] && printf '存在' || printf '不存在')"
  _sd_state="$([ -d "$SERVICE_D" ] && printf '存在' || printf '不存在')"   # 仍检测 service.d，仅不显示
  pln "  网络工具：$(net_tool_name)   哈希工具：$(hash_tool_name)"
  pln "  安全补丁：$(getprop ro.build.version.security_patch 2>/dev/null)"
  hr
  return 0
}

# ---------------------------------------------------------------------
# 6. 法律声明与同意
# ---------------------------------------------------------------------
license(){
  tt "用户须知与法律责任声明  v$JB_LICENSE_VER"
  cat <<'EOF'
  第 1 条 【用途限定】
   本工具及所依据的「春秋检测项解决方案」仅面向 Android 技术爱好者，
   用于技术学习、环境研究与技术探讨。使用者应确保自身行为符合当地
   法律法规、设备厂商条款与所在平台规则。

  第 2 条 【明确禁止】
   严禁将本工具用于绕过应用反作弊、规避风控机制、游戏作弊、侵害他人
   系统与数据、规避付费或版权保护等任何违法违规场景。因违规使用产生
   的一切后果与责任，由使用者自行承担，作者不承担任何责任。

  第 3 条 【风险自担】
   本工具会执行：修改文件属主/权限、删除文件与目录、重置系统属性、
   改写 tricky_store 配置、向 /data/adb/service.d 部署开机脚本等操作。
   上述操作可能导致设备异常、无限重启、数据丢失或系统不可用。所有
   操作风险由使用者本人承担，作者对设备损坏及数据丢失概不负责。

  第 4 条 【不可逆与备份】
   删除类操作通常不可逆；属性修改在重启后可能失效或被重新写入。
   本工具在执行改动前会尽力备份到 /sdcard/JinBeiChunQiuFixToolPro2/
   backup/，但不保证覆盖全部场景，请自行另行备份重要数据。

  第 5 条 【无担保】
   本工具「按现状」提供，不保证能通过任何检测项，也不保证适用于你的
   机型、ROM 版本、内核与 Root 管理器组合。文档与社区结论存在误报与
   概率命中现象，检测结果仅作调试参考，不作为绝对判定依据。

  第 6 条 【第三方资源】
   本工具的「在线校验来源 / 下载官方修复脚本 / 获取第三方工具」会访问
   GitHub 等公开地址，下载的脚本
   仅保存到本地、不会自动执行；第三方资源的安全性由使用者自行甄别，
   作者不对其内容与后果负责。

  第 7 条 【隐私与网络】
   除你在上述联网工具项中主动发起外，本工具不主动发起网络请求。
   匿名使用统计是可选、默认关闭的，详见第 8 条。
   运行日志仅保存在本机 /sdcard/JinBeiChunQiuFixToolPro2/logs/。

  第 8 条 【匿名使用统计（可选，默认关闭）】
   为估算使用人数，本工具提供可选的匿名统计：开启后每次运行会向指定的
   统计端点发送一个随机安装 ID、脚本版本、事件类型（run/install）与本机
   运行次数；不发送设备型号、系统版本、IMEI、账号、位置或任何文件内容。
   该功能默认关闭，首次运行会询问，也可用 56) 工具（使用统计与隐私）
   或 --stats-on / --stats-off 随时开关；关闭后不发起任何统计请求。
   服务端仍会像普通网站一样记录来源 IP（建议仅用于去重并短期保留）。

  第 9 条 【第三方代码与新增高危能力】
   本工具内置 Inode-Hijacker v2.3.1（MIT License，作者 YiJieqwq，
   仓库 https://github.com/YiJieqwq/Inode-Hijacker ）。按该许可要求，
   内嵌副本自身保留 Copyright (c) 2026 YiJieqwq 与 MIT 许可全文，并在
   每次运行前校验 SHA-256；菜单「致谢与开源许可」可查看全文，--license
   可直接打印，启动时也会随附 <输出目录>/THIRD-PARTY-NOTICES.txt。
   转发、转载或二次打包时请勿删除上述声明。另提供模块临时隔离（移出
   /data/adb/modules）、/apex 内 su 执行位修改、PID 回绕 + Zygote 重启、
   按检测结果删除路径等高风险能力，均需输入确认口令，风险自负。
   另：本工具大量实现改编自「春秋检测项解决方案」
   （https://github.com/mingzun09/Chunqiu-Detector-Problem-solution ，
   MIT License，Copyright (c) 2026 Su xiaoming）：File/shamiko_Plus.sh、
   File/Found property.sh、File/Tampered Attestation Key(26)Pass.sh，
   以及 language/answer_zh.md 的正文命令、附录 B/C 清单与词条标题、
   行号参考。该声明同样随副本保留，请勿删除。

  第 10 条 【完整性校验的边界】
   本脚本内置的摘要与校验代码位于同一文件内，只能发现误改、传输损坏与
   忘记重签的二次打包，不能防御有决心的篡改（对方可一并修改摘要或删除
   校验）。请自行通过独立渠道核对原始文件摘要后再运行；作者对经第三方
   修改过的副本不承担任何责任。

  第 11 条 【同意方式】
   输入「同意」即表示你已完整阅读、理解并接受以上全部条款；输入其它
   内容视为不同意，本工具将直接退出。
EOF
  printf '\n'
  if [ "$JB_ACCEPT" = 1 ]; then
    printf '  （已通过 --accept-license 跳过交互确认）\n'
    return 0
  fi
  printf '  请输入 %s同意%s 以继续：' "$C_Y" "$C_0"
  read -r _jb_a 2>/dev/null || _jb_a=''
  case "$_jb_a" in
    同意|agree|AGREE|"I AGREE"|"i agree")
      printf '\n  %s已记录你的同意，开始进入修复菜单。%s\n' "$C_G" "$C_0"
      log "== 用户已同意法律声明 v$JB_LICENSE_VER"
      pause
      return 0 ;;
    *)
      printf '\n  %s未同意，拒绝继续。%s\n' "$C_R" "$C_0"
      exit 1 ;;
  esac
}

# ---------------------------------------------------------------------
# 7. 修复项：属性 / 系统状态
# ---------------------------------------------------------------------
f_found_property(){
  begin_task '清理 logd 缓冲区属性' 'Found property' '1089' '低' '否'
  step '读取当前值'
  for p in persist.logd.size persist.logd.size.crash persist.logd.size.system persist.logd.size.main; do
    printf '        %s = [%s]\n' "$p" "$(getprop "$p" 2>/dev/null)"
  done
  step '写入空值（检测判据为「非空即命中」）'
  for p in persist.logd.size persist.logd.size.crash persist.logd.size.system persist.logd.size.main; do
    run setprop "$p" ''
  done
  step '回读校验'
  for p in persist.logd.size persist.logd.size.crash persist.logd.size.system persist.logd.size.main; do
    printf '        %s = [%s]\n' "$p" "$(getprop "$p" 2>/dev/null)"
  done
  done_task '已清空 4 个 logd 属性；重启后仍为空才算稳定生效。'
}

f_avb(){
  begin_task '修正 avb 版本属性' 'avb校验异常 avb=2.0' '1106' '低' '是'
  step '读取 ro.boot.avb_version'
  run getprop ro.boot.avb_version
  step '写入 1.3（resetprop，不落盘）'
  rp -n ro.boot.avb_version 1.3
  step '回读'
  run getprop ro.boot.avb_version
  done_task '若重启后恢复原值，说明由模块在开机阶段写入，需自行排查改机型类模块。'
}

f_lockstate(){
  begin_task '修正回锁状态属性' '密钥篡改 / 证书链篡改(x)' '566' '低' '否'
  step '读取当前值'
  run getprop ro.secureboot.lockstate
  step '写入 locked（Magisk 用 resetprop；KSU 用 ksud resetprop）'
  rp ro.secureboot.lockstate locked
  step '回读'
  run getprop ro.secureboot.lockstate
  done_task '本条只解决「证书链篡改(x)」分支；「密钥篡改」分支需更换/更新密钥模块。'
}

f_lock_props(){
  _en="${ENTRY_NAME:-Bootloader unlock / 解锁属性}"; _el="${ENTRY_LINE:-534}"; ENTRY_NAME=''; ENTRY_LINE=''
  begin_task '写入回锁 / 启动状态类关键属性' "$_en" "$_el" '中' '是'
  warn '这些属性由真解锁设备本身决定，硬改只影响读取层，可能与密钥模块冲突。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认写入以下属性吗？' '写入' || { printf '  已取消。\n'; return 0; }
  fi
  step 'ro.boot.vbmeta.device_state = locked'
  rp -n ro.boot.vbmeta.device_state locked
  step 'ro.boot.verifiedbootstate = green'
  rp -n ro.boot.verifiedbootstate green
  step 'ro.boot.flash.locked = 1'
  rp -n ro.boot.flash.locked 1
  step '回读'
  for p in ro.boot.vbmeta.device_state ro.boot.verifiedbootstate ro.boot.flash.locked; do
    printf '        %s = [%s]\n' "$p" "$(getprop "$p" 2>/dev/null)"
  done
  info '完整属性隐藏请用「修复（Property Modified）」部署 service.d 脚本，开机早期写入更稳。'
  done_task '完成。'
}

f_vold(){
  begin_task '删除 Vold 隔离开关属性' 'Vold隔离已开启' '1253' '低' '是'
  step '读取当前值'
  run getprop persist.sys.vold_app_data_isolation_enabled
  step '删除该属性（resetprop -p --delete）'
  rp -p --delete persist.sys.vold_app_data_isolation_enabled
  step '回读（应为空）'
  run getprop persist.sys.vold_app_data_isolation_enabled
  warn '同时请在 HMA / 应用隐藏模块里关闭「Vold app data 隔离」，否则会被重新写入。'
  done_task '删除后需重启才稳定；注意本项与 Miscellaneous Check(3) 互相牵制。'
}

f_usb_off(){
  begin_task '关闭 USB 调试' 'USB 调试已开启' '1042' '低' '否'
  step '读取当前值'
  run settings get global adb_enabled
  step '写入 0'
  run settings put global adb_enabled 0
  step '回读'
  run settings get global adb_enabled
  step '可选：写入开机自动关闭脚本'
  if [ "$JB_ASSUME_YES" = 1 ]; then
    write_usb_off_script
  elif ask_yn '同时写入 /data/adb/service.d 开机自动关闭脚本？'; then
    write_usb_off_script
  else
    info '已跳过；本条可随时重选本项再部署'
  fi
  done_task '完成。'
}

f_prop_scan(){
  begin_task '属性伪装残留扫描' '环境伪造' '1214' '只读' '否'
  step '扫描 pihooks / pixelprops / spoof 残留'
  run sh -c 'getprop | grep -iE "pihooks|pixelprops|spoof" || echo "(无匹配)"'
  step '提示'
  info '若命中，定位到对应属性伪装模块后关闭/卸载；或选「修复（Property Modified）」部署开机脚本改写。'
  done_task '本项仅诊断，不修改任何内容。'
}

# ---------------------------------------------------------------------
# 8. 修复项：/data/local/tmp 与挂载
# ---------------------------------------------------------------------
f_tmp_show(){
  begin_task '查看 /data/local/tmp 当前状态' 'Suspicious Surroundings (a)(b)(c)' '866 / 879 / 896' '只读' '否'
  step '目录信息（含 SELinux context）'
  run ls -ldZ /data/local/tmp
  run stat /data/local/tmp
  step '调试意图'
  info '判据：属主/属组应为 shell:shell；权限应为 771；inode 不宜过大（阈值约 10000）。'
  done_task '查看完成。'
}

f_widevine_check(){
  begin_task '检测无效的伪造信息(1) · Widevine' '无效的伪造信息(1)' '1058' '只读' '否'
  step '解码并写入探针（dex）'
  _wv_dex=/data/local/tmp/.jb_wvprobe.dex
  #@@NET-ALLOW-BEGIN
  if has_cmd base64; then
    printf '%s' "$JB_WV_DEX_B64" | base64 -d >"$_wv_dex" 2>/dev/null
  elif has_cmd openssl; then
    printf '%s' "$JB_WV_DEX_B64" | openssl base64 -d >"$_wv_dex" 2>/dev/null
  else
    ng '缺少 base64 / openssl，无法解码探针'; done_task '无法执行探针'; return 1
  fi
  #@@NET-ALLOW-END
  if [ ! -s "$_wv_dex" ]; then ng '探针写入失败'; done_task '无法执行探针'; return 1; fi
  step '无界面运行 MediaDrm 探针（app_process，不弹任何窗口）'
  _wv_bin='app_process'
  has_cmd app_process || _wv_bin='/system/bin/app_process'
  [ -x "$_wv_bin" ] || _wv_bin='/system/bin/app_process64'
  _wv_out="$(CLASSPATH="$_wv_dex" "$_wv_bin" /system/bin com.xiafa.WidevineProbe 2>&1)"
  rm -f "$_wv_dex"
  [ -n "$_wv_out" ] && printf '%s\n' "$_wv_out" | sed 's/^/        /'
  log "== widevine probe: $_wv_out"
  _wv_lvl="$(printf '%s\n' "$_wv_out" | sed -n 's/^LEVEL=//p' | head -1)"
  _wv_sess="$(printf '%s\n' "$_wv_out" | sed -n 's/^SESSION=//p' | head -1)"
  _wv_dlen="$(printf '%s\n' "$_wv_out" | sed -n 's/^DATA_LEN=//p' | head -1)"
  step '解析结果（判据：L1 + openSession 抛 NotProvisioned + 开通请求长度为 0）'
  if [ -z "$_wv_lvl" ]; then
    warn '探针未返回有效安全级别（app_process / MediaDrm 不可用）。'
    info '本条为摘要型检测项；可在「开发者选项 → 强制进行软件安全加密」开启后重启复测。'
    done_task '无法判定：探针不可用'; return 2
  fi
  case "$_wv_lvl" in
    0|1|2)
      info "Widevine 安全级别=$_wv_lvl（软件 / L3 档）；按文档「L3 时本条直接略过」。"
      done_task '未命中（设备为 L3，本条略过）'; return 0 ;;
  esac
  case "$_wv_sess" in
    ok)
      info "Widevine=$_wv_lvl（L1），openSession 正常。"
      done_task '未命中（L1 正常，无「无效的伪造信息」）'; return 0 ;;
    notprovisioned)
      ng "命中：L1 + NotProvisioned（DATA_LEN=${_wv_dlen:-?}）。"
      warn '处理：进入「开发者选项 → 强制进行软件安全加密」开启后重启复测（系统自带开关，可随时关闭）。'
      info '提示：本条属摘要型条目，部分机型 / 未解锁设备会误报；可先按上述开关验证，或播放必需 L1 的 HD 内容判断 L1 是否真实可用。'
      done_task '命中（无效的伪造信息(1)）'; return 0 ;;
    *)
      warn "探针未取得会话状态（SESSION=${_wv_sess:-未知}）。"
      done_task '无法判定'; return 2 ;;
  esac
}

f_tmp_owner(){
  begin_task '修回 /data/local/tmp 属主/属组' 'Suspicious Surroundings (a)' '866' '低' '否'
  step '修改前'
  run ls -ld /data/local/tmp
  step 'chown shell:shell'
  run chown shell:shell /data/local/tmp
  step '修改后'
  run ls -ld /data/local/tmp
  done_task '完成。'
}

f_tmp_perm(){
  begin_task '修回 /data/local/tmp 权限' 'Suspicious Surroundings (c)' '896' '低' '否'
  step '修改前'
  run ls -ld /data/local/tmp
  step 'chmod 771'
  run chmod 771 /data/local/tmp
  step '修改后'
  run ls -ld /data/local/tmp
  done_task '完成。'
}

f_tmp_full(){
  begin_task '一键修复属主 + 权限 + 上下文' 'Suspicious Surroundings (a)(c)' '866 / 896' '低' '否'
  step 'chown shell:shell / chmod 771'
  run chown shell:shell /data/local/tmp
  run chmod 771 /data/local/tmp
  step 'restorecon 恢复 SELinux 上下文'
  run restorecon -RF /data/local/tmp
  step '结果'
  run ls -ldZ /data/local/tmp
  done_task '完成。'
}

f_tmp_restorecon(){
  begin_task '恢复 /data/local/tmp 的 SELinux 上下文' 'Suspicious Surroundings（b）善后' '879' '低' '否'
  step 'restorecon -RF'
  run restorecon -RF /data/local/tmp
  done_task '若使用 Inode-Hijacker 后出现 Scrcpy 等有线投屏不可用，执行本项即可恢复。'
}

f_tmp_rebuild(){
  _en="${ENTRY_NAME:-/data/local/tmp 元数据异常族（Futile hide / 1 / 2 / 04 / 2222）}"; _el="${ENTRY_LINE:-703}"
  ENTRY_NAME=''; ENTRY_LINE=''
  begin_task '重建 /data/local/tmp（重置 inode / 修复拒绝访问）' "$_en" "$_el" '高' '是'
  warn '将删除整个 /data/local/tmp 后立刻按默认属主与权限重建，未备份的用户文件请自行转移。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认删除并重建 /data/local/tmp 吗？' 'REBUILD' || { printf '  已取消。\n'; return 0; }
  fi
  step '删除目录'
  run rm -rf /data/local/tmp
  step '按默认值重建'
  run mkdir -p /data/local/tmp
  run chown shell:shell /data/local/tmp
  run chmod 771 /data/local/tmp
  run restorecon -RF /data/local/tmp
  step '同步并核对'
  run sync
  run ls -ldZ /data/local/tmp
  done_task '请重启后再复测；重启后 inode 会进一步回落。'
}

f_debug_ramdisk(){
  begin_task '卸载 /debug_ramdisk 挂载' 'Inconsistent mount / 不一致的挂载（debug_ramdisk）' '610' '中' '否'
  step '当前挂载情况'
  run sh -c 'mount | grep debug_ramdisk || echo "(未发现 /debug_ramdisk 挂载)"'
  step '执行 umount'
  run umount /debug_ramdisk
  step '复核'
  run sh -c 'mount | grep debug_ramdisk || echo "(已无 /debug_ramdisk 挂载)"'
  done_task '若重启后再次出现，属系统/模块行为，需从模块侧处理。'
}

f_mount_diag(){
  begin_task '挂载视图诊断' 'mountinfo / 挂载异常(X)' '589 / 692' '只读' '否'
  step '可疑挂载点'
  run sh -c 'mount | grep -iE "debug_ramdisk|magic|overlay|KSU|susfs|worker" || echo "(无匹配)"'
  step '挂载组 ID 连续性（挂载间隙参考）'
  run sh -c 'cat /proc/self/mountinfo 2>/dev/null | awk "{print \$1}" | head -n 40'
  done_task '本项仅诊断；挂载类条目的根治手段多为元模块 / Zygisk 策略 / PathMask。'
}


# ---------------------------------------------------------------------
# 9. 修复项：tricky_store（TEE / 密钥证明配置）
# ---------------------------------------------------------------------
need_ts(){
  if [ ! -d "$TS" ]; then
    ng "未找到 $TS"
    info '请先安装 Tricky Store / TEESimulator / TEESimulator-RS 等密钥模块。'
    return 1
  fi
  return 0
}

f_ts_status(){
  begin_task '查看 tricky_store 配置' 'TEE / 密钥证明类' '433 / 469 / 513' '只读' '否'
  [ -d "$TS" ] || { warn "$TS 不存在（未安装密钥模块）"; done_task '跳过'; return 0; }
  step '目录内容'
  run ls -lZ "$TS"
  step 'keybox.xml 概要'
  run sh -c "grep -m1 -o '<Keybox[^>]*>' $TS/keybox.xml 2>/dev/null || echo '(无 keybox.xml)'"
  step 'security_patch.txt'
  run sh -c "cat $TS/security_patch.txt 2>/dev/null || echo '(无该文件)'"
  step 'target.txt 行数'
  run sh -c "wc -l < $TS/target.txt 2>/dev/null || echo '(无该文件)'"
  done_task '查看完成。'
}

f_ts_patch(){
  begin_task '生成 security_patch.txt' 'Tampered Attestation Key(X)（含 16 / 31）' '433' '低' '是'
  need_ts || { done_task '前置条件不满足'; return 0; }
  step '读取系统安全补丁日期'
  _patch="$(getprop ro.build.version.security_patch 2>/dev/null)"
  if [ -z "$_patch" ]; then
    _patch="$(grep '^ro.build.version.security_patch=' /system/build.prop 2>/dev/null | cut -d= -f2)"
  fi
  printf '        ro.build.version.security_patch = [%s]\n' "$_patch"
  if [ -z "$_patch" ]; then ng '无法读取安全补丁日期，已中止'; done_task '失败'; return 1; fi
  _ym="$(printf '%s' "$_patch" | cut -d'-' -f1-2 | tr -d '-')"
  step '选择 vendor 模式'
  printf '        1) vendor=%s（标准，先用这个）\n' "$_patch"
  printf '        2) vendor=prop（上面不行时用）\n'
  read_line '请输入 1 或 2（默认 1）：' '1'
  _mode="$JB_ANSWER"
  case "$_mode" in 2) _vendor='prop' ;; *) _vendor="$_patch" ;; esac
  step '备份原文件并写入'
  backup_path "$TS/security_patch.txt"
  JB_OUT="$JB_TMP/patch.$$"
  {
    printf 'system=%s\n' "$_ym"
    printf 'boot=%s\n' "$_patch"
    printf 'vendor=%s\n' "$_vendor"
  } >"$JB_OUT"
  if [ "$DRY_RUN" = 1 ]; then info "[演练模式] 计划写入内容："; cat "$JB_OUT"
  else
    cp "$JB_OUT" "$TS/security_patch.txt" && chmod 644 "$TS/security_patch.txt"
  fi
  step '结果'
  run cat "$TS/security_patch.txt"
  done_task '写入后请重启再复测；小米/红米 2026-03 前后系统本就可能报 (26)，属已知情况。'
}

f_ts_del_patch(){
  begin_task '删除 security_patch.txt' '发现TrickyStore/类似模块' '469' '低' '是'
  need_ts || { done_task '前置条件不满足'; return 0; }
  step '确认文件是否存在'
  run ls -l "$TS/security_patch.txt"
  step '备份并删除'
  backup_path "$TS/security_patch.txt"
  run rm -f "$TS/security_patch.txt"
  done_task '删除后请重启再复测。'
}

f_ts_target(){
  begin_task '批量写入 target.txt（强制处理）' 'TEE 损坏' '487' '低' '否'
  need_ts || { done_task '前置条件不满足'; return 0; }
  _det="${JB_DETECTOR_PKG:-$(detect_detector_pkg)}"
  [ -n "$_det" ] && info "已识别春秋检测包名：$_det（会一并写入）"
  step '当前行数'
  run sh -c "wc -l < $TS/target.txt 2>/dev/null || echo '(无该文件)'"
  warn '将覆盖 target.txt：固定写入 GMS / Vending（+ 已识别的检测器），并把所有第三方应用加「!」。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认覆盖 target.txt 吗？' '写入' || { printf '  已取消。\n'; return 0; }
  fi
  step '备份原文件'
  backup_path "$TS/target.txt"
  step '生成并写入'
  JB_OUT="$JB_TMP/target.$$"
  {
    printf 'com.google.android.gms!\n'
    printf 'com.android.vending!\n'
    [ -n "$_det" ] && printf '%s!\n' "$_det"
    pm list packages -3 2>/dev/null | sed 's/^package://;s/$/!/'
  } | awk '!seen[$0]++' >"$JB_OUT"
  if [ "$DRY_RUN" = 1 ]; then info '[演练模式] 预览前 10 行：'; head -n 10 "$JB_OUT"
  else
    cp "$JB_OUT" "$TS/target.txt" && chmod 644 "$TS/target.txt"
  fi
  step '结果（前 10 行）'
  run sh -c "head -n 10 $TS/target.txt"
  info 'target 列表通常实时生效，无需重启。'
  done_task '完成。'
}

f_ts_keybox(){
  _en="${ENTRY_NAME:-AOSP密钥}"; _el="${ENTRY_LINE:-513}"; ENTRY_NAME=''; ENTRY_LINE=''
  begin_task '替换 keybox.xml' "$_en" "$_el" '中' '是'
  need_ts || { done_task '前置条件不满足'; return 0; }
  step '说明'
  info '请先把新的 keybox.xml 放到手机里（例如 /sdcard/Download/keybox.xml）。'
  read_line '请输入 keybox.xml 路径（默认 /sdcard/Download/keybox.xml）：' '/sdcard/Download/keybox.xml'
  _src="$JB_ANSWER"
  if [ ! -f "$_src" ]; then ng "文件不存在：$_src"; done_task '失败'; return 1; fi
  step '校验来源文件'
  run ls -l "$_src"
  run sha256_file "$_src"
  step '备份原文件并替换'
  backup_path "$TS/keybox.xml"
  run cp "$_src" "$TS/keybox.xml"
  run chown root:root "$TS/keybox.xml"
  run chmod 644 "$TS/keybox.xml"
  run restorecon "$TS/keybox.xml"
  step '结果'
  run ls -lZ "$TS/keybox.xml"
  done_task '替换 keybox 会改变设备的密钥证明状态且不一定可逆，请保留备份；重启后复测。'
}

f_ts_backup(){
  begin_task '整目录备份 tricky_store' '预防性操作' '—' '只读' '否'
  need_ts || { done_task '前置条件不满足'; return 0; }
  step '复制到备份目录'
  _dst="${JB_BASE}/backup/tricky_store-$(date +%Y%m%d-%H%M%S)"
  run mkdir -p "$_dst"
  run cp -a "$TS/." "$_dst/"
  step '备份内容'
  run ls -l "$_dst"
  done_task "备份完成：$_dst"
}

# ---------------------------------------------------------------------
# 10. 修复项：存储区异常文件清理（高风险）
# ---------------------------------------------------------------------

scan_appendix_b(){
  begin_task '扫描高危路径（附录 B / 异常文件清单）' '异常文件' '946' '只读' '否'
  step '逐条检查是否存在'
  cat <<'EOF' >"$JB_TMP/clean_list.txt"
/data/local/stryker
/data/system/appretention
/data/local/tmp/luckys
/data/local/tmp/input_devices
/data/local/tmp/hyperceiler
/data/local/tmp/simplehook
/data/local/tmp/disabledallgoogleservices
/data/local/mio
/data/dna
/data/local/tmp/cleaner_starter
/data/local/tmp/byyang
/data/local/tmp/mount_mask
/data/local/tmp/mount_mark
/data/local/tmp/scripttmp
/data/local/luckys
/data/local/tmp/horae_control.log
/data/gpu_freq_table.conf
/storage/emulated/0/download/advanced
/storage/emulated/0/documents/advanced
/data/system/noactive
/data/system/freezer
/storage/emulated/0/android/naki
/data/swap_config.conf
/data/local/tmp/resetprop
/data/encore/default_cpu_gov
/data/encore/custom_default_cpu_gov
/data/local/tmp/encore_logo.png
/data/local/tmp/yshell
/data/local/tmp/Surfing_update
/data/local/tmp/android_server
/data/local/tmp/android_server64
/data/local/tmp/gdbserver
/data/A内核.ini
/data/BingPUBG
/data/BingHPJY/pz.cfg
/data/Dit驱动
/data/HPX
/data/HPY
/data/js
/data/js.sh
/data/local/MIO
/data/local/中野三玖
/data/nh.ko
/data/nh2
/data/nh3
/data/nh4
/data/nh5
/data/system/HPX
/data/system/HPY
/data/system/junge
/data/system/liboxmem.so
/data/system/xydriver.ko
/data/南瓜三角洲公益最新版本.sh
/data/物资.txt
/dev/Bing
/storage/emulated/0/rlgg
/storage/emulated/0/弱隐.sh
/storage/emulated/0/落叶配置
EOF
  _n=0; _hit=0
  exec 3<"$JB_TMP/clean_list.txt"
  while IFS= read -r p <&3; do
    [ -n "$p" ] || continue
    _n=$((_n + 1))
    if [ -e "$p" ]; then
      _hit=$((_hit + 1))
      printf '        %s[存在]%s %s\n' "$C_Y" "$C_0" "$p"
    fi
  done
  exec 3<&-
  printf '        共检查 %s 条，命中 %s 条。\n' "$_n" "$_hit"
  done_task '清理请使用「按清单清理」；本项只读。'
}

clean_appendix_b(){
  begin_task '按清单清理高危路径' '异常文件' '946' '高' '是'
  [ -f "$JB_TMP/clean_list.txt" ] || {
    info '先执行一次「扫描高危路径」以生成本地清单...'
    scan_appendix_b
  }
  warn '删除不可逆；/dev/Bing 等设备文件删除后重启会自动消失。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认进入逐条删除流程吗？' 'DELETE' || { printf '  已取消。\n'; return 0; }
  fi
  step '预检：清单中位于系统数据区的高危条目'
  _risky="$JB_TMP/risky.$$"; : >"$_risky"
  exec 3<"$JB_TMP/clean_list.txt"
  while IFS= read -r _rp <&3; do
    [ -n "$_rp" ] || continue
    [ -e "$_rp" ] || continue
    case "$_rp" in
      /data/system/*|/data/local/tmp|/data/local/tmp/*) printf '%s\n' "$_rp" >>"$_risky" ;;
    esac
  done
  exec 3<&-
  if [ -s "$_risky" ]; then
    warn '以下命中项位于系统数据区，删错可能导致开机异常：'
    exec 3<"$_risky"
    while IFS= read -r _rp <&3; do printf '        %s\n' "$_rp"; done
    exec 3<&-
    pln '  建议：先重启复测；确认是外挂/模块残留才删。删错时可用 MT 安全模式或 recovery 恢复。'
    confirm_exact '确认继续逐条处理这些系统数据区条目吗？' 'I_KNOW_RISK' || { printf '  已取消。\n'; return 0; }
  fi
  _del=0
  exec 3<"$JB_TMP/clean_list.txt"
  while IFS= read -r p <&3; do
    [ -n "$p" ] || continue
    [ -e "$p" ] || continue
    case "$p" in
      /data/local/tmp|/data/system|/data/adb|/|'')
        warn "跳过受保护路径：$p"; continue ;;
    esac
    printf '\n  发现：%s\n' "$p"
    if ask_yn '删除它？'; then
      run rm -rf "$p"
      _del=$((_del + 1))
    else
      info '已跳过'
    fi
  done
  exec 3<&-
  done_task "已删除 $_del 条；请重启后再复测。"
}

migrate_mt2(){
  begin_task '迁移 MT2 文件夹到 /data/adb/MT2' 'MT管理器（MT2文件夹）/异常文件' '926' '中' '否'
  _src_mt2='/storage/emulated/0/MT2'
  _dst_mt2='/data/adb/MT2'
  step '检查源目录'
  run ls -ld "$_src_mt2"
  step "准备目标目录 $_dst_mt2（不存在则创建）"
  run mkdir -p "$_dst_mt2"
  warn "请把 MT 管理器设置里的「MT2 路径」改成 $_dst_mt2，否则 MT 会再次在 /sdcard 生成 MT2。"
  warn '迁移顺序为「先复制、成功后删源」，跨文件系统不丢属性；复制失败会保留源目录。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认迁移吗？' 'MOVE' || { printf '  已取消。\n'; return 0; }
  fi
  step '复制到目标目录'
  if [ -d "$_src_mt2" ]; then
    info '目录较大时需要几十秒，请勿中断。'
    if run cp -a "$_src_mt2/." "$_dst_mt2/" || run cp -R "$_src_mt2/." "$_dst_mt2/"; then
      step '复制成功，删除源目录'
      run rm -rf "$_src_mt2"
    else
      warn '复制失败：已保留源目录，请检查剩余空间后重试'
    fi
  else
    info '源目录不存在，无需迁移（目标目录已就绪）'
  fi
  step '结果'
  run ls -ldZ "$_dst_mt2"
  run sh -c "du -sh '$_dst_mt2' 2>/dev/null || true"
  step '顺带检查根目录异常文件'
  run sh -c 'ls -l /storage/emulated/0/*.xml /storage/emulated/0/boot.img 2>/dev/null || echo "(无)"'
  info '若上方列出了你自己的文件请勿删除；本工具不会自动删除它们。'
  step '检查 MT 管理器的 MT2 路径设置'
  mt2_config_verdict
  done_task "已迁移到 $_dst_mt2；请按上面的提示把 MT 的 MT2 路径也改过去。"
}

# ---- 只读检测 MT 管理器（bin.mt.plus 系）配置里的 MT2 目录 ----
# 说明：MT 运行时把配置读入内存，退出时会写回 shared_prefs；
#       直接改它的 xml 会被覆盖，所以这里只检测并给出精确提示。
mt2_pref_raw(){
  for _pkg in $(pm list packages 2>/dev/null | sed 's/^package://' | grep -iE '^bin\.mt\.plus'); do
    for _pd in "/data/data/$_pkg/shared_prefs" /data/user/*/"$_pkg/shared_prefs" /data/user_de/0/"$_pkg/shared_prefs"; do
      [ -d "$_pd" ] || continue
      grep -rhoE '<string name="[^"]*"[^>]*>[^<]*MT2[^<]*</string>' "$_pd"/*.xml 2>/dev/null
    done
  done
}
mt2_pref_any(){
  for _pkg in $(pm list packages 2>/dev/null | sed 's/^package://' | grep -iE '^bin\.mt\.plus'); do
    for _pd in "/data/data/$_pkg/shared_prefs" /data/user/*/"$_pkg/shared_prefs" /data/user_de/0/"$_pkg/shared_prefs"; do
      [ -d "$_pd" ] || continue
      grep -rhoE '<string name="[^"]*"[^>]*>[^<]*/storage/[^<]*</string>' "$_pd"/*.xml 2>/dev/null | head -n 10
    done
  done
}
mt2_manual_hint(){
  info '手动修改：MT 管理器 → 左上角菜单 → 设置 → 找到「MT2 目录 / 临时目录」→ 改为 /data/adb/MT2'
  info '若当前版本没有该项，退而把 MT 的工作目录/主目录指到 /data/adb/MT2 下。'
  info '改完后完全退出 MT 再重开，确认 /storage/emulated/0/MT2 不再被重建。'
  info '（本工具只做只读检测：MT 运行时会在退出时把内存配置写回，脚本直接改它的 xml 会被覆盖。）'
}
mt2_config_verdict(){
  _pkgs="$(pm list packages 2>/dev/null | sed 's/^package://' | grep -iE '^bin\.mt\.plus')"
  if [ -z "$_pkgs" ]; then
    warn '未检测到 MT 管理器（bin.mt.plus 系）'
    mt2_manual_hint; return 1
  fi
  printf '        MT 包：%s\n' "$(printf '%s' "$_pkgs" | tr '\n' ' ')"
  _raw="$(mt2_pref_raw)"
  if [ -z "$_raw" ]; then
    warn '未在 MT 配置里找到含 MT2 的路径项'
    _other="$(mt2_pref_any)"
    if [ -n "$_other" ]; then
      info '以下是 MT 配置中的路径类条目（供人工核对）：'
      printf '%s\n' "$_other" | sed 's/^/          /'
    fi
    mt2_manual_hint; return 2
  fi
  printf '        配置项：\n'
  printf '%s\n' "$_raw" | sed 's/^/          /'
  _vals="$(printf '%s\n' "$_raw" | sed 's/.*>\([^<]*\)<.*/\1/')"
  case "$_vals" in
    *"/data/adb/MT2"*)
      ok 'MT 配置已指向 /data/adb/MT2'; return 0 ;;
    *"/storage/emulated/0/MT2"*)
      warn 'MT 配置仍指向旧的 /storage/emulated/0/MT2：会被重新创建，必须改掉'
      mt2_manual_hint; return 1 ;;
    *)
      warn 'MT 配置里的 MT2 路径不是 /data/adb/MT2'
      mt2_manual_hint; return 1 ;;
  esac
}
check_mt2_config(){
  begin_task '检查 MT 的 MT2 路径配置' 'MT管理器（MT2文件夹）/异常文件' '926' '只读' '否'
  step '读取 MT（bin.mt.plus 系）的 shared_prefs'
  mt2_config_verdict
  step '说明'
  info '本工具把 MT2 迁移到 /data/adb/MT2，MT 自己的设置也必须指到同一路径。'
  done_task '检查完成。'
}

clean_encore(){
  begin_task '清理 Encore Tweaks 残留' '发现异常模块' '995' '中' '是'
  step '检查'
  run ls -l /data/encore/default_cpu_gov /data/encore/custom_default_cpu_gov /data/local/tmp/encore_logo.png
  run sh -c 'pm list packages 2>/dev/null | grep -i encore || echo "(未发现 Encore 管理端包名)"'
  warn '会删除 /data/encore 目录与 /data/local/tmp/encore_logo.png（属于 Encore Tweaks 的配置数据）。'
  confirm_exact '确认删除 Encore 数据吗？' 'ENCORE' || { printf '  已取消。\n'; return 0; }
  step '删除数据残留'
  run rm -rf /data/encore
  run rm -f /data/local/tmp/encore_logo.png
  info '/system/bin/encore_profiler 位于只读分区，sh 无法删除，需卸载对应模块/刷机解决。'
  done_task '完成。'
}

run_adb_cleaner(){
  begin_task '清理 USB 调试痕迹' 'fdinfo mnt 采样异常（c）' '753' '中' '否'
  _s=''
  for c in "$JB_BASE/downloads/ADB-Trace-Cleaner-latest.sh" \
           "$JB_BASE/downloads/adb_trace_cleaner.sh" \
           /sdcard/Download/BilingualVersion-.DebugTraceCleanup.sh \
           /sdcard/Download/adb_trace_cleaner.sh \
           /sdcard/adb_trace_cleaner.sh; do
    [ -f "$c" ] && _s="$c" && break
  done
  if [ -z "$_s" ]; then
    warn '未找到清理脚本'
    info '请先在主页第 48 项下载 ADB-Trace-Cleaner，再回来执行。'
    done_task '跳过'
    return 0
  fi
  step "已找到脚本：$_s"
  run sha256_file "$_s"
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认执行该第三方脚本吗？' 'RUN' || { printf '  已取消。\n'; return 0; }
  fi
  step '执行'
  run sh "$_s"
  done_task '脚本只做临时属性与进程处理，重启后恢复。'
}

# ---------------------------------------------------------------------
# 11. 修复项：service.d 开机脚本
# ---------------------------------------------------------------------
ensure_service_d(){
  if [ -d "$SERVICE_D" ]; then return 0; fi
  warn "$SERVICE_D 不存在：当前 Root 管理器可能不支持 service.d。"
  return 1
}

shamiko_props(){
  cat <<'EOF'
ro.boot.vbmeta.device_state|locked|set
ro.boot.vbmetadevice_state|locked|set
ro.boot.verifiedbootstate|green|set
ro.boot.flash.locked|1|set
ro.boot.veritymode|enforcing|set
ro.boot.warranty_bit|0|set
ro.warranty_bit|0|set
ro.debuggable|0|set
ro.force.debuggable|0|set
ro.secure|1|set
ro.adb.secure|1|set
ro.build.type|user|set
ro.build.tags|release-keys|set
ro.vendor.boot.warranty_bit|0|set
ro.vendor.warranty_bit|0|set
vendor.boot.vbmeta.device_state|locked|set
vendor.boot.verifiedbootstate|green|set
sys.oem_unlock_allowed|0|set
ro.secureboot.lockstate|locked|set
ro.boot.realmebootstate|green|set
ro.boot.realme.lockstate|1|set
partition.system.verified|0|set
partition.vendor.verified|0|set
partition.product.verified|0|set
partition.system_ext.verified|0|set
partition.odm.verified|0|set
ro.oem_unlock_supported|0|set
persist.sys.usb.config|none|set
service.adb.root|0|set
ro.boot.selinux|enforcing|set
ro.boot.avb_version|1.3|set
ro.crypto.state|encrypted|set
ro.bootmode|unknown|contains:recovery
ro.boot.bootmode|unknown|contains:recovery
vendor.boot.bootmode|unknown|contains:recovery
EOF
}
f_shamiko_apply(){
  begin_task '立即应用属性伪装（运行态，35 条）' 'Property Modified（数字代表几处属性修改）' '1097' '中' '否'
  if [ "$RP_MODE" = 'none' ]; then ng 'resetprop / ksud 不可用，无法应用'; done_task '跳过'; return 1; fi
  step '备份当前值（快照）'
  _bk="$JB_BASE/backup/$(date +%Y%m%d-%H%M%S)-shamiko-plus.properties"
  mkdir -p "$JB_BASE/backup" 2>/dev/null
  : > "$_bk"
  shamiko_props | while IFS='|' read -r _n _v _m; do
    [ -n "$_n" ] || continue
    printf '%s=%s\n' "$_n" "$(getprop "$_n" 2>/dev/null)" >> "$_bk"
  done
  ok "已保存属性快照：$_bk"
  step '逐条写入（不落盘）'
  shamiko_props | while IFS='|' read -r _n _v _m; do
    [ -n "$_n" ] || continue
    _cur="$(getprop "$_n" 2>/dev/null)"
    case "$_m" in
      contains:*)
        case "$_cur" in *"${_m#contains:}"*) rp -n "$_n" "$_v" ;; esac ;;
      *)
        [ -z "$_cur" ] || [ "$_cur" = "$_v" ] || rp -n "$_n" "$_v" ;;
    esac
  done
  info '空值属性会被跳过（与原版 shamiko_Plus.sh 语义一致）；不一致的才会写入。'
  warn '这是运行态修改，重启后失效；要长期生效请部署开机脚本。'
  done_task '完成；重启前后可在「工具（查看备份）」里找到快照。'
}
deploy_shamiko(){
  begin_task '部署属性隐藏开机脚本 shamiko_Plus.sh' 'Property Modified（数字代表几处属性修改）' '1097' '中' '是'
  ensure_service_d || { done_task '跳过'; return 0; }
  step '生成脚本内容'
  JB_OUT="$JB_TMP/shamiko.$$"
  {
    printf '#!/system/bin/sh\n'
    printf '# 本脚本改写自「春秋检测项解决方案」File/shamiko_Plus.sh\n'
    printf '# 版权 Copyright (c) 2026 Su xiaoming ｜ MIT License\n'
    printf '# 完整许可声明：本工具 --license，或包内 THIRD-PARTY-NOTICES.txt\n'
    printf 'check_reset_prop() {\n  NAME=$1\n  EXPECTED=$2\n  VALUE=$(resetprop $NAME)\n  [ -z $VALUE ] || [ $VALUE = $EXPECTED ] || resetprop -n $NAME $EXPECTED\n}\n'
    printf 'contains_reset_prop() {\n  NAME=$1\n  CONTAINS=$2\n  NEWVAL=$3\n  case "$(resetprop $NAME)" in\n    *"$CONTAINS"*) resetprop -n $NAME $NEWVAL ;;\n  esac\n}\n'
    printf 'resetprop -w sys.boot_completed 0\n'
    shamiko_props | while IFS='|' read -r _n _v _m; do
      [ -n "$_n" ] || continue
      case "$_m" in
        contains:*) printf 'contains_reset_prop "%s" "%s" "%s"\n' "$_n" "${_m#contains:}" "$_v" ;;
        *)          printf 'check_reset_prop "%s" "%s"\n' "$_n" "$_v" ;;
      esac
    done
  } >"$JB_OUT"
  _dst="$SERVICE_D/shamiko_Plus.sh"
  step "备份并写入 $_dst"
  backup_path "$_dst"
  run cp "$JB_OUT" "$_dst"
  run chown root:root "$_dst"
  run chmod 755 "$_dst"
  run restorecon "$_dst"
  step '语法检查与结果'
  run sh -n "$_dst"
  run ls -lZ "$_dst"
  warn '脚本使用 resetprop，需要 Magisk/KSU 提供；不持久化属性是正常设计。'
  done_task '重启后由 Root 管理器在开机阶段自动执行。'
}


list_service_d(){
  begin_task '查看已部署的开机脚本' 'service.d 管理' '—' '只读' '否'
  if [ ! -d "$SERVICE_D" ]; then warn "$SERVICE_D 不存在"; done_task '跳过'; return 0; fi
  step '目录内容'
  run ls -lZ "$SERVICE_D"
  done_task '查看完成。'
}

remove_service_d(){
  begin_task '移除本工具部署的开机脚本' 'service.d 管理' '—' '低' '是'
  if [ ! -d "$SERVICE_D" ]; then warn "$SERVICE_D 不存在"; done_task '跳过'; return 0; fi
  step '将被移除的脚本'
  run ls -l "$SERVICE_D/shamiko_Plus.sh" "$SERVICE_D/jb_usb_debug_off.sh"
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认移除这两个脚本吗？' 'REMOVE' || { printf '  已取消。\n'; return 0; }
  fi
  backup_path "$SERVICE_D/shamiko_Plus.sh"
  backup_path "$SERVICE_D/jb_usb_debug_off.sh"
  run rm -f "$SERVICE_D/shamiko_Plus.sh" "$SERVICE_D/jb_usb_debug_off.sh"
  done_task '重启后不再执行。'
}

# ---------------------------------------------------------------------
# 12. 诊断与信息收集
# ---------------------------------------------------------------------
f_check_props(){
  begin_task '检查正文附录 C 的被检查属性' '内核 / 属性与系统特征检测' '1434（附录 C）' '只读' '否'
  step '逐项打印'
  cat <<'EOF' >"$JB_TMP/props_list.txt"
dalvik.vm.dex2oat-flags
persist.chunqiu.path_hide
persist.debug.dalvik.vm.core_platform_api_policy
persist.logd.size
persist.logd.size.crash
persist.logd.size.main
persist.logd.size.system
persist.sys.pihooks.disable.gms
persist.sys.pihooks_BRAND
persist.sys.pihooks_DEVICE
persist.sys.pihooks_DEVICE_INIT
persist.sys.pihooks_MANUFACTURE
persist.sys.pihooks_MODEL
persist.sys.pihooks_PRODUCT
persist.sys.pihooks_RELEASE
persist.sys.pihooks_SDK_INT
persist.sys.pixelprops.gapps
persist.sys.pixelprops.gms
persist.sys.pixelprops.google
persist.sys.pixelprops.gphotos
persist.sys.spoof.gms
persist.sys.vold_app_data_isolation_enabled
ro.boot.flash.locked
ro.boot.selinux
ro.boot.vbmeta.avb_version
ro.boot.vbmeta.device_state
ro.boot.vbmeta.digest
ro.boot.verifiedbootstate
ro.build.date.utc
ro.build.type
ro.build.version.sdk
ro.product.brand
EOF
  exec 3<"$JB_TMP/props_list.txt"
  while IFS= read -r p <&3; do
    [ -n "$p" ] || continue
    printf '        %-46s = [%s]\n' "$p" "$(getprop "$p" 2>/dev/null)"
  done
  exec 3<&-
  done_task '对照附录 C 自行判断哪些是被模块写入的伪装属性。'
}

f_find_pid(){
  begin_task '反查进程 PID' '异常进程0000（pid）' '333' '只读' '否'
  read_line '请输入要反查的 PID（数字）：' ''
  _pid="$JB_ANSWER"
  case "$_pid" in
    ''|*[!0-9]*) ng 'PID 必须是数字'; done_task '跳过'; return 0 ;;
  esac
  step "ps -ef | grep $_pid"
  run sh -c "ps -ef 2>/dev/null | grep -w '$_pid' || echo '(未找到该 PID 进程)'"
  step '补充：该 PID 对应的域'
  run sh -c "cat /proc/$_pid/attr/current 2>/dev/null || echo '(无法读取，正常情况)'"
  info '根因是审计日志侧信道漏洞，本项只能定位，无法用 sh 修复。'
  done_task '完成。'
}

f_diag_report(){
  begin_task '生成诊断报告' '通用排查方法' '34（说明与反馈）' '只读' '否'
  _r="$JB_BASE/logs/diag-$(date +%Y%m%d-%H%M%S).txt"
  step "输出文件：$_r"
  if [ "$DRY_RUN" = 1 ]; then info '[演练模式] 跳过'; done_task '完成'; return 0; fi
  {
    printf 'JinBeiChunQiuFixToolPro2 %s 诊断报告 %s\n' "$JB_VER" "$(date)"
    printf '作者：%s\n' "$JB_AUTHOR"
    printf '脚本哈希：%s\n' "$SELF_HASH"
    printf '%s\n' '---- 环境 ----'
    printf 'Android %s (SDK %s) / 内核 %s\n' "$(getprop ro.build.version.release 2>/dev/null)" "$(getprop ro.build.version.sdk 2>/dev/null)" "$(uname -r 2>/dev/null)"
    printf '机型 %s %s / 安全补丁 %s\n' "$(getprop ro.product.brand 2>/dev/null)" "$(getprop ro.product.model 2>/dev/null)" "$(getprop ro.build.version.security_patch 2>/dev/null)"
    printf 'Root 管理器 %s / SELinux %s\n' "$(root_manager)" "$(getenforce 2>/dev/null)"
    printf 'resetprop %s\n' "$RP_DESC"
    printf '%s\n' '---- 模块 ----'
    ls /data/adb/modules 2>/dev/null
    printf '%s\n' '---- 伪装属性 ----'
    getprop 2>/dev/null | grep -iE 'pihooks|pixelprops|spoof'
    printf '%s\n' '---- 挂载（可疑）----'
    mount 2>/dev/null | grep -iE 'debug_ramdisk|magic|overlay|KSU|susfs'
    printf '%s\n' '---- /data/local/tmp ----'
    ls -ldZ /data/local/tmp 2>/dev/null
    printf '%s\n' '---- tricky_store ----'
    ls -lZ "$TS" 2>/dev/null
    printf '%s\n' '---- 附录 C 属性 ----'
    for p in ro.boot.flash.locked ro.boot.verifiedbootstate ro.boot.vbmeta.device_state ro.boot.vbmeta.avb_version ro.build.type ro.build.version.sdk ro.product.brand dalvik.vm.dex2oat-flags persist.sys.vold_app_data_isolation_enabled; do
      printf '%s=%s\n' "$p" "$(getprop "$p" 2>/dev/null)"
    done
  } >"$_r" 2>&1
  step '结果'
  run ls -l "$_r"
  run sh -c "head -n 20 '$_r'"
  done_task "报告已生成：$_r"
}

# ---------------------------------------------------------------------
# 13. 在线校验 / 资料下载
# ---------------------------------------------------------------------
net_download_repo(){
  if [ "$DRY_RUN" = 1 ]; then info '演练模式：跳过实际联网下载'; return 0; fi
  begin_task '下载官方修复脚本（只下载不执行）' '参考：Found property / 26Pass / shamiko_Plus' '1089 / 433 / 1097' '低' '否'
  if [ "$(net_tool_name)" = '无' ]; then ng '设备缺少下载工具，无法联网'; done_task '跳过'; return 0; fi
  _dl="$JB_BASE/downloads"
  step '准备目录'
  run mkdir -p "$_dl"
  step '下载 3 个官方脚本'
  _base='https://raw.githubusercontent.com/mingzun09/Chunqiu-Detector-Problem-solution/main/File'
  fetch_url "$_base/Found%20property.sh" "$_dl/Found property.sh" && ok 'Found property.sh' || ng 'Found property.sh'
  fetch_url "$_base/shamiko_Plus.sh" "$_dl/shamiko_Plus.sh" && ok 'shamiko_Plus.sh' || ng 'shamiko_Plus.sh'
  fetch_url "$_base/Tampered%20Attestation%20Key(26)Pass.sh" "$_dl/Tampered Attestation Key(26)Pass.sh" && ok '26Pass.sh' || ng '26Pass.sh'
  step '校验并列出'
  for f in "$_dl/Found property.sh" "$_dl/shamiko_Plus.sh" "$_dl/Tampered Attestation Key(26)Pass.sh"; do
    if [ -f "$f" ]; then printf '        %s\n' "$f"; sha256_file "$f" | sed 's/^/          sha256: /'; fi
  done
  info '下载内容不会自动执行；请在阅读后再决定是否使用。'
  done_task "下载目录：$_dl"
}

net_download_tools(){
  if [ "$DRY_RUN" = 1 ]; then info '演练模式：跳过实际联网下载'; return 0; fi
  begin_task '获取 Inode-Hijacker / ADB-Trace-Cleaner' 'Suspicious Surroundings（b） / fdinfo mnt' '879 / 753' '低' '否'
  if [ "$(net_tool_name)" = '无' ]; then ng '设备缺少下载工具，无法联网'; done_task '跳过'; return 0; fi
  step '准备目录'
  run mkdir -p "$JB_BASE/downloads"
  _i="$JB_BASE/downloads/Inode-Hijacker-latest.sh"
  _a="$JB_BASE/downloads/ADB-Trace-Cleaner-latest.sh"
  step 'Inode-Hijacker：查最新 release，失败则用已核实版本'
  _u="$(gh_latest_asset YiJieqwq/Inode-Hijacker)"
  if [ -z "$_u" ]; then _u="$JB_KNOWN_INODE_URL"; info "API 不可用，改用已核实版本 $JB_KNOWN_INODE_VER"; fi
  printf '        %s\n' "$_u"
  if fetch_url "$_u" "$_i"; then
    ok "已保存：$_i"
    sha256_file "$_i" | sed 's/^/          sha256: /'
    [ "$_u" = "$JB_KNOWN_INODE_URL" ] && verify_sha "$_i" "$JB_KNOWN_INODE_SHA"
  else ng '下载失败'; fi
  step 'ADB-Trace-Cleaner：查最新 release，失败则用已核实版本'
  _u2="$(gh_latest_asset YiJieqwq/ADB-Trace-Cleaner)"
  if [ -z "$_u2" ]; then _u2="$JB_KNOWN_ADB_URL"; info "API 不可用，改用已核实版本 $JB_KNOWN_ADB_VER"; fi
  printf '        %s\n' "$_u2"
  if fetch_url "$_u2" "$_a"; then
    ok "已保存：$_a"
    sha256_file "$_a" | sed 's/^/          sha256: /'
    [ "$_u2" = "$JB_KNOWN_ADB_URL" ] && verify_sha "$_a" "$JB_KNOWN_ADB_SHA"
  else ng '下载失败'; fi
  warn '第三方脚本仅供技术研究，请自行审阅后再执行；本工具不会自动运行它们。'
  done_task "下载目录：$JB_BASE/downloads"
}

net_custom_download(){
  if [ "$DRY_RUN" = 1 ]; then info '演练模式：跳过实际联网下载'; return 0; fi
  begin_task '自定义地址下载' '资料获取' '—' '低' '否'
  read_line '请输入直链 URL：' ''
  _u="$JB_ANSWER"
  case "$_u" in http://*|https://*) ;; *) ng '地址无效'; done_task '跳过'; return 0 ;; esac
  read_line '保存文件名（默认 custom_download.bin）：' 'custom_download.bin'
  _f="$JB_BASE/downloads/$JB_ANSWER"
  step "下载到 $_f"
  if fetch_url "$_u" "$_f"; then
    run ls -l "$_f"
    run sha256_file "$_f"
  else
    ng '下载失败'
  fi
  done_task '完成（不会自动执行）。'
}

net_links(){
  begin_task '致谢与开源许可' '参考资料' '—' '只读' '否'
  step '相关资料与上游项目'
  cat <<'EOF'
        春秋检测项解决方案（本工具依据的正文）
          https://github.com/mingzun09/Chunqiu-Detector-Problem-solution
        致谢清单
          https://github.com/mingzun09/Chunqiu-Detector-Problem-solution/blob/main/File/Doc/thanks.md
        Inode-Hijacker（目录 inode 处理，纯 sh）
          https://github.com/YiJieqwq/Inode-Hijacker/releases
        ADB-Trace-Cleaner（USB 调试痕迹清理，纯 sh）
          https://github.com/YiJieqwq/ADB-Trace-Cleaner/releases
EOF
  step '开源致谢（第三方代码随副本许可声明）'
  pln "        项目名称：$JB_THIRD_PARTY_PROJECT"
  pln "        作者    ：$JB_THIRD_PARTY_AUTHOR"
  pln "        仓库    ：$JB_THIRD_PARTY_URL"
  pln "        许可    ：$JB_THIRD_PARTY_LICENSE    $JB_THIRD_PARTY_COPYRIGHT"
  pln ""
  pln "        ── 组件 2 ──"
  pln "        项目名称：$JB_THIRD_PARTY2_PROJECT"
  pln "        作者    ：$JB_THIRD_PARTY2_AUTHOR"
  pln "        仓库    ：$JB_THIRD_PARTY2_URL"
  pln "        许可    ：$JB_THIRD_PARTY2_LICENSE    $JB_THIRD_PARTY2_COPYRIGHT"
  pln "        改动自  ：File/shamiko_Plus.sh / File/Found property.sh /"
  pln "                  File/Tampered Attestation Key(26)Pass.sh"
  pln ''
  third_party_notice
  write_third_party_notice 2>/dev/null || true
  info "同一份声明已写入：$JB_BASE/$JB_THIRD_PARTY_NOTICE"
  done_task '以上为完整许可声明；转发、转载或二次打包时请一并保留。'
}

# ---------------------------------------------------------------------
# 14. 备份与日志
# ---------------------------------------------------------------------
list_backups(){
  begin_task '查看备份' '通用' '—' '只读' '否'
  step '备份根目录'
  run ls -l "$JB_BASE/backup"
  step '最近备份内容'
  run sh -c "ls -lR $JB_BASE/backup 2>/dev/null | head -n 60"
  done_task '查看完成。'
}

restore_backup(){
  begin_task '从备份恢复单个路径' '通用' '—' '中' '否'
  read_line '请输入要恢复的原始绝对路径（例如 /data/adb/tricky_store/keybox.xml）：' ''
  _p="$JB_ANSWER"
  case "$_p" in /*) ;; *) ng '必须是绝对路径'; done_task '跳过'; return 0 ;; esac
  if path_is_protected "$_p" restore; then
    ng "该路径属于受保护位置，拒绝覆盖：$_p"
    info '（模块目录、root 管理器目录、/data/system、/data/local/tmp 本体等不允许经此项覆盖）'
    done_task '已拒绝'; return 0
  fi
  step '查找备份'
  _b="$(find "$JB_BASE/backup" -path "*/${_p#/}" 2>/dev/null | head -n 5)"
  if [ -z "$_b" ]; then ng '未找到该路径的备份'; done_task '跳过'; return 0; fi
  printf '        找到候选备份：\n%s\n' "$_b"
  _b1="$(printf '%s\n' "$_b" | head -n 1)"
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact "确认用备份覆盖 $_p 吗？" 'RESTORE' || { printf '  已取消。\n'; return 0; }
  fi
  step '恢复'
  run cp -a "$_b1" "$_p"
  run restorecon "$_p"
  done_task '恢复完成。'
}

view_log(){
  begin_task '查看本次日志' '通用' '—' '只读' '否'
  step "日志文件：$LOG"
  run sh -c "tail -n 80 '$LOG'"
  done_task '完成。'
}

export_log(){
  begin_task '导出日志到 /sdcard' '通用' '—' '只读' '否'
  _d="/sdcard/JinBeiChunQiuFixToolPro2/logs/export-$(date +%Y%m%d-%H%M%S).log"
  step "导出到 $_d"
  run cp "$LOG" "$_d"
  done_task '完成。'
}

# ---------------------------------------------------------------------
# 14.5 与 FIXTOOL 1.1.0 融合的能力
#   模块临时隔离 / 内置 Inode-Hijacker / /apex su / PID 回绕 / 路径删除 /
#   service.d 脚本复制 / 自动体检 / 来源提示
# ---------------------------------------------------------------------

# ---- 模块临时隔离：移出 /data/adb/modules（不删除），重启后停止加载 ----
module_display_name(){
  _mp="$1"; _mn=''
  if [ -f "$_mp/module.prop" ]; then
    while IFS= read -r _l; do
      case "$_l" in name=*) _mn="${_l#name=}"; break ;; esac
    done < "$_mp/module.prop"
  fi
  [ -n "$_mn" ] || _mn="${_mp##*/}"
  printf '%s' "$_mn"
}
module_match_reason(){
  _mp="$1"; _txt=''
  [ -f "$_mp/module.prop" ] || return 1
  while IFS= read -r _l; do
    case "$_l" in name=*|description=*) _txt="$_txt ${_l#*=}" ;; esac
  done < "$_mp/module.prop"
  for _k in 隐藏 一键隐藏 改机 改机型 机型 设备伪装 伪装 月虹 悲伤 密钥 keybox; do
    case "$_txt" in *"$_k"*) printf '%s' "$_k"; return 0 ;; esac
  done
  return 1
}
collect_module_candidates(){
  _out="$1"; : > "$_out" || return 1
  [ -d /data/adb/modules ] || return 0
  for _mp in /data/adb/modules/*; do
    [ -d "$_mp" ] || continue
    _mid="${_mp##*/}"
    case "$_mid" in ''|*[!A-Za-z0-9._-]*) continue ;; esac
    [ -e "$_mp/disable" ] && continue
    _r="$(module_match_reason "$_mp" 2>/dev/null)" || continue
    printf '%s|%s\n' "$_mp" "$_r" >> "$_out"
  done
}
quarantine_modules(){
  begin_task '临时隔离模块（移出 /data/adb/modules，不删除）' 'Tampered Attestation Key(X)（含 16 / 31）' '433' '高' '是'
  if [ ! -d /data/adb/modules ]; then warn '未找到 /data/adb/modules'; done_task '跳过'; return 0; fi
  step '按 module.prop 的名称/描述匹配密钥、隐藏、改机类模块'
  _cand="$JB_TMP/modcand.$$"
  collect_module_candidates "$_cand"
  if [ ! -s "$_cand" ]; then info '未匹配到隐藏 / 改机 / 密钥类模块'; done_task '完成'; return 0; fi
  _i=1
  exec 3<"$_cand"
  while IFS='|' read -r _mp _r <&3; do
    printf '        %s. %s\n           匹配：%s   路径：%s\n' "$_i" "$(module_display_name "$_mp")" "$_r" "$_mp"
    _i=$((_i + 1))
  done
  exec 3<&-
  warn '只做「移出 /data/adb/modules」的临时停用，不会删除模块文件。'
  read_line '输入要临时停用的编号（如 1,3 ；a=全选 ；0=跳过）：' '0'
  _sel="$JB_ANSWER"
  case "$_sel" in 0|'') info '已跳过'; done_task '完成'; return 0 ;; esac
  case "$_sel" in a|A) _all=1 ;; *) _all=0 ;; esac
  confirm_exact '模块会移出 /data/adb/modules（重启后停止加载），确认继续' 'TEMP_DISABLE_MODULES' || { printf '  已取消。\n'; return 0; }
  _batch="$JB_QUARANTINE_ROOT/$(date +%Y%m%d-%H%M%S)-$$"
  step "准备批次目录 $_batch"
  if [ "$DRY_RUN" = 1 ]; then info '[演练模式] 跳过实际移动'; done_task '演练完成'; return 0; fi
  mkdir -p "$_batch" 2>/dev/null || { ng '无法创建批次目录'; done_task '失败'; return 1; }
  chmod 700 "$_batch" 2>/dev/null
  _man="$_batch/manifest.txt"
  printf '# module_id|original_path\n' > "$_man"
  _n=0; _idx=1
  exec 3<"$_cand"
  while IFS='|' read -r _mp _r <&3; do
    if [ "$_all" = 1 ] || printf '%s\n' "$_sel" | tr ',' ' ' | grep -qx "$_idx"; then
      _mid="${_mp##*/}"
      case "$_mp:$_mid" in
        /data/adb/modules/*:*[!A-Za-z0-9._-]*) warn "跳过不安全路径：$_mp" ;;
        /data/adb/modules/*:*)
          if [ -e "$_batch/$_mid" ]; then warn "目标已存在，跳过：$_mid"
          elif mv "$_mp" "$_batch/$_mid"; then printf '%s|%s\n' "$_mid" "$_mp" >> "$_man"; _n=$((_n + 1))
          else ng "移动失败：$_mp"; fi ;;
        *) warn "跳过范围外路径：$_mp" ;;
      esac
    fi
    _idx=$((_idx + 1))
  done
  exec 3<&-
  chmod 600 "$_man" 2>/dev/null
  step '结果'
  run ls -l "$_batch"
  [ "$_n" = 0 ] && { warn '没有模块被移动'; done_task '完成'; return 1; }
  ok "已临时停用 $_n 个模块；清单：$_man"
  info '重启后生效；还原请走 14) 修复（Tampered Attestation Key(X)）→ 5) 恢复被隔离的模块。'
  done_task '完成。'
}
list_quarantine_batches(){
  [ -d "$JB_QUARANTINE_ROOT" ] || return 0
  for _b in "$JB_QUARANTINE_ROOT"/*; do
    [ -d "$_b" ] && [ -f "$_b/manifest.txt" ] && printf '%s\n' "$_b"
  done
}
restore_modules(){
  begin_task '恢复被隔离的模块到 /data/adb/modules' '临时隔离的模块' '—' '中' '是'
  _bf="$JB_TMP/batches.$$"
  list_quarantine_batches > "$_bf" 2>/dev/null
  if [ ! -s "$_bf" ]; then info '没有可恢复的批次'; done_task '完成'; return 0; fi
  step '可恢复批次'
  _i=1
  exec 3<"$_bf"
  while IFS= read -r _b <&3; do
    _c="$(sed -n '2,$p' "$_b/manifest.txt" 2>/dev/null | wc -l | tr -d ' ')"
    printf '        %s. %s（%s 个模块）\n' "$_i" "${_b##*/}" "$_c"
    _i=$((_i + 1))
  done
  exec 3<&-
  read_line '输入要恢复的批次编号（0=取消）：' '0'
  case "$JB_ANSWER" in 0|'') info '已取消'; done_task '完成'; return 0 ;; esac
  case "$JB_ANSWER" in *[!0-9]*) ng '编号无效'; done_task '跳过'; return 1 ;; esac
  _sel=''; _i=1
  exec 3<"$_bf"
  while IFS= read -r _b <&3; do
    [ "$_i" = "$JB_ANSWER" ] && _sel="$_b"
    _i=$((_i + 1))
  done
  exec 3<&-
  [ -n "$_sel" ] || { ng '批次不存在'; done_task '跳过'; return 1; }
  confirm_exact '将按清单恢复到 /data/adb/modules（需要重启）' 'RESTORE_MODULES' || { printf '  已取消。\n'; return 0; }
  _n=0
  exec 3<"$_sel/manifest.txt"
  while IFS='|' read -r _mid _orig <&3; do
    case "$_mid" in \#*|'') continue ;; esac
    case "$_mid" in *[!A-Za-z0-9._-]*) warn "跳过无效 ID：$_mid"; continue ;; esac
    [ -d "$_sel/$_mid" ] || continue
    if [ -e "/data/adb/modules/$_mid" ]; then warn "目标已存在，未覆盖：$_mid"; continue; fi
    if [ "$DRY_RUN" = 1 ]; then info "[演练模式] 恢复 $_mid"; _n=$((_n + 1)); continue; fi
    if mv "$_sel/$_mid" "/data/adb/modules/$_mid"; then ok "已恢复：$_mid"; _n=$((_n + 1)); else ng "恢复失败：$_mid"; fi
  done
  exec 3<&-
  done_task "已恢复 $_n 个模块；重启后生效（批次目录保留：$_sel）。"
}

# ---- /apex 内的 su 二进制（SU binary detected）----
f_su_binary(){
  begin_task '处理 /apex 内的 su 二进制' 'SU binary detected' '230' '中' '是'
  _t='/apex/com.android.virt/bin/su'
  step '检查目标文件'
  if [ ! -e "$_t" ]; then info "未找到 $_t，无需处理"; done_task '完成'; return 0; fi
  run ls -lZ "$_t"
  if [ ! -x "$_t" ]; then info '该文件已没有执行权限，无需处理'; done_task '完成'; return 0; fi
  warn '关闭执行位可能影响 Android 虚拟化/相关系统组件；/apex 只读时操作会失败。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认尝试关闭该文件的全部执行权限？' 'SU_FIX' || { printf '  已取消。\n'; return 0; }
  fi
  step '备份原权限'
  _mode="$(stat -c '%a' "$_t" 2>/dev/null)"
  _bk="$JB_BASE/backup/$(date +%Y%m%d-%H%M%S)_su-binary.mode"
  mkdir -p "$JB_BASE/backup" 2>/dev/null
  if printf 'path=%s\nmode=%s\n' "$_t" "${_mode:-unknown}" > "$_bk" 2>/dev/null; then ok "已保存：$_bk"; fi
  step 'chmod a-x'
  run chmod a-x "$_t"
  step '复核'
  if [ -x "$_t" ]; then
    warn '仍可执行：/apex 为只读或被系统策略保护 —— 本条在该设备上 sh 无法解决，需模块 overlay'
  else
    ok '已关闭执行权限，建议重启后复测'
  fi
  info "如需还原：chmod ${_mode:-755} $_t"
  done_task '完成。'
}

# ---- PID 回绕 + Zygote 重启（实验性，高风险）----
f_pid_wrap_zygote(){
  begin_task 'PID 回绕兼容处理 + 重启 Zygote（实验性）' 'Found ksu/免解设备 / 异常进程0000（pid）' '218 / 333' '高' '是'
  warn '先把 ro.boot.selinux 写成 enforcing，再创建短生命周期进程直到 PID 回绕，最后 setprop ctl.restart zygote。'
  warn '可能终止应用、丢失未保存状态或导致系统不稳定；官方对免解模式不提供保证。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '第一次确认：已备份 boot/重要数据并接受 Zygote 重启风险' 'PID_WRAP_ZYGOTE' || { printf '  已取消。\n'; return 0; }
  fi
  step '备份当前状态'
  _bk="$JB_BASE/backup/$(date +%Y%m%d-%H%M%S)_$$-pid-wrap.properties"
  mkdir -p "$JB_BASE/backup" 2>/dev/null
  printf 'ro.boot.selinux=%s\npid_max=%s\n' "$(getprop ro.boot.selinux 2>/dev/null)" "$(cat /proc/sys/kernel/pid_max 2>/dev/null)" > "$_bk" 2>/dev/null && ok "已保存：$_bk"
  step '写入 ro.boot.selinux=enforcing'
  if [ "$(getprop ro.boot.selinux 2>/dev/null)" != 'enforcing' ]; then
    rp -n ro.boot.selinux enforcing
  else
    info '已是 enforcing'
  fi
  _pm="$(cat /proc/sys/kernel/pid_max 2>/dev/null)"
  case "$_pm" in ''|*[!0-9]*) _pm=32768 ;; esac
  _max=$((_pm + 2048))
  [ "$_max" -gt 65536 ] && _max=65536
  step "创建短生命周期进程直到 PID 回绕（上限 $_max 次）"
  if [ "$DRY_RUN" = 1 ]; then info '[演练模式] 跳过进程创建与 Zygote 重启'; done_task '演练完成'; return 0; fi
  _last="$(sh -c 'echo $PPID' 2>/dev/null)"
  case "$_last" in ''|*[!0-9]*) _last=$$ ;; esac
  _wrapped=0; _it=0
  while :; do
    : &
    _cur=$!
    wait "$_cur" 2>/dev/null
    [ "$_cur" -lt "$_last" ] && _wrapped=1
    if [ "$_wrapped" = 1 ] && [ "$_cur" -ge 1700 ]; then break; fi
    _last="$_cur"
    _it=$((_it + 1))
    if [ "$_it" -ge "$_max" ]; then
      warn "在 $_it 次以内未检测到 PID 回绕，已停止，不会重启 Zygote"
      done_task '未完成。'
      return 1
    fi
    [ $((_it % 2000)) -eq 0 ] && printf '        ...已创建约 %s 个短生命周期进程\n' "$_it"
  done
  ok "PID 回绕阶段完成（约 $_it 个进程）"
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '最后确认：现在执行 setprop ctl.restart zygote 重启 Zygote' 'RESTART_ZYGOTE' || { printf '  已跳过重启。\n'; done_task '属性处理已完成。'; return 0; }
  fi
  step 'setprop ctl.restart zygote'
  run setprop ctl.restart zygote
  done_task '请等待系统恢复后重新检测。'
}

# ---- 按检测结果给出的路径删除（白名单）----
# ---- 受保护路径判定：防误删 root 管理器 / 系统数据区 ----
path_is_protected(){ # $1 路径  $2 delete|restore ；0=受保护
  case "$1" in
    /|/data|/data/adb|/data/system|/data/data|/data/user|/data/user_de|/data/local|/data/local/tmp|/data/misc|/data/vendor|/data/dalvik-cache|/system|/vendor|/product|/my_product|/boot|/apex|/proc|/sys|/dev|/sdcard|/storage|/storage/emulated|/storage/emulated/0) return 0 ;;
    /data/system/*|/data/misc/*|/data/vendor/*|/data/dalvik-cache/*|/system/*|/vendor/*|/product/*|/my_product/*|/boot/*|/apex/*|/proc/*|/sys/*) return 0 ;;
    /data/adb/modules|/data/adb/modules/*|/data/adb/magisk|/data/adb/magisk/*|/data/adb/ksu|/data/adb/ksu/*|/data/adb/ksud|/data/adb/ap|/data/adb/ap/*|/data/adb/apd) return 0 ;;
    /data/adb/service.d|/data/adb/service.d/*|/data/adb/post-fs-data.d|/data/adb/post-fs-data.d/*|/data/adb/tricky_store|/data/adb/tricky_store/*)
      [ "$2" = 'delete' ] && return 0 ;;
  esac
  _pd="$(printf '%s' "$1" | tr -cd '/' | wc -c | tr -d ' ')"
  [ "$_pd" -lt 2 ] && return 0
  return 1
}
delete_reported_path(){
  begin_task '按检测结果删除指定路径' '异常文件 / 挂载异常(X)' '946 / 692' '高' '是'
  info '仅允许 /storage/emulated/0、/sdcard、/data/local/tmp、/data/adb 下的路径。'
  read_line '输入检测结果给出的完整路径：' ''
  _t="$JB_ANSWER"
  case "$_t" in
    ''|*[!A-Za-z0-9_./\:-]*) ng '路径含不允许的字符'; done_task '跳过'; return 1 ;;
    /storage/emulated/0/*|/sdcard/*|/data/local/tmp/*|/data/adb/*) ;;
    *) ng '为安全起见仅允许上述白名单目录'; done_task '跳过'; return 1 ;;
  esac
  if path_is_protected "$_t" delete; then
    ng "该路径属于受保护位置，已拒绝删除：$_t"
    info '（root 管理器、模块目录、/data/system、/data/local/tmp 本体等都不允许经此项删除）'
    done_task '已拒绝'; return 1
  fi
  [ -e "$_t" ] || { ng "路径不存在：$_t"; done_task '跳过'; return 1; }
  if mount 2>/dev/null | grep -q " $_t "; then ng '该路径是挂载点，拒绝删除'; done_task '已拒绝'; return 1; fi
  step '目标'
  run ls -ld "$_t"
  warn '递归删除不可恢复。'
  confirm_exact "确认递归删除 $_t 吗？" 'DELETE_PATH' || { printf '  已取消。\n'; return 0; }
  step '删除'
  run rm -rf "$_t"
  done_task '完成；请重启后再复测。'
}

# ---- 复制任意脚本到 /data/adb/service.d ----
copy_script_to_service_d(){
  begin_task '复制脚本到 /data/adb/service.d' 'service.d 管理' '—' '高' '是'
  warn '开机脚本若写坏（死循环/反复重启/删关键文件），可能导致无法正常开机。'
  info '常用于把 service.sh / shamiko.sh 之类放到开机执行目录。'
  read_line '输入源文件路径（如 /sdcard/service.sh）：' ''
  _src="$JB_ANSWER"
  case "$_src" in
    ''|*[!A-Za-z0-9_./\:-]*) ng '路径含不允许的字符'; done_task '跳过'; return 1 ;;
  esac
  [ -f "$_src" ] || { ng "文件不存在：$_src"; done_task '跳过'; return 1; }
  [ -d "$SERVICE_D" ] || { ng "$SERVICE_D 不存在（当前管理器可能不支持 service.d）"; done_task '跳过'; return 1; }
  step '内容体检'
  _sz="$(wc -c <"$_src" 2>/dev/null | tr -d ' ')"
  case "$_sz" in ''|*[!0-9]*) _sz=0 ;; esac
  pln "        大小：$_sz 字节"
  if [ "$_sz" -gt 65536 ]; then ng '文件过大（>64KB），拒绝写入开机目录'; done_task '已拒绝'; return 1; fi
  if grep -qE 'while[[:space:]]+(true|:)|for[[:space:]]*\(' "$_src" 2>/dev/null; then
    warn '检测到可能是无限循环的写法（while true / for(;;)）——开机阶段死循环会拖住启动'
  fi
  if grep -qE '(^|[^a-zA-Z_])reboot([^a-zA-Z_]|$)|rm -rf /[[:space:]]*(;|$)|rm -rf /\*' "$_src" 2>/dev/null; then
    warn '检测到 reboot / rm -rf / 一类危险写法，请务必确认这不是恶意或错误脚本'
  fi
  run sh -n "$_src"
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认把该脚本放到开机执行目录吗？' 'SERVICE_D_OK' || { printf '  已取消。\n'; return 0; }
  fi
  read_line "目标文件名（默认 $(basename "$_src")）：" "$(basename "$_src")"
  _dst="$SERVICE_D/$JB_ANSWER"
  case "$_dst" in *[!A-Za-z0-9_./-]*) ng '目标文件名不合法'; done_task '跳过'; return 1 ;; esac
  step "备份并写入 $_dst"
  backup_path "$_dst"
  run cp "$_src" "$_dst"
  run chown root:root "$_dst"
  run chmod 755 "$_dst"
  run restorecon "$_dst"
  step '结果'
  run ls -lZ "$_dst"
  warn "若开机异常：用 MT 安全模式，或在 recovery 里删除 $_dst 后重启即可恢复。"
  done_task '重启后由 Root 管理器在开机阶段执行。'
}

# ---- 自动体检：把本机可判定的问题映射到菜单序号 ----
f_auto_scan(){
  begin_task '自动体检：列出本机可自动修复的项' '通用排查方法' '34（说明与反馈）' '只读' '否'
  _lst="$JB_TMP/autoscan.$$"
  auto_detect_list "$_lst"
  step '检查本地可判定状态'
  if [ ! -s "$_lst" ]; then
    ok '未发现可自动修复的状态'
  else
    _an=0
    exec 3<"$_lst"
    while IFS='|' read -r _n _r <&3; do
      printf '        %s —— %s\n' "$(auto_label "$_n")" "$_r"
      _an=$((_an + 1))
    done
    exec 3<&-
    info "共 $_an 条建议；输入 a 可让本工具自动执行其中的低风险项。"
  fi
  [ -d "$TS" ] || printf '        （未检测到 tricky_store，14~18 项需先安装密钥模块）\n'
  done_task '完成。'
}

# ---- 来源提示（酷安；仅为渠道线索，不是完整性校验）----
source_provenance_hint(){
  has_cmd pm || return 0
  _spv_hit=0
  if pm path "$JB_SOURCE_COOLAPK" >/dev/null 2>&1 || pm list packages 2>/dev/null | grep -qi 'coolapk'; then
    info '来源提示：本机安装了酷安（本工具的发布渠道之一）'; _spv_hit=1
  fi
  [ "$_spv_hit" = 1 ] && info '以上仅为来源线索，不是加密完整性校验；完整性以本脚本 SHA-256 为准。'
  return 0
}

# ---- 内置 Inode-Hijacker（MIT，作者 YiJieqwq 异界；官方 v2.3.1 release 资产）----
cleanup_inode_payload(){
  case "$1" in "$JB_INODE_RUNTIME"/.inode-hijacker-v2.3.1.*) rm -f "$1" 2>/dev/null ;; esac
}
verify_inode_payload(){
  _h="$(sha256_file "$1" 2>/dev/null)"
  if [ -z "$_h" ]; then ng '无法校验内嵌 Inode-Hijacker 的 SHA-256'; return 2; fi
  if [ "$_h" = "$JB_INODE_SHA" ]; then ok "内嵌 Inode-Hijacker 校验通过（$_h）"; return 0; fi
  ng "内嵌文件校验不匹配：期望 $JB_INODE_SHA / 实际 $_h"
  return 1
}
#@@PAYLOAD-ALLOW-BEGIN
extract_inode_payload(){
  mkdir -p "$JB_INODE_RUNTIME" 2>/dev/null || return 1
  chmod 700 "$JB_INODE_RUNTIME" 2>/dev/null || return 1
  _ip="$(mktemp "$JB_INODE_RUNTIME/.inode-hijacker-v2.3.1.XXXXXX" 2>/dev/null)" || return 1
  chmod 600 "$_ip" 2>/dev/null || { rm -f "$_ip"; return 1; }
  cat > "$_ip" <<'__JB_INODE_HIJACKER_V2_3_1__'
#!/system/bin/sh
# -------------------- 第三方许可声明（随副本保留） --------------------
# 本文件是 Inode-Hijacker v2.3.1（作者 YiJieqwq）的副本，仓库：
#   https://github.com/YiJieqwq/Inode-Hijacker
# 按 MIT 许可要求，版权声明与许可声明全文随本副本一并保留，全文如下：
#
# MIT License
#
# Copyright (c) 2026 YiJieqwq
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ------------------------------ 许可声明结束 ------------------------------
# shellcheck disable=SC3037,SC2012
# ============================================================
#  Inode Hijacker v2.3.1 — 数据保留、SELinux 严格校验、安全分级
#  作者: YiJieqwq异界 基于 MIT 协议开源
#  项目链接: https://github.com/YiJieqwq/Inode-Hijacker
# ============================================================

TOYBOX="/system/bin/toybox"

TARGET_INPUT="${1:-/data/local/tmp}"
MAX_INODE="${2:-10000}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
DIM='\033[2m'

TMP_SAFE=""; TMP_CAUT=""; TMP_UNKN=""
TX_DIR=""; TARGET_PAYLOAD=""; DONOR_PAYLOAD=""
CHOSEN_DIR=""; STATE=0

say_error() { echo -e "${RED}[✗] $*${NC}" >&2; }
warn()      { echo -e "${YELLOW}[!] $*${NC}" >&2; }

die() {
    say_error "$*"
    exit 1
}

cleanup_lists() {
    rm -f "$TMP_SAFE" "$TMP_CAUT" "$TMP_UNKN" 2>/dev/null || true
}

# 使用 toybox `mv -x` 的原子 RENAME_EXCHANGE，禁止普通 mv 的 copy+delete 回退。
# 先在目标位置创建同类型占位项，再交换两个 inode，最后删除原位置的占位项。
exchange_paths() {
    _left="$1"; _right="$2"
    "$TOYBOX" mv -x "$_left" "$_right"
}

move_one_nocopy() {
    _src_entry="$1"; _dst_dir="$2"
    _base="${_src_entry##*/}"
    _placeholder="${_dst_dir}/${_base}"

    if [ -L "$_src_entry" ]; then
        ln -s . "$_placeholder" || return 1
    elif [ -d "$_src_entry" ]; then
        mkdir "$_placeholder" || return 1
    elif [ -f "$_src_entry" ]; then
        : > "$_placeholder" || return 1
    elif [ -p "$_src_entry" ]; then
        mkfifo "$_placeholder" || return 1
    else
        say_error "不支持的目录项类型: $_src_entry"
        return 1
    fi

    if ! exchange_paths "$_src_entry" "$_placeholder"; then
        rm -rf "$_placeholder" 2>/dev/null || true
        return 1
    fi
    rm -rf "$_src_entry" || return 1
    return 0
}

# 移动目录中的全部直接子项，兼容普通文件、隐藏文件、目录、FIFO 和符号链接。
# 每个条目均使用 RENAME_EXCHANGE；绝不允许 cp/unlink 退化路径。
move_entries() {
    _src="$1"; _dst="$2"
    for _entry in "$_src"/* "$_src"/.[!.]* "$_src"/..?*; do
        [ -e "$_entry" ] || [ -L "$_entry" ] || continue
        move_one_nocopy "$_entry" "$_dst" || return 1
    done
    return 0
}

get_ctx() {
    _ctx=$(ls -Zd "$1" 2>/dev/null | awk '{print $1}') || true
    echo "${_ctx:-unknown}"
}

restore_ctx_checked() {
    _path="$1"; _expected="$2"
    echo -e "  ${DIM}restorecon -F $_path${NC}"
    if ! restorecon -F "$_path"; then
        say_error "restorecon 失败: $_path"
        return 1
    fi
    _actual=$(get_ctx "$_path")
    if [ "$_actual" != "$_expected" ]; then
        say_error "SELinux 上下文不匹配: $_path"
        echo "      expected: $_expected" >&2
        echo "      actual:   $_actual" >&2
        return 1
    fi
    return 0
}

apply_root_metadata() {
    _path="$1"; _mode="$2"; _uid="$3"; _gid="$4"; _ctx="$5"
    chown "${_uid}:${_gid}" "$_path" || return 1
    chmod "$_mode" "$_path" || return 1
    restore_ctx_checked "$_path" "$_ctx" || return 1
    return 0
}

# STATE=1：target/donor 根目录仍在原位，内容位于事务目录。
# STATE=2：两个根 inode 已交换，内容仍位于事务目录。
rollback() {
    [ "$STATE" -eq 0 ] && return 0
    warn "正在回滚未提交事务…"

    if [ "$STATE" -eq 2 ]; then
        if exchange_paths "$TARGET" "$CHOSEN_DIR"; then
            STATE=1
        else
            say_error "根目录原子交换回滚失败。请勿重启或删除事务目录：$TX_DIR"
            return 1
        fi
    fi

    if [ "$STATE" -eq 1 ]; then
        move_entries "$TARGET_PAYLOAD" "$TARGET" || {
            say_error "目标内容回滚失败，剩余数据保留在：$TARGET_PAYLOAD"
            return 1
        }
        move_entries "$DONOR_PAYLOAD" "$CHOSEN_DIR" || {
            say_error "捐献者内容回滚失败，剩余数据保留在：$DONOR_PAYLOAD"
            return 1
        }
        apply_root_metadata "$TARGET" "$OLD_PERM" "$OLD_UID" "$OLD_GID" "$OLD_CTX" || true
        apply_root_metadata "$CHOSEN_DIR" "$DONOR_PERM" "$DONOR_UID" "$DONOR_GID" "$DONOR_CTX" || true
        STATE=0
    fi
    return 0
}

on_signal() {
    echo "" >&2
    rollback || true
    die "操作被中断"
}

finish() {
    cleanup_lists
    if [ "$STATE" -eq 0 ] && [ -n "$TX_DIR" ]; then
        rm -rf "$TX_DIR" 2>/dev/null || true
    elif [ "$STATE" -ne 0 ] && [ -n "$TX_DIR" ]; then
        warn "存在未完成事务，数据保留在：$TX_DIR"
    fi
}

trap 'on_signal' HUP INT TERM
trap 'finish' EXIT

# ======================== 风险知识库 ========================
# safe 仅用于经过精确名称审查、且运行时为空的低风险候选。
# 名称启发式永远只能进入 unknown，不再自动声称“安全”。
eval_risk() {
    _name="$1"
    case "$_name" in
        data|app|app-private|adb|media|media_rw|local|misc|system|system_ce|system_de|user|user_de|vendor|vendor_ce|vendor_de|misc_ce|misc_de)
            echo "forbidden:应用数据/Root/加密/多用户核心目录" ;;
        mediadrm|drm|unencrypted|property|security|dpm|apex|dalvik-cache|resource-cache|storage)
            echo "forbidden:密钥、策略、启动或系统核心目录" ;;
        anr|tombstones|rollback-observer|rollback-history)
            echo "forbidden:崩溃证据或系统回滚机制" ;;
        cota|oplus_lib|oppo_lib|opluscvtnvm)
            echo "forbidden:运营商配置、动态厂商库或 NVM 参数" ;;
        oplus_ota_package|sota_package)
            echo "cautious:OTA 暂存路径，仅可在无更新任务且目录为空时使用" ;;
        engineercamera|engineermode)
            echo "cautious:厂商工程/相机服务路径，不保证闲置" ;;
        theme_bak)
            echo "cautious:持久主题备份，不保证可重建" ;;
        logswitch)
            echo "cautious:日志状态/开关，可能被常驻服务读取" ;;
        ramdump|debug_log|oplusbootstats|persist_log)
            echo "cautious:日志或转储，可能正在写入或用于排障" ;;
        oplus_backup|oplus|app-metadata|preloads|preapps-lib|format_unclear)
            echo "cautious:厂商配置、预装数据或用途不充分明确" ;;
        log*|debug*|cache*|temp*|tmp*|*log*|*cache*|*bak*|*backup*|*temp*|*engineer*|*debug*|*dump*|*test*)
            echo "unknown:仅名称像日志/缓存/测试，不能证明安全" ;;
        *)
            echo "unknown:无设备级证据，请自行评估" ;;
    esac
}

# ======================== 前置检查 ========================
clear
echo -e "\n${BOLD}${CYAN}  ╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}  ║           Inode Hijacker v2.3.1            ║${NC}"
echo -e "${BOLD}${CYAN}  ║  保留原内容 · SELinux 严格校验 · 可回滚  ║${NC}"
echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════╝${NC}\n"

[ "$(id -u)" -eq 0 ] || die "需要 root 权限"
[ -x "$TOYBOX" ] || die "缺少 Android toybox: $TOYBOX"
"$TOYBOX" mv --help 2>&1 | grep -q -- '-x.*swap' || die "当前 toybox mv 不支持 -x 原子交换"
case "$MAX_INODE" in ''|*[!0-9]*) die "MAX_INODE 必须是正整数" ;; esac
[ "$MAX_INODE" -gt 0 ] 2>/dev/null || die "MAX_INODE 必须大于 0"

for _cmd in stat mkdir chmod chown ls awk grep restorecon getenforce mountpoint readlink mktemp ln mkfifo rm; do
    command -v "$_cmd" >/dev/null 2>&1 || die "缺少必要命令: $_cmd"
done

[ -L "$TARGET_INPUT" ] && die "目标不能是符号链接: $TARGET_INPUT"
[ -d "$TARGET_INPUT" ] || die "目标目录不存在: $TARGET_INPUT"
TARGET=$(readlink -f "$TARGET_INPUT" 2>/dev/null) || die "无法解析目标路径"
case "$TARGET" in /data/*) ;; *) die "目标必须位于 /data 下" ;; esac
[ "$TARGET" != "/data" ] || die "禁止操作 /data 根目录"
mountpoint -q "$TARGET" 2>/dev/null && die "目标是挂载点，拒绝操作"

SELINUX_MODE=$(getenforce 2>/dev/null || echo Disabled)
[ "$SELINUX_MODE" != "Disabled" ] || die "SELinux 不可用或已禁用，无法验证上下文"
[ -d /sys/fs/selinux ] || die "SELinux 文件系统不可用"

CURRENT_INODE=$(stat -c '%i' "$TARGET" 2>/dev/null) || die "无法获取目标 inode"
TARGET_DEV=$(stat -c '%d' "$TARGET" 2>/dev/null) || die "无法获取目标文件系统"
echo -e " 目标: ${CYAN}${TARGET}${NC}"
echo -e " inode: ${YELLOW}${CURRENT_INODE}${NC}   SELinux: ${YELLOW}${SELINUX_MODE}${NC}"

[ "$CURRENT_INODE" -le "$MAX_INODE" ] && {
    echo -e " ${GREEN}[✓]${NC} inode 已 ≤ ${MAX_INODE}，无需操作\n"
    exit 0
}

WORK_DIR=$(dirname "$TARGET")
TMP_SAFE=$(mktemp "${WORK_DIR}/.hijack_safe.XXXXXX") || die "无法创建候选清单"
TMP_CAUT=$(mktemp "${WORK_DIR}/.hijack_caut.XXXXXX") || die "无法创建候选清单"
TMP_UNKN=$(mktemp "${WORK_DIR}/.hijack_unkn.XXXXXX") || die "无法创建候选清单"
chmod 600 "$TMP_SAFE" "$TMP_CAUT" "$TMP_UNKN" || die "无法保护候选清单"

# ======================== 扫描与分级 ========================
SAFE_COUNT=0; CAUTIOUS_COUNT=0; FORBIDDEN_COUNT=0; UNKNOWN_COUNT=0; global_idx=0
BEST_IDX=""; BEST_INODE=""; BEST_NAME=""; _bestscore=""

for dir in /data/*/; do
    [ -d "$dir" ] || continue
    [ -L "$dir" ] && continue
    dir="${dir%/}"; name="${dir##*/}"
    [ "$dir" = "$TARGET" ] && continue
    case "$TARGET" in "$dir"/*) continue ;; esac
    mountpoint -q "$dir" 2>/dev/null && continue

    _dev=$(stat -c '%d' "$dir" 2>/dev/null) || continue
    [ "$_dev" = "$TARGET_DEV" ] || continue
    inode=$(stat -c '%i' "$dir" 2>/dev/null) || continue
    case "$inode" in ''|*[!0-9]*) continue ;; esac
    [ "$inode" -le "$MAX_INODE" ] || continue

    [ -z "$(ls -A "$dir" 2>/dev/null)" ] && is_empty=1 || is_empty=0
    risk_info=$(eval_risk "$name")
    risk="${risk_info%%:*}"; desc="${risk_info#*:}"

    [ "$risk" = "forbidden" ] && {
        FORBIDDEN_COUNT=$((FORBIDDEN_COUNT + 1))
        continue
    }

    global_idx=$((global_idx + 1))
    case "$risk" in
        safe) SAFE_COUNT=$((SAFE_COUNT + 1)); _file="$TMP_SAFE"; _base=300 ;;
        cautious) CAUTIOUS_COUNT=$((CAUTIOUS_COUNT + 1)); _file="$TMP_CAUT"; _base=200 ;;
        *) UNKNOWN_COUNT=$((UNKNOWN_COUNT + 1)); _file="$TMP_UNKN"; _base=100 ;;
    esac
    echo "${global_idx}|${inode}|${name}|${is_empty}|${desc}|${risk}" >> "$_file"

    # 仅推荐 cautious/safe 的空目录；unknown 只展示，不作为回车默认值。
    if [ "$risk" != "unknown" ] && [ "$is_empty" -eq 1 ]; then
        _finalscore=$((_base * 1000000 - inode))
        if [ -z "$_bestscore" ] || [ "$_finalscore" -gt "$_bestscore" ]; then
            _bestscore="$_finalscore"; BEST_IDX="$global_idx"
            BEST_INODE="$inode"; BEST_NAME="$name"
        fi
    fi
done

print_entry() {
    _idx="$1"; _inode="$2"; _name="$3"; _empty="$4"; _icon="$5"; _color="$6"; _tag="$7"
    printf "  %b %b[%2s]%b  %-8s  %b%-30s%b" "$_icon" "$CYAN" "$_idx" "$NC" "$_inode" "$_color" "/data/$_name" "$NC"
    [ "$_empty" -eq 1 ] && printf '  %b[空]%b' "$GREEN" "$NC" || printf '  %b[有内容，将事务迁移]%b' "$YELLOW" "$NC"
    printf "  ${DIM}%s${NC}\n" "$_tag"
}

[ "$CAUTIOUS_COUNT" -gt 0 ] && {
    echo -e "\n  ${BOLD}${YELLOW}═══ 谨慎候选 ═══${NC}"
    while IFS='|' read -r idx inode name empty desc risk; do
        print_entry "$idx" "$inode" "$name" "$empty" "${YELLOW}●${NC}" "$YELLOW" "$desc"
    done < "$TMP_CAUT"
}
[ "$UNKNOWN_COUNT" -gt 0 ] && {
    echo -e "\n  ${BOLD}${BLUE}═══ 未知候选（不会自动推荐）═══${NC}"
    while IFS='|' read -r idx inode name empty desc risk; do
        print_entry "$idx" "$inode" "$name" "$empty" "${BLUE}○${NC}" "$NC" "$desc"
    done < "$TMP_UNKN"
}
[ "$FORBIDDEN_COUNT" -gt 0 ] && echo -e "\n  ${DIM}${RED}已排除 ${FORBIDDEN_COUNT} 个关键/危险目录${NC}"

total=$((SAFE_COUNT + CAUTIOUS_COUNT + UNKNOWN_COUNT))
[ "$total" -gt 0 ] || die "未找到候选目录"

echo -e "\n  ${BOLD}───────────────${NC}"
if [ -n "$BEST_IDX" ]; then
    echo -e "  ${BOLD}${GREEN}★ 默认候选:${NC} ${CYAN}[${BEST_IDX}] /data/${BEST_NAME}${NC}  inode ${YELLOW}${BEST_INODE}${NC}"
    echo -n "  选择序号 (直接回车 = 默认候选): "
else
    warn "没有可自动推荐的空谨慎候选；必须手动选择并承担设备级风险"
    echo -n "  选择序号 (直接回车 = 取消): "
fi
read -r CHOICE
[ -z "$CHOICE" ] && CHOICE="$BEST_IDX"
[ -n "$CHOICE" ] || die "已取消"

CHOSEN_INODE=""; CHOSEN_NAME=""; CHOSEN_RISK=""; CHOSEN_EMPTY=""
for _f in "$TMP_SAFE" "$TMP_CAUT" "$TMP_UNKN"; do
    [ -s "$_f" ] || continue
    while IFS='|' read -r _idx _ino _name _empty _desc _risk; do
        if [ "$_idx" = "$CHOICE" ]; then
            CHOSEN_INODE="$_ino"; CHOSEN_NAME="$_name"
            CHOSEN_EMPTY="$_empty"; CHOSEN_RISK="$_risk"
            break 2
        fi
    done < "$_f"
done
[ -n "$CHOSEN_NAME" ] || die "无效序号: $CHOICE"
CHOSEN_DIR="/data/${CHOSEN_NAME}"

# 执行前二次验证，防止扫描后路径被替换。
if [ ! -d "$CHOSEN_DIR" ] || [ -L "$CHOSEN_DIR" ]; then
    die "候选类型已变化"
fi
[ "$(stat -c '%i' "$CHOSEN_DIR" 2>/dev/null)" = "$CHOSEN_INODE" ] || die "候选 inode 已变化，请重试"
[ "$(stat -c '%d' "$CHOSEN_DIR" 2>/dev/null)" = "$TARGET_DEV" ] || die "候选不在同一文件系统"
mountpoint -q "$CHOSEN_DIR" 2>/dev/null && die "候选变成了挂载点"

OLD_PERM=$(stat -c '%a' "$TARGET") || die "读取目标权限失败"
OLD_UID=$(stat -c '%u' "$TARGET") || die "读取目标 UID 失败"
OLD_GID=$(stat -c '%g' "$TARGET") || die "读取目标 GID 失败"
OLD_CTX=$(get_ctx "$TARGET")
DONOR_PERM=$(stat -c '%a' "$CHOSEN_DIR") || die "读取候选权限失败"
DONOR_UID=$(stat -c '%u' "$CHOSEN_DIR") || die "读取候选 UID 失败"
DONOR_GID=$(stat -c '%g' "$CHOSEN_DIR") || die "读取候选 GID 失败"
DONOR_CTX=$(get_ctx "$CHOSEN_DIR")
case "$OLD_CTX:$DONOR_CTX" in *unknown*|*unlabeled*) die "无法可靠读取原始 SELinux 上下文" ;; esac

# 先用 restorecon 做无副作用的可用性验证：原上下文必须与当前策略一致。
restore_ctx_checked "$TARGET" "$OLD_CTX" || die "目标 SELinux 预检失败"
restore_ctx_checked "$CHOSEN_DIR" "$DONOR_CTX" || die "候选 SELinux 预检失败"

if [ "$CHOSEN_RISK" = "unknown" ] || [ "$CHOSEN_EMPTY" -eq 0 ]; then
    warn "所选目录为 ${CHOSEN_RISK}，或包含内容；脚本会保留内容，但无法证明厂商服务当前未使用它"
fi

echo -e "\n  ${RED}━━━ 最终确认 ━━━${NC}"
echo -e "  目标: ${CYAN}${TARGET}${NC}  inode ${YELLOW}${CURRENT_INODE}${NC}"
echo -e "  候选: ${CYAN}${CHOSEN_DIR}${NC}  inode ${YELLOW}${CHOSEN_INODE}${NC}  风险=${YELLOW}${CHOSEN_RISK}${NC}"
echo -e "  ${YELLOW}两个目录的原内容都会保留；目录 inode、根权限和根 SELinux context 会交换后恢复。${NC}"
echo -n "  输入大写 SWAP 继续: "
read -r confirm
[ "$confirm" = "SWAP" ] || die "已取消"

# ======================== 事务交换 ========================
TX_DIR=$(mktemp -d "${WORK_DIR}/.inode_hijacker.XXXXXX") || die "无法创建事务目录"
chmod 700 "$TX_DIR" || die "无法保护事务目录"
TARGET_PAYLOAD="$TX_DIR/target_payload"
DONOR_PAYLOAD="$TX_DIR/donor_payload"
mkdir "$TARGET_PAYLOAD" "$DONOR_PAYLOAD" || die "无法初始化事务目录"
chmod 700 "$TARGET_PAYLOAD" "$DONOR_PAYLOAD" || die "无法保护事务内容"

# 在碰触真实目录前验证 RENAME_EXCHANGE，避免任何 copy+delete 退化。
_EX_A="$TX_DIR/.exchange_test_a"; _EX_B="$TX_DIR/.exchange_test_b"
mkdir "$_EX_A" "$_EX_B" || die "无法创建原子交换测试目录"
_EX_A_INO=$(stat -c '%i' "$_EX_A") || die "无法读取测试 inode"
_EX_B_INO=$(stat -c '%i' "$_EX_B") || die "无法读取测试 inode"
if ! exchange_paths "$_EX_A" "$_EX_B" \
    || [ "$(stat -c '%i' "$_EX_A" 2>/dev/null)" != "$_EX_B_INO" ] \
    || [ "$(stat -c '%i' "$_EX_B" 2>/dev/null)" != "$_EX_A_INO" ]; then
    die "toybox mv -x/RENAME_EXCHANGE 自检失败，未修改目标目录"
fi
rm -rf "$_EX_A" "$_EX_B" || die "无法清理原子交换测试目录"

echo -e "\n  ${YELLOW}[▶]${NC} 暂存两个目录的原内容（RENAME_EXCHANGE，不复制）…"
STATE=1
move_entries "$TARGET" "$TARGET_PAYLOAD" || {
    rollback || true
    die "暂存目标内容失败"
}
move_entries "$CHOSEN_DIR" "$DONOR_PAYLOAD" || {
    rollback || true
    die "暂存候选内容失败"
}
# 若此时又出现新条目，说明有并发进程正在写入；不冒险继续交换。
if [ -n "$(ls -A "$TARGET" 2>/dev/null)" ] || [ -n "$(ls -A "$CHOSEN_DIR" 2>/dev/null)" ]; then
    rollback || true
    die "检测到并发写入，请停止相关服务后重试"
fi

# 再次确认空根目录 inode，随后使用 RENAME_EXCHANGE 原子交换。
[ "$(stat -c '%i' "$TARGET")" = "$CURRENT_INODE" ] || { rollback; die "目标 inode 在事务中变化"; }
[ "$(stat -c '%i' "$CHOSEN_DIR")" = "$CHOSEN_INODE" ] || { rollback; die "候选 inode 在事务中变化"; }

if ! exchange_paths "$TARGET" "$CHOSEN_DIR"; then
    rollback || true
    die "根目录原子交换失败；设备可能不支持 toybox mv -x/RENAME_EXCHANGE"
fi
STATE=2

# 内容仍隔离时恢复并严格验证两个根目录，失败可完整交换回去。
echo -e "  ${YELLOW}[▶]${NC} 恢复根目录权限与 SELinux 上下文…"
if ! apply_root_metadata "$TARGET" "$OLD_PERM" "$OLD_UID" "$OLD_GID" "$OLD_CTX" \
    || ! apply_root_metadata "$CHOSEN_DIR" "$DONOR_PERM" "$DONOR_UID" "$DONOR_GID" "$DONOR_CTX"; then
    rollback || true
    die "元数据或 SELinux 恢复失败，已尝试回滚"
fi

# 子项以 rename 返回原路径，保留自身 inode、uid/gid、mode、SELinux xattr 和其他 xattr。
echo -e "  ${YELLOW}[▶]${NC} 恢复两个目录的原内容…"
if ! move_entries "$TARGET_PAYLOAD" "$TARGET"; then
    say_error "目标内容恢复不完整；为避免删除数据，事务目录予以保留：$TX_DIR"
    die "请勿重启，检查目标目录与 target_payload 后手动恢复"
fi
if ! move_entries "$DONOR_PAYLOAD" "$CHOSEN_DIR"; then
    say_error "候选内容恢复不完整；为避免删除数据，事务目录予以保留：$TX_DIR"
    die "请勿重启，检查候选目录与 donor_payload 后手动恢复"
fi

FINAL_INODE=$(stat -c '%i' "$TARGET" 2>/dev/null) || die "无法读取最终 inode"
FINAL_CTX=$(get_ctx "$TARGET")
DONOR_FINAL_CTX=$(get_ctx "$CHOSEN_DIR")
[ "$FINAL_INODE" = "$CHOSEN_INODE" ] || die "最终 inode 校验失败"
[ "$FINAL_CTX" = "$OLD_CTX" ] || die "目标最终 SELinux 校验失败"
[ "$DONOR_FINAL_CTX" = "$DONOR_CTX" ] || die "候选最终 SELinux 校验失败"

STATE=0
sync 2>/dev/null || true

echo -e "\n  ${BOLD}${GREEN}╔════════════════════════════╗${NC}"
echo -e "  ${BOLD}${GREEN}║       操作完成并验证 ✓     ║${NC}"
echo -e "  ${BOLD}${GREEN}╚════════════════════════════╝${NC}\n"
echo -e "  inode:   ${RED}${CURRENT_INODE}${NC} → ${GREEN}${FINAL_INODE}${NC}"
echo -e "  目标 ctx: ${GREEN}${FINAL_CTX}${NC}"
echo -e "  候选 ctx: ${GREEN}${DONOR_FINAL_CTX}${NC}"
echo -e "  原内容:  ${GREEN}已通过同分区 rename 保留${NC}\n"
__JB_INODE_HIJACKER_V2_3_1__
  [ -s "$_ip" ] || { rm -f "$_ip"; return 1; }
  write_third_party_notice "$JB_INODE_RUNTIME/Inode-Hijacker-NOTICE.txt" 2>/dev/null || true
  printf '%s\n' "$_ip"
}
#@@PAYLOAD-ALLOW-END
run_embedded_inode(){
  begin_task '运行内置 Inode-Hijacker（设备级 inode 交换）' 'Suspicious Surroundings（b）' '879' '高' '是'
  [ -d /data/local/tmp ] || { warn '/data/local/tmp 不存在'; done_task '跳过'; return 1; }
  step '读取当前 inode（判据 >10000）'
  _ino="$(stat -c '%i' /data/local/tmp 2>/dev/null)"
  case "$_ino" in ''|*[!0-9]*) ng '无法读取 inode'; done_task '失败'; return 1 ;; esac
  printf '        当前 inode = %s\n' "$_ino"
  if [ "$_ino" -le 10000 ]; then
    info '未达到 >10000 的判据，不执行设备级目录交换（避免无意义的设备级改动）'
    info '其他思路：① 恢复出厂；② 内核级隐藏把该路径 inode 伪装到 1000 以下。'
    done_task '完成。'
    return 0
  fi
  step '提取内置脚本并校验 SHA-256'
  _p="$(extract_inode_payload)" || { ng '提取失败'; done_task '失败'; return 1; }
  printf '        运行时路径：%s\n' "$_p"
  if ! verify_inode_payload "$_p"; then cleanup_inode_payload "$_p"; done_task '已拒绝执行'; return 1; fi
  step '前置安全检查与备份'
  if mount 2>/dev/null | grep -q ' /data/local/tmp '; then
    warn '/data/local/tmp 是独立挂载点，本项不做设备级 inode 交换'
    cleanup_inode_payload "$_p"; done_task '已拒绝'; return 1
  fi
  _bak="$JB_INODE_RUNTIME/pre-tmp-$(date +%Y%m%d-%H%M%S)"
  run mkdir -p "$_bak"
  if run cp -a /data/local/tmp/. "$_bak/" || run cp -R /data/local/tmp/. "$_bak/"; then
    ok "已备份 /data/local/tmp -> $_bak（失败时可从这里取回）"
  else
    warn "备份失败：$_bak（继续执行风险更高，建议先手动备份）"
  fi
  warn '它会交换 /data/local/tmp 与同分区候选目录的 inode；失败可能需要救砖。' 

  confirm_exact '第一次确认：已备份 boot/重要数据并接受卡开机/数据不可用风险' 'INODE_HIJACKER' || { cleanup_inode_payload "$_p"; printf '  已取消。\n'; return 0; }
  step '记录元数据备份'
  _bk="$JB_BASE/backup/$(date +%Y%m%d-%H%M%S)_inode-hijacker.metadata"
  mkdir -p "$JB_BASE/backup" 2>/dev/null
  {
    printf 'target=/data/local/tmp\ninode=%s\nmode=%s\nuid=%s\ngid=%s\n' \
      "$_ino" "$(stat -c '%a' /data/local/tmp 2>/dev/null)" "$(stat -c '%u' /data/local/tmp 2>/dev/null)" "$(stat -c '%g' /data/local/tmp 2>/dev/null)"
    printf 'script=%s\nruntime_path=%s\nsha256=%s\n' "$JB_INODE_VER" "$_p" "$JB_INODE_SHA"
  } > "$_bk" 2>/dev/null && ok "已保存：$_bk"
  step '执行（该脚本内部还会再次要求确认；交互提示直接来自它）'
  if [ "$DRY_RUN" = 1 ]; then info '[演练模式] 跳过执行'; cleanup_inode_payload "$_p"; done_task '演练完成'; return 0; fi
  if sh "$_p" /data/local/tmp 10000; then
    cleanup_inode_payload "$_p"
    done_task '执行结束：请重启后复测；若有线投屏异常，用 41) restorecon 项恢复。'
  else
    cleanup_inode_payload "$_p"
    warn '返回失败：请保留其事务目录并按提示处理，不要重复执行。'
    done_task '失败。'
  fi
}

# ---------------------------------------------------------------------
# 15. 菜单（以春秋检测词条为选项，格式：修复（词条名称））
# ---------------------------------------------------------------------
page_header(){
  hr
  printf '  %s v%s   作者：%s\n' "$JB_NAME" "$JB_VER" "$JB_AUTHOR"
  _ph1="ROOT=$([ "$(id -u 2>/dev/null)" = 0 ] && printf '是' || printf '否')  管理器=$(root_manager)  resetprop=$RP_DESC"
  _sd_state="$([ -d "$SERVICE_D" ] && printf '有' || printf '无')"   # 仍检测 service.d，仅不在页头显示
  _ph2="tricky_store=$([ -d "$TS" ] && printf '有' || printf '无')"
  if [ "$JB_WIDTH" -ge 66 ]; then
    printf '  %s  %s\n' "$_ph1" "$_ph2"
  else
    printf '  %s\n' "$_ph1"
    printf '  %s\n' "$_ph2"
  fi
  hr
}

# 春秋检测包名：优先已知候选，其次模糊匹配（同族应用较多，允许手动指定）
detect_detector_pkg(){ printf '%s' "$JB_DETECTOR_PKG"; }

show_detector_pkg(){
  begin_task '核对春秋检测包名' '配置辅助（target.txt / 清数据）' '—' '只读' '否'
  step "固定包名：$JB_DETECTOR_PKG"
  run sh -c "pm path '$JB_DETECTOR_PKG' 2>/dev/null || echo '(该包名未安装)'"
  run sh -c "pm list packages 2>/dev/null | grep -F 'package:$JB_DETECTOR_PKG' || echo '(列表中也未找到)'"
  info '包名已在脚本内固定，不再做模糊匹配；若检测器为其它包名，请自行改脚本内 JB_DETECTOR_PKG。'
  done_task '该包名用于「16) 修复（TEE 损坏）」的 target.txt 与「25) 修复（内存异常）」。'
}

clear_detector_data(){
  begin_task '清除春秋检测数据' '内存异常' '761' '中' '否'
  _p="${JB_DETECTOR_PKG:-$(detect_detector_pkg)}"
  if [ -z "$_p" ]; then ng '未识别到包名，请先执行「工具（识别春秋检测包名）」'; done_task '跳过'; return 0; fi
  step "目标包名：$_p"
  run sh -c "pm list packages 2>/dev/null | grep -F 'package:$_p' || echo '(该包名未安装)'"
  warn '会清除检测器自身数据（等于重置检测结果），不是环境修复；仅用于排除残留。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact "确认清除 $_p 的数据吗？" 'CLEAR' || { printf '  已取消。\n'; return 0; }
  fi
  step '执行 pm clear'
  run pm clear "$_p"
  done_task '完成后重新打开检测器复测。'
}

# ---- 修复（Dirty Device(a)）：扫描 + 逐条清理 /sdcard 下名称含 sh 的项 ----
f_dirty_scan_only(){
  begin_task '扫描 /sdcard 下名称含 sh 的文件/目录' 'Dirty Device(a)' '781' '只读' '否'
  _lst="$JB_TMP/shlist.$$"
  find /sdcard -maxdepth 3 -name '*sh*' 2>/dev/null \
    | grep -vE '/Android/|/DCIM/|/Pictures/|/Movies/|/Music/|/\.thumbnails/|/JinBeiChunQiuFixToolPro2/' \
    | head -n 50 >"$_lst"
  step '扫描结果（区分大小写；已排除 Android/DCIM/Pictures 等常见目录）'
  if [ ! -s "$_lst" ]; then info '未扫描到名称含 sh 的文件/目录'; done_task '完成'; return 0; fi
  exec 3<"$_lst"
  while IFS= read -r _x <&3; do printf '        %s\n' "$_x"; done
  exec 3<&-
  done_task '只读扫描；清理请选本词条的「按清单逐条清理」或 19) Dirty Device(a)。'
}
f_dirty_device(){
  begin_task '处理 /sdcard 下名称含 sh 的文件/目录' 'Dirty Device(a)' '781' '高' '是'
  _list="$JB_TMP/shlist.$$"
  step '扫描（最多 50 条）'
  find /sdcard -maxdepth 3 -name '*sh*' 2>/dev/null \
    | grep -vE '/Android/|/DCIM/|/Pictures/|/Movies/|/Music/|/\.thumbnails/|/JinBeiChunQiuFixToolPro2/' \
    | head -n 50 >"$_list"
  if [ ! -s "$_list" ]; then info '未扫描到名称含 sh 的文件/目录'; done_task '完成'; return 0; fi
  _cnt=0
  exec 3<"$_list"
  while IFS= read -r x <&3; do
    printf '        %s\n' "$x"
    _cnt=$((_cnt + 1))
  done
  exec 3<&-
  info "共 $_cnt 条（区分大小写；已排除 Android/DCIM/Pictures 等常见目录）。"
  pln '  默认做法：移动到 /data/adb 下的隔离目录（可恢复），而不是直接删除。'
  read_line '处理方式：1) 移动到隔离目录（默认，可恢复） 2) 直接删除 0) 取消' '1'
  case "$JB_ANSWER" in
    0|'') info '已取消'; done_task '完成'; return 0 ;;
    2) _delmode=1 ;;
    *) _delmode=0 ;;
  esac
  _qdir="$JB_QUARANTINE_ROOT/sh-quarantine/$(date +%Y%m%d-%H%M%S)"
  if [ "$_delmode" = 0 ]; then
    if [ "$DRY_RUN" = 1 ]; then info "[演练模式] 将移动到 $_qdir"; else mkdir -p "$_qdir" 2>/dev/null || { ng "无法创建隔离目录：$_qdir"; done_task '失败'; return 1; }; fi
  elif [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '直接删除不可恢复，确认吗？' 'DELETE' || { printf '  已取消。\n'; return 0; }
  fi
  _n=0
  exec 3<"$_list"
  while IFS= read -r p <&3; do
    [ -n "$p" ] || continue
    case "$p" in
      /sdcard/Android/*|/storage/emulated/0/Android/*) info "跳过应用数据：$p"; continue ;;
    esac
    if mount 2>/dev/null | grep -q " $p "; then warn "跳过挂载点：$p"; continue; fi
    if [ "$_delmode" = 1 ]; then
      printf '\n  发现：%s\n' "$p"
      if ask_yn '删除它？'; then run rm -rf "$p"; _n=$((_n + 1)); else info '已跳过'; fi
    else
      if run mv "$p" "$_qdir/"; then _n=$((_n + 1)); else warn "移动失败：$p"; fi
    fi
  done
  exec 3<&-
  if [ "$_delmode" = 1 ]; then
    done_task "已删除 $_n 条；请重启后再复测。"
  else
    done_task "已移动 $_n 条到 $_qdir（需要时从该目录取回）；请重启后再复测。"
  fi
}

# ---- 修复（环境伪造）：pihooks / pixelprops / spoof 属性残留清理 ----
f_env_fake(){
  begin_task '清理属性伪装残留' '环境伪造' '1214' '中' '否'
  step '扫描残留属性'
  _raw="$(getprop 2>/dev/null | grep -iE 'pihooks|pixelprops|spoof')"
  if [ -z "$_raw" ]; then info '未发现 pihooks / pixelprops / spoof 残留'; done_task '完成'; return 0; fi
  printf '%s\n' "$_raw" | while IFS= read -r l; do printf '        %s\n' "$l"; done
  warn '若属性由模块在开机阶段重写，本项会失效，需从模块侧处理。'
  if [ "$JB_ASSUME_YES" != 1 ]; then
    confirm_exact '确认逐条删除这些属性吗？' 'DELETE' || { printf '  已取消。\n'; return 0; }
  fi
  printf '%s\n' "$_raw" | sed 's/^\[\([^]]*\)\].*/\1/' | grep -v '^$' >"$JB_TMP/fakeprops.$$"
  _n=0
  exec 3<"$JB_TMP/fakeprops.$$"
  while IFS= read -r p <&3; do
    [ -n "$p" ] || continue
    printf '\n  删除属性：%s\n' "$p"
    rp --delete "$p"
    _n=$((_n + 1))
  done
  exec 3<&-
  done_task "已尝试删除 $_n 条属性；重启后复测。"
}

# ---- 同一个修复动作对应多个词条时的入口包装 ----
r_bootloader_unlock(){ ENTRY_NAME='Bootloader unlock / 解锁属性'; ENTRY_LINE='534'; f_lock_props; }
r_abnormal_boot(){ ENTRY_NAME='启动状态异常'; ENTRY_LINE='547'; f_lock_props; }
r_meta_family(){ ENTRY_NAME='/data/local/tmp 元数据异常族（Futile hide / 1 / 2 / 04 / 2222）'; ENTRY_LINE='703'; f_tmp_rebuild; }
r_tmp_denied(){ ENTRY_NAME='/data/local/tmp denied'; ENTRY_LINE='909'; f_tmp_rebuild; }
r_ts_aosp(){ ENTRY_NAME='AOSP密钥'; ENTRY_LINE='513'; f_ts_keybox; }
r_ts_crl(){ ENTRY_NAME='证书已被吊销(CRL)'; ENTRY_LINE='558'; f_ts_keybox; }

# ---- 修复（USB 调试已开启）用到的开机脚本写入 ----
write_usb_off_script(){
  if [ ! -d "$SERVICE_D" ]; then warn "$SERVICE_D 不存在，跳过开机脚本"; return 0; fi
  JB_OUT="$JB_TMP/usboff.$$"
  cat <<'SCRIPT_EOF' >"$JB_OUT"
#!/system/bin/sh
# JinBeiChunQiuFixToolPro2 - 开机自动关闭 USB 调试
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 60 ]; do
  sleep 2
  i=$((i + 1))
done
settings put global adb_enabled 0
SCRIPT_EOF
  _dst="$SERVICE_D/jb_usb_debug_off.sh"
  backup_path "$_dst"
  run cp "$JB_OUT" "$_dst"
  run chown root:root "$_dst"
  run chmod 755 "$_dst"
  run restorecon "$_dst"
  run sh -n "$_dst"
}

page_help(){
  hr
  printf '  使用说明 / 帮助\n'
  hr
  cat <<'EOF'
  MT 管理器怎么以 ROOT 运行
   1) 在 MT 设置里勾选 ROOT 权限（或顶栏/图标旁的 root 开关）；
   2) 长按本脚本 → 以 ROOT 运行 / 执行；
   3) 也可以在「MT 终端」里执行： sh /sdcard/JinBeiChunQiuFixToolPro2.sh

  选项就是春秋检测的词条
   · 修复类选项统一命名为： 修复（词条名称）
   · 输入序号回车即执行；支持一次多个，用空格或逗号分隔，例如： 8 9 10
   · 标〔子菜单〕的项进去后还有细分子项（14 / 20 / 24）
   · 标「高风险」的项会要求输入确认词（REBUILD / DELETE / TEMP_DISABLE_MODULES /
     INODE_HIJACKER / PID_WRAP_ZYGOTE / RESTART_ZYGOTE / SU_FIX / CLEAR /
     MOVE / RUN / REMOVE / RESTORE / RESTORE_MODULES / DELETE_PATH）
   · 每项按 [步骤 01/02…] 分步显示，改动前备份到
     /sdcard/JinBeiChunQiuFixToolPro2/backup/
   · 需重启的项会在任务结束时提示；属性类改动重启后可能失效

  显示与缩放
   · 主页只显示「修复项」栏目；其余（查看/扫描/诊断 + 工具）默认隐藏。
   · 输入 x 切换显示/隐藏这些栏目（隐藏时仍可直接输入其序号执行）。
   · 运行时自动读取终端列数并按该宽度排版，避免文字换行乱飞；
     检测不到宽度时默认按 80 列，并尝试把终端锁定为 80x40。
     也可用 --width N 或 JB_WIDTH_ENV=N 固定宽度。

  版本检测
   · 配置了更新源（JB_OFFICIAL_HASH_URL 或 --update-url）时，启动会做一次
     短超时检查，发现新版本只提示一行，不阻断、不自动覆盖自身。
   · 菜单 56) 工具（检测最新版本）可查看/下载；--check-update 可脚本化。

  使用统计（可选，默认关闭）
   · 只统计「有多少人用」：随机安装 ID + 版本 + 事件 + 本机运行次数。
   · 不采集设备信息；关闭后不发起任何统计请求。菜单 57 可查看/开关。

  快捷键
   s  自动体检（只读扫描，列出本机可修复项，= 菜单 39）
   a  自动修复（体检后自动执行其中的低风险项，其余列建议）
   p  依次执行 1~7（属性类）        t  依次执行 8~13（tmp 与挂载类）
   x  切换显示其他栏目             h  本帮助                        0  退出

  全自动词条（无需输入包名/路径/密钥，选序号即可）
   9   Suspicious Surroundings（b）：离线运行内置 Inode-Hijacker（自带 SHA-256 校验）
   14  Tampered Attestation Key(X)：补丁文件生成/删除/回滚 + 模块临时隔离/恢复
   20  异常文件：清单扫描/清理 + 按检测结果删除单个路径
   24  Property Modified：立即应用属性伪装 / 部署开机脚本 / 复制脚本到 service.d
   27  SU binary detected：/apex 内 su 执行位处理
   28  Found ksu/免解设备：PID 回绕 + Zygote 重启（实验性，高风险）

  启动流程
   ROOT 自检 → 脚本哈希与来源自检 → 法律声明 → 环境报告 → 词条修复菜单

  如何真正校验（推荐）
   · 在电脑或终端用独立工具核对原始文件摘要：
       sha256sum JinBeiChunQiuFixToolPro2.sh
     然后与发布页/仓库公布的「原始文件摘要」比对。
   · 或在手机上加参数运行，让脚本拿外部摘要来比：
       --verify <发布页摘要>      # 与原始文件或总哈希比对
       --verify-remote <url>      # 按《哈希云端校验·网站侧技术要求》拉清单比对
       --strict                   # 校验失败/拉不到就拒绝启动
       --allow-unverified         # 明确跳过校验（危险，仅自改副本用）
   · 内置的三个摘要（总哈希 / 分发区 / 内置载荷）只能防误改与漏签，
     不能防有决心的篡改——改脚本的人可以连摘要一起改。

  完整性自检怎么维护
   修改脚本后执行： sh 本脚本 --print-hash
   把输出的 64 位哈希写回脚本里的 SELF_SHA256='...' 那一行。
   内置的 Inode-Hijacker 载荷另有独立哈希（JB_INODE_SHA），运行前再次校验。

  命令行参数
   --self-test  只做自检与环境报告，不进菜单
   --dry-run    演练模式：只显示将执行什么，不真正执行
   --fast       关闭逐步骤暂停        --step 强制逐步骤暂停
   --yes        跳过各类确认（危险）  --accept-license 跳过协议确认
   --no-color   关闭彩色              --clear 每个菜单前清屏
EOF
  hr
}


# ---- 词条子菜单：Tampered Attestation Key(X) ----
f_ts_patch_rollback(){
  begin_task '从备份回滚 security_patch.txt' 'Tampered Attestation Key(X)（含 16 / 31）' '433' '中' '是'
  need_ts || { done_task '前置条件不满足'; return 0; }
  step '查找备份'
  _lst="$JB_TMP/patchbk.$$"
  find "$JB_BASE/backup" -type f -name 'security_patch.txt' 2>/dev/null | sort >"$_lst"
  if [ ! -s "$_lst" ]; then info '没有找到 security_patch.txt 备份'; done_task '完成'; return 0; fi
  _i=1
  exec 3<"$_lst"
  while IFS= read -r _b <&3; do printf '        %s. %s\n' "$_i" "$_b"; _i=$((_i + 1)); done
  exec 3<&-
  read_line '输入要回滚的备份编号（0=取消）：' '0'
  case "$JB_ANSWER" in 0|'') info '已取消'; done_task '完成'; return 0 ;; esac
  case "$JB_ANSWER" in *[!0-9]*) ng '编号无效'; done_task '跳过'; return 1 ;; esac
  _sel=''; _i=1
  exec 3<"$_lst"
  while IFS= read -r _b <&3; do [ "$_i" = "$JB_ANSWER" ] && _sel="$_b"; _i=$((_i + 1)); done
  exec 3<&-
  [ -f "$_sel" ] || { ng '备份不存在'; done_task '跳过'; return 1; }
  step '确认并覆盖'
  run ls -l "$_sel"
  confirm_exact "确认用该备份覆盖 $TS/security_patch.txt 吗？" 'RESTORE' || { printf '  已取消。\n'; return 0; }
  backup_path "$TS/security_patch.txt"
  run cp "$_sel" "$TS/security_patch.txt"
  run chmod 644 "$TS/security_patch.txt"
  run restorecon "$TS/security_patch.txt"
  done_task '已回滚；请重启后复测。'
}
menu_ts_patch(){
  while :; do
    clear_screen; hr
    printf '  修复（Tampered Attestation Key(X)（含 16 / 31））\n'
    hr
    cat <<'EOF'
   1) 生成 security_patch.txt（26 号补丁标签）
   2) 删除 security_patch.txt
   3) 从备份回滚 security_patch.txt
   4) 临时隔离模块（移出 /data/adb/modules，不删除）
   5) 恢复被隔离的模块
   0) 返回主菜单
EOF
    printf '\n  请输入序号：'
    read -r c 2>/dev/null || return 0
    case "$c" in
      1) f_ts_patch ;;
      2) f_ts_del_patch ;;
      3) f_ts_patch_rollback ;;
      4) quarantine_modules ;;
      5) restore_modules ;;
      0) return 0 ;;
      *) warn '无效序号'; pause ;;
    esac
  done
}

# ---- 词条子菜单：异常文件 ----
menu_abnormal_files(){
  while :; do
    clear_screen; hr
    printf '  修复（异常文件）\n'
    hr
    cat <<'EOF'
   1) 扫描高危路径清单（只读）
   2) 按清单逐条清理（需输入 DELETE）
   3) 按检测结果删除指定路径（单个，白名单目录）
   4) 扫描 /sdcard 下名称含 sh 的文件/目录（只读）
   0) 返回主菜单
EOF
    printf '\n  请输入序号：'
    read -r c 2>/dev/null || return 0
    case "$c" in
      1) scan_appendix_b ;;
      2) clean_appendix_b ;;
      3) delete_reported_path ;;
      4) f_dirty_scan_only ;;
      0) return 0 ;;
      *) warn '无效序号'; pause ;;
    esac
  done
}

# ---- 词条子菜单：Property Modified ----
menu_prop_modified(){
  while :; do
    clear_screen; hr
    printf '  修复（Property Modified（数字代表几处属性修改））\n'
    hr
    cat <<'EOF'
   1) 立即应用属性伪装（35 条，运行态，带快照）
   2) 部署开机脚本 shamiko_Plus.sh（长期生效）
   3) 复制任意脚本到 /data/adb/service.d
   4) 查看已部署脚本
   5) 移除本工具部署的脚本
   0) 返回主菜单
EOF
    printf '\n  请输入序号：'
    read -r c 2>/dev/null || return 0
    case "$c" in
      1) f_shamiko_apply ;;
      2) deploy_shamiko ;;
      3) copy_script_to_service_d ;;
      4) list_service_d ;;
      5) remove_service_d ;;
      0) return 0 ;;
      *) warn '无效序号'; pause ;;
    esac
  done
}

# ---- 使用统计（默认关闭，opt-in；只发送随机ID/版本/事件/运行次数）----
cfg_file(){ printf '%s' "$JB_BASE/config"; }
cfg_get(){ [ -f "$(cfg_file)" ] || return 0; sed -n "s/^$1=//p" "$(cfg_file)" 2>/dev/null | tail -n 1 | tr -d '\r'; }
cfg_set(){
  _cf="$(cfg_file)"; mkdir -p "$JB_BASE" 2>/dev/null
  if [ -f "$_cf" ]; then grep -v "^$1=" "$_cf" >"$_cf.tmp" 2>/dev/null; else : >"$_cf.tmp"; fi
  printf '%s=%s\n' "$1" "$2" >>"$_cf.tmp"
  mv "$_cf.tmp" "$_cf" 2>/dev/null
  return 0
}
usage_file(){ printf '%s' "$JB_BASE/usage.log"; }
stats_local_runs(){ if [ -f "$(usage_file)" ]; then wc -l <"$(usage_file)" 2>/dev/null | tr -d ' '; else printf '0'; fi; }
stats_bump(){ mkdir -p "$JB_BASE" 2>/dev/null; printf '%s|%s\n' "$(date '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)" "$JB_VER" >>"$(usage_file)" 2>/dev/null; return 0; }
stats_id(){
  _sid="$(cfg_get install_id)"
  if [ -z "$_sid" ]; then
    if [ -r /proc/sys/kernel/random/uuid ]; then
      _sid="$(cat /proc/sys/kernel/random/uuid 2>/dev/null)"
    else
      _sid="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
    fi
    case "$_sid" in ''|*[!0-9a-zA-Z-]*) _sid="anon-$(date +%s 2>/dev/null)-$$" ;; esac
    cfg_set install_id "$_sid"
    cfg_set first_seen "$(date '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)"
  fi
  printf '%s' "$_sid"
}
stats_enabled(){
  case "${JB_STATS_FORCE:-}" in on) return 0 ;; off) return 1 ;; esac
  [ "$(cfg_get stats)" = 1 ] && return 0
  [ "$JB_STATS_DEFAULT" = 1 ] && return 0
  return 1
}
stats_parse_count(){
  [ -s "$1" ] || return 1
  _sb="$(tr -d '\n\r' <"$1" 2>/dev/null)"
  case "$_sb" in
    *count*) _sn="$(printf '%s' "$_sb" | sed 's/.*count[^0-9]*\([0-9][0-9]*\).*/\1/')" ;;
    *) case "$_sb" in ''|*[!0-9]*) return 1 ;; esac; _sn="$_sb" ;;
  esac
  case "$_sn" in ''|*[!0-9]*) return 1 ;; esac
  printf '%s' "$_sn"
}
stats_report(){ # $1 事件（install/run）
  [ -n "$JB_STATS_URL" ] || return 1
  [ "$(net_tool_name)" = '无' ] && return 1
  _sr_id="$(stats_id)"
  _sr_url="$JB_STATS_URL?id=$_sr_id&v=$JB_VER&ev=$1&n=$(stats_local_runs)"
  if stats_get "$_sr_url" >"$JB_TMP/stats.out" 2>/dev/null; then
    STATS_LAST="$(stats_parse_count "$JB_TMP/stats.out" 2>/dev/null)"
    [ -n "$STATS_LAST" ] && cfg_set last_count "$STATS_LAST"
    return 0
  fi
  return 1
}
stats_consent(){ # 首次交互询问；默认关闭
  [ -n "$(cfg_get stats)" ] && return 0
  [ -t 0 ] || return 0
  [ "$DRY_RUN" = 1 ] && return 0
  [ -n "$JB_STATS_URL" ] || return 0
  hr
  printf '  匿名使用统计（默认关闭）\n'
  pln '  开启后每次运行只发送：随机安装 ID、脚本版本、事件(run/install)、本机运行次数。'
  pln '  不发送：设备型号/系统版本/IMEI/账号/位置/文件内容。'
  pln '  服务端会像任何网站一样看到你的 IP（仅用于去重，建议保留 ≤30 天）。'
  pln '  可随时用 57) 工具（使用统计与隐私）关闭。'
  if ask_yn '是否开启匿名使用统计？'; then
    cfg_set stats 1; ok '已开启（可随时关闭）'
  else
    cfg_set stats 0; info '已保持关闭'
  fi
  hr
}
stats_startup(){
  stats_bump
  [ -n "$JB_STATS_URL" ] || return 0
  stats_consent
  stats_enabled || return 0
  stats_id >/dev/null
  if [ -z "$(cfg_get install_reported)" ]; then
    stats_report install && cfg_set install_reported 1
  fi
  stats_report run
  [ -n "$STATS_LAST" ] && info "累计使用人数（服务端统计）：$STATS_LAST"
  return 0
}
f_stats(){
  begin_task '使用统计与隐私' '工具' '—' '只读' '否'
  step '本机统计（离线，始终可用）'
  pln "        本机运行次数：$(stats_local_runs)"
  pln "        安装 ID：$(stats_id | cut -c1-8)…（服务端去重用，可删 config 重置）"
  pln "        配置/计数文件：$(cfg_file) 、 $(usage_file)"
  step '联网统计状态'
  if [ -z "$JB_STATS_URL" ]; then
    info '未配置统计端点（脚本内 JB_STATS_URL）：当前只有本机计数'
  elif stats_enabled; then
    ok "已开启；端点：$JB_STATS_URL"
    _fc="$(cfg_get last_count)"; [ -n "$_fc" ] && pln "        上次累计人数：$_fc"
    read_line '是否立即上报一次并刷新累计人数？（y/N）' 'n'
    case "$JB_ANSWER" in
      y|Y|yes|YES)
        if stats_report run; then
          [ -n "$STATS_LAST" ] && ok "累计使用人数：$STATS_LAST" || warn '服务端未返回人数'
        else
          warn '上报失败（已忽略）'
        fi ;;
      *) info '已跳过' ;;
    esac
    if ask_yn '是否关闭匿名使用统计？'; then cfg_set stats 0; info '已关闭，之后不再发起统计请求'; fi
  else
    warn '当前为关闭状态（默认）'
    if ask_yn '是否开启匿名使用统计？（只发送随机ID/版本/事件/运行次数）'; then
      cfg_set stats 1; ok '已开启'
      stats_report install >/dev/null 2>&1 && cfg_set install_reported 1
      if stats_report run; then [ -n "$STATS_LAST" ] && ok "累计使用人数：$STATS_LAST"; fi
    fi
  fi
  step '说明'
  info '统计仅用于估算使用人数；关闭后不发起任何统计请求。'
  done_task '完成。'
}

# ---- 自动检测最新版本（读云端清单，按《哈希云端校验·网站侧技术要求》）----
ver_gt(){ # 0 表示 $1 > $2
  _vi=1
  while [ "$_vi" -le 4 ]; do
    _va="$(printf '%s' "$1" | cut -d. -f"$_vi" | tr -cd '0-9')"; [ -z "$_va" ] && _va=0
    _vb="$(printf '%s' "$2" | cut -d. -f"$_vi" | tr -cd '0-9')"; [ -z "$_vb" ] && _vb=0
    [ "$_va" -gt "$_vb" ] && return 0
    [ "$_va" -lt "$_vb" ] && return 1
    _vi=$((_vi + 1))
  done
  return 1
}
manifest_get(){ sed -n "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*//p" "$1" 2>/dev/null | head -n 1 | tr -d ' \r'; }
update_source(){ printf '%s' "${JB_UPDATE_URL:-$JB_OFFICIAL_HASH_URL}"; }
update_probe(){ # 结果写入 UP_*；成功返回 0
  UP_STATE=''; UP_LATEST=''; UP_SEQ=''; UP_MIN=''; UP_URL=''; UP_NOTES=''; UP_RAW=''
  _usrc="$(update_source)"
  [ -n "$_usrc" ] || { UP_STATE='nourl'; return 1; }
  if [ "$(net_tool_name)" = '无' ]; then UP_STATE='notool'; return 1; fi
  if ! fetch_url_quick "$_usrc" "$JB_TMP/update.manifest"; then UP_STATE='netfail'; return 1; fi
  tr 'A-Z' 'a-z' <"$JB_TMP/update.manifest" >"$JB_TMP/update.manifest.lc" 2>/dev/null
  _um="$JB_TMP/update.manifest.lc"
  UP_LATEST="$(manifest_get "$_um" version)"
  UP_SEQ="$(manifest_get "$_um" release_seq)"
  UP_MIN="$(manifest_get "$_um" min_client)"
  UP_URL="$(manifest_get "$_um" download_url)"
  UP_NOTES="$(manifest_get "$_um" notes)"
  UP_RAW="$(manifest_get "$_um" raw_sha256)"
  [ -n "$UP_LATEST" ] || { UP_STATE='nover'; return 1; }
  if ver_gt "$UP_LATEST" "$JB_VER"; then UP_STATE='newer'
  elif [ "$UP_LATEST" = "$JB_VER" ]; then UP_STATE='same'
  else UP_STATE='older'; fi
  return 0
}
update_notice(){ # 启动时一行提示（非阻断）
  [ "$JB_UPDATE_CHECK" = 1 ] || return 0
  [ "$DRY_RUN" = 1 ] && return 0
  update_probe || return 0
  case "$UP_STATE" in
    newer) warn "发现新版本 v$UP_LATEST（当前 v$JB_VER）：见 55) 工具（检测最新版本）";;
    same)  info "版本检查：已是最新（v$JB_VER）";;
    *) : ;;
  esac
  return 0
}
update_download(){ # $1 url $2 期望摘要
  if [ -z "$1" ]; then warn '清单未提供 download_url，跳过下载'; return 1; fi
  _udst="$JB_BASE/downloads/$(basename "$1")"
  run mkdir -p "$JB_BASE/downloads"
  step "下载到 $_udst"
  if fetch_url "$1" "$_udst"; then
    ok '下载完成（不会自动覆盖当前脚本）'
    _uh="$(sha256_file "$_udst")"
    pln "        实际摘要：$_uh"
    if [ -n "$2" ]; then
      if [ "$_uh" = "$2" ]; then ok '摘要校验通过（与清单 raw_sha256 一致）'
      else ng '摘要不一致：请勿使用该文件'; fi
    else
      warn '清单未提供 raw_sha256，无法校验'
    fi
  else
    ng '下载失败'
  fi
}
f_check_update(){
  begin_task '检测最新版本' '工具' '—' '只读' '否'
  step "当前版本：$JB_VER"
  update_probe
  case "$UP_STATE" in
    nourl)  info '未配置更新源：填 JB_OFFICIAL_HASH_URL / JB_UPDATE_URL，或用 --update-url <url>' ;;
    notool) warn '设备无下载工具，无法联网检测' ;;
    netfail) warn '联网失败或清单不存在（已忽略，不影响使用）' ;;
    nover)  warn '清单缺少 version 字段，无法比较版本' ;;
    same)   ok "已是最新版本：v$JB_VER" ;;
    older)  warn "清单版本 v$UP_LATEST 低于当前 v$JB_VER（服务端可能未更新，或你用的是内测版）" ;;
    newer)
      warn "发现新版本：v$UP_LATEST（当前 v$JB_VER）"
      [ -n "$UP_SEQ" ] && pln "        release_seq=$UP_SEQ"
      [ -n "$UP_MIN" ] && pln "        min_client=$UP_MIN"
      [ -n "$UP_NOTES" ] && pln "        更新说明：$UP_NOTES"
      [ -n "$UP_RAW" ] && pln "        制品摘要：$UP_RAW"
      info '可下载到 downloads 目录并校验摘要，再自行替换；本工具不会自动覆盖自身。'
      read_line '是否现在下载新版本到 downloads？（y/N）' 'n'
      case "$JB_ANSWER" in y|Y|yes|YES) update_download "$UP_URL" "$UP_RAW" ;; *) info '已跳过下载' ;; esac ;;
  esac
  done_task '检测完成。'
}

# ---- 自动体检 / 自动修复 ----
auto_label(){
  case "$1" in
    1)  printf '修复（Found property）' ;;
    3)  printf '修复（密钥篡改 / 证书链篡改(x)）' ;;
    6)  printf '修复（Vold隔离已开启）' ;;
    7)  printf '修复（USB 调试已开启）' ;;
    8)  printf '修复（Suspicious Surroundings (a)）' ;;
    10) printf '修复（Suspicious Surroundings（c））' ;;
    13) printf '修复（Inconsistent mount / 不一致的挂载（debug_ramdisk））' ;;
    9)  printf '修复（Suspicious Surroundings（b）· 内置 Inode-Hijacker）' ;;
    12) printf '修复（/data/local/tmp denied）' ;;
    21) printf '修复（MT管理器（MT2文件夹）/异常文件）' ;;
    26) printf '修复（环境伪造）' ;;
    27) printf '修复（SU binary detected）' ;;
    *)  printf '序号 %s' "$1" ;;
  esac
}
auto_detect_list(){
  _o="$1"; : > "$_o"
  if [ -d /data/local/tmp ]; then
    _ao="$(stat -c '%u:%g' /data/local/tmp 2>/dev/null)"
    _am="$(stat -c '%a' /data/local/tmp 2>/dev/null)"
    _ai="$(stat -c '%i' /data/local/tmp 2>/dev/null)"
    [ "$_ao" != '2000:2000' ] && printf '%s\n' "8|/data/local/tmp 属主=$_ao" >>"$_o"
    [ "$_am" != '771' ] && printf '%s\n' "10|/data/local/tmp 权限=$_am" >>"$_o"
    case "$_ai" in ''|*[!0-9]*) ;; *) [ "$_ai" -gt 10000 ] && printf '%s\n' "9|inode=$_ai（>10000）" >>"$_o" ;; esac
  else
    printf '%s\n' '12|/data/local/tmp 不存在' >>"$_o"
  fi
  _alp="$(getprop persist.logd.size 2>/dev/null)$(getprop persist.logd.size.crash 2>/dev/null)$(getprop persist.logd.size.system 2>/dev/null)$(getprop persist.logd.size.main 2>/dev/null)"
  [ -n "$_alp" ] && printf '%s\n' '1|logd 缓冲区属性非空' >>"$_o"
  [ "$(getprop ro.secureboot.lockstate 2>/dev/null)" = 'unlocked' ] && printf '%s\n' '3|ro.secureboot.lockstate=unlocked' >>"$_o"
  [ -n "$(getprop persist.sys.vold_app_data_isolation_enabled 2>/dev/null)" ] && printf '%s\n' '6|Vold 隔离属性存在' >>"$_o"
  [ "$(settings get global adb_enabled 2>/dev/null)" = '1' ] && printf '%s\n' '7|USB 调试已开启' >>"$_o"
  [ -n "$(getprop 2>/dev/null | grep -iE 'pihooks|pixelprops|spoof')" ] && printf '%s\n' '26|属性伪装残留' >>"$_o"
  [ -e /storage/emulated/0/MT2 ] && printf '%s\n' '21|/sdcard/MT2 存在' >>"$_o"
  [ -x /apex/com.android.virt/bin/su ] && printf '%s\n' '27|/apex 内 su 可执行' >>"$_o"
  grep -q ' /debug_ramdisk ' /proc/self/mountinfo 2>/dev/null && printf '%s\n' '13|/debug_ramdisk 已挂载' >>"$_o"
  return 0
}
f_auto_repair(){
  begin_task '自动体检 + 自动修复已命中项' '通用排查方法' '34（说明与反馈）' '中' '否'
  _lst="$JB_TMP/autofix.$$"
  auto_detect_list "$_lst"
  if [ ! -s "$_lst" ]; then info '未发现可自动修复的状态'; done_task '完成'; return 0; fi
  step '检出项'
  exec 3<"$_lst"
  while IFS='|' read -r _n _r <&3; do printf '        %s —— %s\n' "$(auto_label "$_n")" "$_r"; done
  exec 3<&-
  warn '只自动执行低风险属性/权限项；其余只列建议，需你手动执行。'
  step '自动执行低风险项'
  _adone=0
  for _an in 1 3 6 7 8 10 13; do
    if cut -d'|' -f1 "$_lst" 2>/dev/null | grep -qx "$_an"; then
      info "开始执行：$(auto_label "$_an")"
      run_item "$_an"
      _adone=$((_adone + 1))
    fi
  done
  step '需要手动执行的高风险 / 交互项'
  exec 3<"$_lst"
  while IFS='|' read -r _n _r <&3; do
    case "$_n" in 1|3|6|7|8|10|13) continue ;; esac
    printf '        → %s（%s）\n' "$(auto_label "$_n")" "$_r"
  done
  exec 3<&-
  done_task "已自动执行 $_adone 项；其余请按上方序号手动执行。"
}

# ---- 修复（隐藏应用列表生效（2））：结束非必要系统组件的应用层 UID ----
f_hideapp_kill(){
  begin_task '结束非必要系统组件的应用层 UID' '隐藏应用列表生效（2）' '—' '高' '否'
  warn '原理：隐藏应用列表（HMA 类）注入后，部分预装组件进程会残留「列表已生效」的可见状态。'
  warn '      结束这些非系统必要组件的应用层进程（uid>=10000），让系统重新拉起，可清掉残留状态。'
  step '列出预装（系统）包及其 UID'
  _su="$JB_TMP/sysuid.$$"
  pm list packages -s -U 2>/dev/null | sed 's/^package://; s/ uid:/|/' | grep -E '^[^|]+\|[0-9]+$' >"$_su" 2>/dev/null
  if [ ! -s "$_su" ]; then
    warn '无法获取系统包列表（需要 Android 11+ 的 pm list packages -s -U）'
    done_task '跳过'; return 1
  fi
  pln "        预装包数量：$(wc -l <"$_su" | tr -d ' ')"
  step '枚举应用层进程（uid>=10000，排除必要的系统层 uid）'
  _raw="$JB_TMP/psraw.$$"
  ps -A -o uid,pid,args 2>/dev/null >"$_raw"
  if ! awk 'NR>1 && $1 ~ /^[0-9]+$/ {ok=1} END{exit !ok}' "$_raw" 2>/dev/null; then
    warn 'ps 输出不是数值 UID 格式（该机型/该 toybox 不支持 -o uid）：本机无法安全按 UID 结束进程'
    done_task '跳过'; return 1
  fi
  _cand="$JB_TMP/killcand.$$"
  awk -v self="$(id -u)" '/^[ \t]*[0-9]+[ \t]+[0-9]+/ { u=$1+0; p=$2+0; if (u>=10000 && u!=self && p>1) { $1=""; $2=""; sub(/^[ \t]+/,""); printf "%d|%d|%s\n", u, p, $0 } }' "$_raw" >"$_cand" 2>/dev/null
  step '与预装包取交集，并排除必要组件'
  _list="$JB_TMP/killlist.$$"; : >"$_list"
  exec 3<"$_cand"
  while IFS='|' read -r _u _pp _cc <&3; do
    _pkg="$(grep "|$_u\$" "$_su" 2>/dev/null | head -n 1 | cut -d'|' -f1)"
    [ -n "$_pkg" ] || continue
    case "$_pkg" in
      *launcher*|*home*|*systemui*|*inputmethod*|*settings*|*permissioncontroller*|*telecom*|*phone*|*bluetooth*|*nfc*|*camera*|*deskclock*|*provider*|*framework*) continue ;;
    esac
    [ "$_pkg" = "$JB_DETECTOR_PKG" ] && continue
    printf '%s|%s|%s\n' "$_u" "$_pp" "$_pkg" >>"$_list"
  done
  exec 3<&-
  _cnt="$(wc -l <"$_list" | tr -d ' ')"
  if [ "$_cnt" = 0 ]; then info '没有可结束的候选（进程都已停止，或全部落入排除名单）'; done_task '完成'; return 0; fi
  step "候选进程（共 $_cnt 条）"
  exec 3<"$_list"
  while IFS='|' read -r _u _pp _pkg <&3; do
    printf '        uid=%-6s pid=%-6s %s\n' "$_u" "$_pp" "$_pkg"
  done
  exec 3<&-
  warn '结束后系统通常会重新拉起这些组件；其间可能看到图标/界面短暂重载。'
  if [ "$DRY_RUN" = 1 ]; then info '[演练模式] 跳过实际结束'; done_task '演练完成'; return 0; fi
  confirm_exact '确认结束上述应用层 UID 的进程吗？' 'KILL_APP_UID' || { printf '  已取消。\n'; return 0; }
  step '结束进程'
  _kok=0; _kng=0
  exec 3<"$_list"
  while IFS='|' read -r _u _pp _pkg <&3; do
    if kill -9 "$_pp" 2>/dev/null; then ok "已结束 uid=$_u pid=$_pp $_pkg"; _kok=$((_kok + 1))
    else warn "无法结束 uid=$_u pid=$_pp $_pkg（可能已退出）"; _kng=$((_kng + 1)); fi
  done
  exec 3<&-
  step '复核'
  sleep 2
  _alive=0
  exec 3<"$_list"
  while IFS='|' read -r _u _pp _pkg <&3; do
    kill -0 "$_pp" 2>/dev/null && _alive=$((_alive + 1))
  done
  exec 3<&-
  pln "        已结束 $_kok 个（失败 $_kng），其中 $_alive 个 PID 已被系统重新拉起"
  info '若检测项仍在：说明触发源不在这些 UID 上，请改用其它词条方案（应用隐藏模块配置等）。'
  done_task '完成。'
}

# ---- 菜单渲染（宽度自适应，防文字乱飞）----
entry_label(){
  case "$1" in
    1) printf '%s' '修复（Found property）' ;;
    2) printf '%s' '修复（avb校验异常 avb=2.0）' ;;
    3) printf '%s' '修复（密钥篡改 / 证书链篡改(x)）' ;;
    4) printf '%s' '修复（Bootloader unlock / 解锁属性）' ;;
    5) printf '%s' '修复（启动状态异常）' ;;
    6) printf '%s' '修复（Vold隔离已开启）' ;;
    7) printf '%s' '修复（USB 调试已开启）' ;;
    8) printf '%s' '修复（Suspicious Surroundings (a)）' ;;
    9) printf '%s' '修复（Suspicious Surroundings（b）· 内置 Inode-Hijacker）' ;;
    10) printf '%s' '修复（Suspicious Surroundings（c））' ;;
    11) printf '%s' '修复（/data/local/tmp 元数据异常族）' ;;
    12) printf '%s' '修复（/data/local/tmp denied）' ;;
    13) printf '%s' '修复（Inconsistent mount / 不一致的挂载（debug_ramdisk））' ;;
    14) printf '%s' '修复（Tampered Attestation Key(X)（含 16 / 31））〔子菜单〕' ;;
    15) printf '%s' '修复（发现TrickyStore/类似模块）' ;;
    16) printf '%s' '修复（TEE 损坏）' ;;
    17) printf '%s' '修复（AOSP密钥）' ;;
    18) printf '%s' '修复（证书已被吊销(CRL)）' ;;
    19) printf '%s' '修复（Dirty Device(a)）' ;;
    20) printf '%s' '修复（异常文件）〔子菜单〕' ;;
    21) printf '%s' '修复（MT管理器（MT2文件夹）/异常文件）' ;;
    22) printf '%s' '修复（发现异常模块）' ;;
    23) printf '%s' '修复（fdinfo mnt 采样异常（c））' ;;
    24) printf '%s' '修复（Property Modified（数字代表几处属性修改））〔子菜单〕' ;;
    25) printf '%s' '修复（内存异常）' ;;
    26) printf '%s' '修复（环境伪造）' ;;
    27) printf '%s' '修复（SU binary detected）' ;;
    28) printf '%s' '修复（Found ksu/免解设备 · PID 回绕实验）⚠高风险' ;;
    29) printf '%s' '修复（隐藏应用列表生效（2））' ;;
    30) printf '%s' '查看（/data/local/tmp 现状）' ;;
    31) printf '%s' '查看（tricky_store 配置）' ;;
    33) printf '%s' '扫描（异常文件高危清单，只读）' ;;
    34) printf '%s' '诊断（环境报告）' ;;
    35) printf '%s' '诊断（附录 C 被检查属性）' ;;
    36) printf '%s' '诊断（异常进程0000 pid 反查）' ;;
    37) printf '%s' '诊断（挂载视图 / mountinfo · 挂载异常(X)）' ;;
    38) printf '%s' '诊断（属性伪装残留）' ;;
    39) printf '%s' '扫描（自动体检：列出可自动修复项）' ;;
    40) printf '%s' '工具（一键修复 (a)+(c) 属主+权限+上下文）' ;;
    41) printf '%s' '工具（restorecon 恢复 SELinux 上下文）' ;;
    42) printf '%s' '工具（整目录备份 tricky_store）' ;;
    43) printf '%s' '工具（移除已部署的开机脚本）' ;;
    44) printf '%s' '工具（识别春秋检测包名）' ;;
    45) printf '%s' '工具（生成诊断报告）' ;;
    46) printf '%s' '安全（脚本完整性 / 来源自检）' ;;
    47) printf '%s' '工具（在线校验来源）' ;;
    48) printf '%s' '工具（下载官方修复脚本）' ;;
    49) printf '%s' '工具（获取 Inode-Hijacker / ADB-Trace-Cleaner）' ;;
    50) printf '%s' '工具（自定义直链下载）' ;;
    51) printf '%s' '工具（致谢与开源许可）' ;;
    52) printf '%s' '工具（查看备份）' ;;
    53) printf '%s' '工具（从备份恢复）' ;;
    54) printf '%s' '工具（查看本次日志）' ;;
    55) printf '%s' '工具（导出日志到 /sdcard）' ;;
    56) printf '%s' '工具（检测最新版本）' ;;
    57) printf '%s' '工具（使用统计与隐私）' ;;
    58) printf '%s' '检测（无效的伪造信息(1) · Widevine）' ;;
    *) printf '%s' "序号 $1" ;;
  esac
}
entry_ref(){
  case "$1" in
    1) printf '%s' 'L1089' ;;
    2) printf '%s' 'L1106' ;;
    3) printf '%s' 'L566' ;;
    4) printf '%s' 'L534' ;;
    5) printf '%s' 'L547' ;;
    6) printf '%s' 'L1253' ;;
    7) printf '%s' 'L1042' ;;
    8) printf '%s' 'L866' ;;
    9) printf '%s' 'L879' ;;
    10) printf '%s' 'L896' ;;
    11) printf '%s' 'L703' ;;
    12) printf '%s' 'L909' ;;
    13) printf '%s' 'L610' ;;
    14) printf '%s' 'L433' ;;
    15) printf '%s' 'L469' ;;
    16) printf '%s' 'L487' ;;
    17) printf '%s' 'L513' ;;
    18) printf '%s' 'L558' ;;
    19) printf '%s' 'L781' ;;
    20) printf '%s' 'L946' ;;
    21) printf '%s' 'L926' ;;
    22) printf '%s' 'L995' ;;
    23) printf '%s' 'L753' ;;
    24) printf '%s' 'L1097' ;;
    25) printf '%s' 'L761' ;;
    26) printf '%s' 'L1214' ;;
    27) printf '%s' 'L230' ;;
    28) printf '%s' 'L218' ;;
    58) printf '%s' 'L1058' ;;
    *) printf '' ;;
  esac
}
# ---- 短标签（窄屏回退，构建期预截断，运行时不再截断）----
print_menu_repair(){
  if [ "$JB_WIDTH" -ge 26 ]; then printf '【修复项 · 春秋检测词条】\n'; else printf '【修复项】\n'; fi
  _mi=1
  while [ "$_mi" -le 29 ]; do
    print_entry "$_mi" "$(entry_label "$_mi")" "$(entry_ref "$_mi")"
    _mi=$((_mi + 1))
  done
  print_entry 58 "$(entry_label 58)" "$(entry_ref 58)"
}
print_menu_hidden(){
  printf '\n【查看/扫描/诊断】\n'
  _mi=29
  while [ "$_mi" -le 39 ]; do
    [ "$_mi" = 32 ] || print_entry "$_mi" "$(entry_label "$_mi")" "$(entry_ref "$_mi")"
    _mi=$((_mi + 1))
  done
  printf '\n【工具】\n'
  _mi=39
  while [ "$_mi" -le 57 ]; do
    print_entry "$_mi" "$(entry_label "$_mi")" "$(entry_ref "$_mi")"
    _mi=$((_mi + 1))
  done
}

# 序号 -> 修复项 的唯一分发入口
run_item(){
  case "$1" in
    1) f_found_property ;;
    2) f_avb ;;
    3) f_lockstate ;;
    4) r_bootloader_unlock ;;
    5) r_abnormal_boot ;;
    6) f_vold ;;
    7) f_usb_off ;;
    8) f_tmp_owner ;;
    9) run_embedded_inode ;;
    10) f_tmp_perm ;;
    11) r_meta_family ;;
    12) r_tmp_denied ;;
    13) f_debug_ramdisk ;;
    14) menu_ts_patch ;;
    15) f_ts_del_patch ;;
    16) f_ts_target ;;
    17) r_ts_aosp ;;
    18) r_ts_crl ;;
    19) f_dirty_device ;;
    20) menu_abnormal_files ;;
    21) migrate_mt2 ;;
    22) clean_encore ;;
    23) run_adb_cleaner ;;
    24) menu_prop_modified ;;
    25) clear_detector_data ;;
    26) f_env_fake ;;
    27) f_su_binary ;;
    28) f_pid_wrap_zygote ;;
    29) f_hideapp_kill ;;
    30) f_tmp_show ;;
    31) f_ts_status ;;
    33) scan_appendix_b ;;
    34) env_report; pause ;;
    35) f_check_props ;;
    36) f_find_pid ;;
    37) f_mount_diag ;;
    38) f_prop_scan ;;
    39) f_auto_scan ;;
    40) f_tmp_full ;;
    41) f_tmp_restorecon ;;
    42) f_ts_backup ;;
    43) remove_service_d ;;
    44) show_detector_pkg ;;
    45) f_diag_report ;;
    46) self_check_local; self_check_online; pause ;;
    47) self_check_online; pause ;;
    48) net_download_repo ;;
    49) net_download_tools ;;
    50) net_custom_download ;;
    51) net_links ;;
    52) list_backups ;;
    53) restore_backup ;;
    54) view_log ;;
    55) export_log ;;
    56) f_check_update ;;
    57) f_stats ;;
    58) f_widevine_check ;;
    *)  warn "无效序号：$1" ;;
  esac
}

menu_main(){
  while :; do
    clear_screen
    page_header
    print_menu_repair
    [ "$JB_SHOW_ALL" = 1 ] && print_menu_hidden
    if [ "$JB_WIDTH" -ge 100 ]; then
      printf '\n  序号(可多个 8 9 12) ｜ s=体检 ｜ a=自动修复 ｜ p=1~7 ｜ t=8~13 ｜ x=其他栏目 ｜ h=帮助 ｜ 0=退出\n'
    else
      printf '\n  序号(可多个 8 9 12) ｜ s=体检 ｜ a=修复 ｜ p=1~7 ｜ t=8~13\n'
      printf '  x=其他栏目 ｜ h=帮助 ｜ 0=退出\n'
    fi
    printf '  > '
    read -r _line 2>/dev/null || return 0
    case "$_line" in
      0|q|Q|quit|exit) printf '\n  已退出。日志：%s\n' "$LOG"; return 0 ;;
      h|H|help|\?)     page_help; pause; continue ;;
      x|X)             if [ "$JB_SHOW_ALL" = 1 ]; then JB_SHOW_ALL=0; else JB_SHOW_ALL=1; fi; continue ;;
      s|S)             f_auto_scan; pause; continue ;;
      a|A)             f_auto_repair; pause; continue ;;
      p|P)             for _i in 1 2 3 4 5 6 7; do run_item "$_i"; done; pause; continue ;;
      t|T)             for _i in 8 9 10 11 12 13; do run_item "$_i"; done; pause; continue ;;
    esac
    _norm="$(printf '%s' "$_line" | sed 's/[,，、;]/ /g')"
    _any=0
    for _tok in $_norm; do
      case "$_tok" in
        ''|*[!0-9]*) warn "无效序号：$_tok"; continue ;;
      esac
      _any=1
      run_item "$_tok"
    done
    [ "$_any" = 1 ] || warn '未识别到有效序号（输入 h 看帮助）'
    pause
  done
}

# ---------------------------------------------------------------------
# 16. 命令行参数与入口
# ---------------------------------------------------------------------
usage(){
  cat <<EOF
$JB_NAME v$JB_VER  by $JB_AUTHOR

用法： sh $JB_NAME.sh [选项]

  无参数启动：主页只显示「修复项 · 春秋检测词条」；输入序号即执行（支持 8 9 12）。
  其他栏目默认隐藏，按 x 切换显示。快捷键：s 体检 / a 自动修复 / p 1~7 / t 8~13 / h 帮助 / 0 退出。

  --print-hash        打印 4 个摘要（原始/总哈希/分发区/载荷）——作者维护用；
                      注意：任何拿到脚本的人都能执行它，所以它不构成防护。
  --self-test         只做自检与环境报告，不进入菜单
  --dry-run           演练模式：只显示将执行什么，不真正执行
  --fast              关闭逐步骤暂停
  --step              强制逐步骤暂停
  --yes               跳过各类确认（危险，慎用）
  --accept-license    跳过法律声明交互确认
  --no-color          关闭彩色输出
  --clear             每个菜单前清屏
  --width <列数>      固定显示宽度（默认自动检测，取不到时按 80 列排版）
  --verify <摘要>     用外部摘要校验本文件（原始文件或总哈希）
  --verify-remote [url] 联网校验；失败默认仅告警
  --strict            严格模式：校验失败/拉不到摘要就拒绝启动
  --allow-unverified  跳过完整性校验（危险，仅自改副本用）
  --check-update      只检测最新版本后退出（0=最新 10=有新版 1=检测失败）
  --no-update-check   启动时不做版本检查
  --update-url <url>  指定版本/摘要清单地址
  --stats-on          开启匿名使用统计（也可在菜单 57 里改）
  --stats-off         关闭匿名使用统计
  --stats-show        打印本机运行次数与统计状态后退出
  --stats-url <url>   指定统计端点（测试/自建用）
  --license           打印第三方代码许可声明（Inode-Hijacker / MIT 全文）后退出
  -h, --help          显示本帮助

环境变量：
  JB_OFFICIAL_HASH_URL  官方校验地址（只含 64 位 sha256 文本）
  JB_BASE_OVERRIDE      输出根目录，默认 /sdcard/JinBeiChunQiuFixToolPro2
  JB_TMP_OVERRIDE       临时目录
  JB_WIDTH_ENV          显示宽度（同 --width）
EOF
}
parse_args(){
  while [ $# -gt 0 ]; do
    case "$1" in
      --print-hash) JB_MODE='hash' ;;
      --self-test) JB_MODE='selftest' ;;
      --dry-run) DRY_RUN=1 ;;
      --fast) JB_FAST=1; JB_STEP_PAUSE=0 ;;
      --step) JB_STEP_PAUSE=1 ;;
      --yes) JB_ASSUME_YES=1 ;;
      --accept-license) JB_ACCEPT=1 ;;
      --no-color) JB_COLOR=0 ;;
      --clear) JB_CLEAR=1 ;;
      --width) shift; JB_WIDTH_OVERRIDE="$1" ;;
      --verify) shift; JB_VERIFY_EXPECT="$1" ;;
      --allow-unverified) JB_ALLOW_UNVERIFIED=1 ;;
      --verify-remote)
        JB_VERIFY_REMOTE=1
        case "${2:-}" in http://*|https://*) shift; JB_VERIFY_REMOTE_URL="$1" ;; esac ;;
      --strict) JB_STRICT=1 ;;
      --check-update) JB_MODE='update' ;;
      --no-update-check) JB_UPDATE_CHECK=0 ;;
      --update-url) shift; JB_UPDATE_URL="$1" ;;
      --stats-on) JB_STATS_FORCE=on ;;
      --stats-off|--no-stats) JB_STATS_FORCE=off ;;
      --stats-show) JB_MODE='stats' ;;
      --stats-url) shift; JB_STATS_URL="$1" ;;
      --license) JB_MODE='license' ;;
      --width=*) JB_WIDTH_OVERRIDE="${1#--width=}" ;;
      -h|--help) usage; exit 0 ;;
      *) ;;
    esac
    shift
  done
}
init_tty(){
  detect_width
  if [ -t 1 ]; then JB_COLOR=1; JB_CLEAR=1; fi
  if [ -t 0 ]; then JB_STEP_PAUSE=1; fi
  [ "$JB_FAST" = 1 ] && JB_STEP_PAUSE=0
  if [ "$JB_COLOR" != 1 ]; then
    C_R=''; C_G=''; C_Y=''; C_B=''; C_D=''; C_0=''
  fi
}

main(){
  parse_args "$@"
  resolve_self
  if [ "$JB_MODE" = 'hash' ]; then
    SELF_HASH="$(self_hash)"
    if [ -z "$SELF_HASH" ]; then printf '无法计算哈希（缺少 sha256sum/toybox/busybox/openssl）\n'; exit 1; fi
    printf 'raw（发布页应公布这个） = %s\n' "$(raw_hash)"
    printf 'SELF_SHA256（写回脚本）  = %s\n' "$SELF_HASH"
    printf 'JB_DISPATCH_SHA（写回）  = %s\n' "$(dispatch_hash)"
    printf 'JB_INODE_SHA（写回）     = %s\n' "$(payload_hash)"
    exit 0
  fi
  if [ "$JB_MODE" = 'license' ]; then third_party_notice; exit 0; fi
  [ -n "${JB_OFFICIAL_HASH_URL_OVERRIDE:-}" ] && JB_OFFICIAL_HASH_URL="$JB_OFFICIAL_HASH_URL_OVERRIDE"
  if [ "$JB_MODE" != 'selftest' ] && [ "$JB_MODE" != 'update' ]; then need_root; fi
  init_tty
  init_dirs
  detect_resetprop
  if [ "$JB_MODE" = 'stats' ]; then
    printf '本机运行次数：%s\n' "$(stats_local_runs)"
    printf '安装 ID：%s\n' "$(stats_id)"
    if [ -n "$JB_STATS_URL" ]; then
      if stats_enabled; then printf '联网统计：已开启（%s）\n' "$JB_STATS_URL"; else printf '联网统计：已关闭\n'; fi
      _c="$(cfg_get last_count)"; [ -n "$_c" ] && printf '上次累计人数：%s\n' "$_c"
    else
      printf '联网统计：未配置端点（JB_STATS_URL）\n'
    fi
    exit 0
  fi
  if [ "$JB_MODE" = 'update' ]; then
    update_probe
    case "$UP_STATE" in
      newer) printf '最新版本：v%s（当前 v%s）\n' "$UP_LATEST" "$JB_VER"
             [ -n "$UP_RAW" ] && printf '制品摘要：%s\n' "$UP_RAW"
             exit 10 ;;
      same)  printf '已是最新版本：v%s\n' "$JB_VER"; exit 0 ;;
      older) printf '清单版本 v%s 低于当前 v%s\n' "$UP_LATEST" "$JB_VER"; exit 0 ;;
      nourl) printf '未配置更新源（JB_OFFICIAL_HASH_URL / JB_UPDATE_URL / --update-url）\n'; exit 1 ;;
      notool) printf '设备无下载工具，无法检测\n'; exit 1 ;;
      nover) printf '清单缺少 version 字段\n'; exit 1 ;;
      *) printf '联网失败或清单不可用\n'; exit 1 ;;
    esac
  fi
  tt "$JB_NAME v$JB_VER"
  printf '  作者：%s\n' "$JB_AUTHOR"
  printf '  说明：只做 root sh 可完成的修复；\n         每步可见、改动前自动备份。\n'
  env_report
  self_check
  if [ "$JB_MODE" = 'selftest' ]; then
    printf '\n  自检结束（--self-test）。\n'
    exit 0
  fi
  notice_line
  license
  update_notice
  stats_startup
  menu_main
  printf '\n  感谢使用 %s。\n' "$JB_NAME"
  printf '  日志：%s\n' "$LOG"
  exit 0
}

main "$@"
