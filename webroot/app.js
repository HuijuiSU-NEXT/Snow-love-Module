/* 一键隐藏 WebUI v1.4
 * KernelSU / HuijuiSU WebUI：ksu.exec(cmd, "{}", 回调名)
 * 回调必须挂在 window 上，这是 KSU 的接口约定（模板里也是这么用的）
 */
(function () {
  "use strict";

  var ROOT = "/data/adb/modules/hide_bundle";
  var MOD = "sh " + ROOT + "/";
  var out = document.getElementById("out");
  var out2 = document.getElementById("out2");
  var statusBox = document.getElementById("status");
  var loading = document.getElementById("loading");
  var toastEl = document.getElementById("toast");
  var busy = false;
  var toastTimer = null;

  function api() {
    if (window.ksu && typeof window.ksu.exec === "function") return window.ksu;
    if (window.MagiskWebUI && typeof window.MagiskWebUI.exec === "function") return window.MagiskWebUI;
    return null;
  }

  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  function toast(msg) {
    toastEl.textContent = msg;
    toastEl.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.classList.remove("show"); }, 2600);
    var k = api();
    if (k && typeof k.toast === "function") { try { k.toast(msg); } catch (e) {} }
  }

  /* ---------- 核心：兼容 KSU 回调式 exec ---------- */
  function exec(cmd, timeoutMs) {
    return new Promise(function (resolve, reject) {
      var k = api();
      if (!k) { reject(new Error("没有 ksu 接口（请在模块页里打开）")); return; }

      var name = "exec_cb_" + Date.now() + "_" + Math.random().toString(36).slice(2, 8);
      var done = false;
      var timer = setTimeout(function () {
        if (done) return;
        done = true;
        try { delete window[name]; } catch (e) {}
        resolve({ errno: -2, stdout: "", stderr: "__TIMEOUT__" });
      }, timeoutMs || 240000);

      function finish(errno, stdout, stderr) {
        if (done) return;
        done = true;
        clearTimeout(timer);
        try { delete window[name]; } catch (e) {}
        resolve({ errno: errno, stdout: stdout || "", stderr: stderr || "" });
      }

      window[name] = function (errno, stdout, stderr) { finish(errno, stdout, stderr); };

      try {
        var ret = k.exec(cmd, "{}", name);
        if (ret && typeof ret.then === "function") {
          ret.then(function (v) {
            if (typeof v === "string") finish(0, v, "");
            else if (v && typeof v === "object") finish(v.errno || 0, v.stdout || "", v.stderr || "");
            else finish(0, "", "");
          }, function (e) { finish(-1, "", (e && e.message) || String(e)); });
        } else if (typeof ret === "string") {
          finish(0, ret, "");
        }
      } catch (e) {
        clearTimeout(timer);
        if (!done) { done = true; reject(e); }
      }
    });
  }

  function resultText(r) {
    if (!r) return "(无返回)";
    if (r.stderr === "__TIMEOUT__") {
      return "命令超时（还在后台跑，或者卡住了）。\n" +
             "可以点「刷新状态」看结果，或点「查看日志」看进度。";
    }
    var s = "";
    if (r.stdout) s += r.stdout;
    if (r.stderr) s += (s ? "\n" : "") + r.stderr;
    if (!s) s = "(无输出，errno=" + (r.errno === undefined ? "?" : r.errno) + ")";
    return s;
  }

  function setBusy(on) {
    busy = on;
    var btns = document.querySelectorAll("button");
    for (var i = 0; i < btns.length; i++) btns[i].disabled = on;
    document.body.style.cursor = on ? "progress" : "";
  }

  function renderStatus(text) {
    var rows = (text || "").split("\n");
    var html = "";
    for (var i = 0; i < rows.length; i++) {
      var line = rows[i].replace(/\s+$/, "");
      var m = line.match(/^(OK|--)\s+(\S+)\s+(.*)$/);
      if (!m) continue;
      html += '<div class="card"><span class="dot' + (m[1] === "OK" ? " on" : "") + '"></span>' +
              '<span class="name">' + esc(m[3]) + "</span>" +
              '<span class="key">' + esc(m[2]) + "</span></div>";
    }
    statusBox.innerHTML = html || '<div class="card"><span class="dot"></span><span class="name">没有状态输出</span></div>';
  }

  function refreshStatus() {
    return exec(MOD + "status.sh", 25000).then(function (r) {
      renderStatus(resultText(r));
    }).catch(function (e) {
      statusBox.innerHTML = '<div class="card"><span class="dot"></span><span class="name">' + esc(e.message) + "</span></div>";
    });
  }

  function writeTo(el, text) {
    el.textContent = text || "(无输出)";
    el.scrollTop = 0;
  }

  function run(label, cmd, opts) {
    if (busy) { toast("上一项还没结束"); return; }
    opts = opts || {};
    var target = opts.target === "chunqiu" ? out2 : out;
    setBusy(true);
    writeTo(target, "$ " + label + "\n执行中…（长任务可能要几十秒到几分钟）");
    exec(cmd, opts.timeout || 240000).then(function (r) {
      writeTo(target, "$ " + label + "\n\n" + resultText(r));
      toast(r.stderr === "__TIMEOUT__" ? (label + " 超时，看日志") : (label + " 完成"));
      return refreshStatus();
    }).catch(function (e) {
      writeTo(target, "$ " + label + "\n\n失败：" + e.message);
      toast(label + " 失败");
    }).then(function () { setBusy(false); });
  }

  function pathOf(id, def) {
    var el = document.getElementById(id);
    var v = el && el.value ? el.value : def;
    v = String(v).replace(/["'`$\\\n\r]/g, "").replace(/^\s+|\s+$/g, "");
    return v || def;
  }

  function showPage(which) {
    document.getElementById("pageHome").style.display = which === "home" ? "" : "none";
    document.getElementById("pageChunqiu").style.display = which === "chunqiu" ? "" : "none";
    window.scrollTo(0, 0);
  }

  document.addEventListener("click", function (ev) {
    var btn = ev.target.closest ? ev.target.closest("button[data-act]") : null;
    if (!btn) return;
    var act = btn.getAttribute("data-act");

    if (act === "oneclick") run("补装 / 应用设置", MOD + "oneclick.sh", { timeout: 300000 });
    else if (act === "reimport") run("重新导入配置", MOD + "oneclick.sh --reimport", { timeout: 180000 });
    else if (act === "applist") run("重扫名单", MOD + "applist.sh --apply", { timeout: 180000 });
    else if (act === "status") { refreshStatus(); toast("已刷新"); }
    else if (act === "log") run("查看日志", "tail -n 200 /data/adb/hide_bundle.log", { timeout: 20000 });

    else if (act === "keybox") {
      var p1 = pathOf("keyboxPath", "/sdcard/Download/keybox.xml");
      run("替换 keybox (" + p1 + ")", 'sh ' + ROOT + '/scripts/set_keybox.sh "' + p1 + '"', { timeout: 60000 });
    }
    else if (act === "hma") {
      var p2 = pathOf("hmaPath", "/sdcard/Download/HMA-OSS_config.json");
      run("导入 HMA 配置 (" + p2 + ")", 'sh ' + ROOT + '/scripts/import_hma.sh "' + p2 + '"', { timeout: 180000 });
    }
    else if (act === "hma_builtin") {
      run("用包内配置", 'sh ' + ROOT + '/scripts/import_hma.sh "' + ROOT + '/hma/config.json"', { timeout: 180000 });
    }
    else if (act === "detect") {
      toast("开始安装 7 个检测包，请等完成提示");
      run("安装检测软件", 'sh ' + ROOT + '/scripts/install_detectors.sh', { timeout: 600000 });
    }
    else if (act === "noadb") run("关闭无线调试", 'sh ' + ROOT + '/scripts/disable_wireless_adb.sh', { timeout: 30000 });

    else if (act === "openChunqiu") showPage("chunqiu");
    else if (act === "backHome") showPage("home");
    else if (act === "chunqiu") run("部署春秋修复脚本", 'sh ' + ROOT + '/scripts/chunqiu_fix.sh', { target: "chunqiu", timeout: 60000 });
    else if (act === "chunqiuHash") {
      var pc = pathOf("chunqiuPath", "/sdcard/Download/JinBeiChunQiuFixToolPro2.sh");
      run("校验 sha256", 'sha256sum "' + pc + '" 2>&1 || echo "文件不存在：' + pc + '"', { target: "chunqiu", timeout: 30000 });
    }
    else if (act === "chunqiuRunHint") {
      writeTo(out2, "运行方法（交互式菜单，必须在手机上手动跑）：\n\n" +
        "1. 打开 MT 管理器 → 设置 → 勾选「ROOT」\n" +
        "2. 长按 /sdcard/Download/JinBeiChunQiuFixToolPro2.sh\n" +
        "3. 选「以 ROOT 运行」\n" +
        "4. 先跑它菜单里的「自动体检」，再按序号修\n\n" +
        "注意：脚本自带完整性校验，用编辑器改过会拒绝运行。");
    }
  });

  if (!api()) {
    loading.classList.add("hidden");
    statusBox.innerHTML = '<div class="card"><span class="dot"></span><span class="name">需要在模块页里打开本 WebUI</span></div>';
    document.getElementById("pageHome").insertAdjacentHTML("beforeend",
      '<p style="color:var(--warning);font-size:12.5px;margin-top:12px">当前没有 ksu 接口，所有按钮都无法执行。</p>');
    return;
  }

  if (window.ksu && typeof window.ksu.fullScreen === "function") {
    try { window.ksu.fullScreen(true); } catch (e) {}
  }

  refreshStatus().then(function () {
    loading.classList.add("hidden");
  });
})();
