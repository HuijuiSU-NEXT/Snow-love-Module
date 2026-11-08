/* 一键隐藏 WebUI
 * 兼容 KernelSU / HuijuiSU（BakaSU 系）的模块 WebUI：注入 window.ksu.exec
 * 没有 ksu 时只显示提示，不报错。
 */
(function () {
  "use strict";

  var MOD = "sh /data/adb/modules/hide_bundle/";
  var out = document.getElementById("out");
  var statusBox = document.getElementById("status");
  var hint = document.getElementById("hint");
  var busy = false;

  function api() {
    if (window.ksu && typeof window.ksu.exec === "function") return window.ksu;
    if (window.MagiskWebUI && typeof window.MagiskWebUI.exec === "function") return window.MagiskWebUI;
    return null;
  }

  function write(text) {
    out.textContent = text || "(无输出)";
    out.scrollTop = 0;
  }

  function append(text) {
    out.textContent += text;
    out.scrollTop = out.scrollHeight;
  }

  function toast(msg) {
    var k = api();
    if (k && typeof k.toast === "function") { k.toast(msg); return; }
    console.log(msg);
  }

  function exec(cmd) {
    var k = api();
    if (!k) return Promise.reject(new Error("当前环境不支持 WebUI 命令"));
    return k.exec(cmd);
  }

  function resultText(r) {
    if (!r) return "(无返回)";
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
  }

  function renderStatus(text) {
    var rows = (text || "").split("\n");
    var html = "";
    for (var i = 0; i < rows.length; i++) {
      var line = rows[i].replace(/\s+$/, "");
      if (!line) continue;
      var m = line.match(/^(OK|--)\s+(\S+)\s+(.*)$/);
      if (!m) continue;
      var on = m[1] === "OK";
      html += '<div class="card"><span class="dot' + (on ? " on" : "") + '"></span>' +
              '<span class="name">' + escapeHtml(m[3]) + "</span>" +
              '<span class="key">' + escapeHtml(m[2]) + "</span></div>";
    }
    statusBox.innerHTML = html || '<div class="card">没有状态输出</div>';
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  function refreshStatus() {
    return exec(MOD + "status.sh").then(function (r) {
      renderStatus(resultText(r));
    }).catch(function (e) {
      statusBox.innerHTML = '<div class="card">' + escapeHtml(e.message) + "</div>";
    });
  }

  function run(label, cmd) {
    if (busy) return;
    setBusy(true);
    write("$ " + label + "\n执行中…");
    exec(cmd).then(function (r) {
      write("$ " + label + "\n\n" + resultText(r));
      toast(label + " 完成");
      return refreshStatus();
    }).catch(function (e) {
      write("$ " + label + "\n\n失败：" + e.message);
      toast(label + " 失败");
    }).then(function () {
      setBusy(false);
    });
  }

  document.addEventListener("click", function (ev) {
    var btn = ev.target.closest ? ev.target.closest("button[data-act]") : null;
    if (!btn) return;
    var act = btn.getAttribute("data-act");

    if (act === "oneclick") run("补装 / 应用设置", MOD + "oneclick.sh");
    else if (act === "reimport") run("重新导入配置", MOD + "oneclick.sh --reimport");
    else if (act === "applist") run("重扫名单", MOD + "applist.sh --apply");
    else if (act === "status") { refreshStatus(); toast("已刷新"); }
    else if (act === "log") run("查看日志", "tail -n 200 /data/adb/hide_bundle.log");
  });

  if (!api()) {
    hint.textContent = "没有检测到 ksu 接口：请在 KernelSU / HuijuiSU 的模块页面点「打开」进入，不要在浏览器里直接打开。";
    statusBox.innerHTML = '<div class="card">需要 KernelSU / HuijuiSU 容器</div>';
    return;
  }

  if (window.ksu && typeof window.ksu.fullScreen === "function") {
    try { window.ksu.fullScreen(true); } catch (e) { /* 忽略 */ }
  }

  refreshStatus();
})();
