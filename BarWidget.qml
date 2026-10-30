import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Universal Font Sizer — click the bar widget to open a panel with three
// independent sliders (shell, GTK, terminal) plus reset controls.
//
// Reads: the shell size is bound to Style.font.baseSize, which tracks
// ~/.config/omarchy/shell.toml live. GTK and terminal sizes are read from
// `scripts/font-size-ctl get` on open and after every change.
//
// Writes: all changes go through `scripts/font-size-ctl set|reset`, which
// edits each target on its own. Commands run one at a time from a queue
// keyed by target, so rapid slider/scroll input coalesces to the latest value.
BarWidget {
  id: root
  moduleName: "io.github.ukkit.universal-font-sizer"

  // Valid ranges, mirroring the limits enforced by font-size-ctl.
  readonly property var ranges: ({ shell: [8, 32], gtk: [6, 30], term: [6, 24] })
  readonly property string helper: Qt.resolvedUrl("scripts/font-size-ctl").toString().replace(/^file:\/\//, "")

  // Last known GTK / terminal point sizes read from the helper.
  property int gtkSize: 11
  property int termSize: 9

  // Optimistic values for targets with a write in flight, so sliders don't
  // snap back while the command runs. Cleared once the queue drains.
  property var overrides: ({})

  property var queue: []
  property bool busy: false
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function clamp(target, v) {
    var r = root.ranges[target]
    return Math.max(r[0], Math.min(r[1], v))
  }

  // The value a control should display right now: pending override first,
  // otherwise the last confirmed value.
  function displayed(target) {
    if (root.overrides[target] !== undefined) return root.overrides[target]
    if (target === "shell") return Style.font.baseSize
    if (target === "gtk") return root.gtkSize
    return root.termSize
  }

  // A newer command for the same key replaces one that has not started yet.
  function enqueue(key, cmd) {
    var next = root.queue.filter(function(e) { return e.key !== key })
    next.push({ key: key, cmd: cmd })
    root.queue = next
    runNext()
  }

  function setValue(target, value) {
    console.log("font-sizer DEBUG setValue", target, value)
    var v = root.clamp(target, Math.round(value))
    var o = Object.assign({}, root.overrides)
    o[target] = v
    root.overrides = o
    root.enqueue("set-" + target, ["set", "--" + target, String(v)])
  }

  function reset(target) {
    var o = Object.assign({}, root.overrides)
    delete o[target]
    root.overrides = o
    root.enqueue("reset-" + target, ["reset", target])
  }

  function resetAll() {
    root.overrides = ({})
    root.enqueue("reset-all", ["reset", "all"])
  }

  // Scroll ticks nudge the shell size from whatever is currently displayed.
  function nudge(delta) {
    root.setValue("shell", root.displayed("shell") + delta)
  }

  function runNext() {
    if (root.busy || root.queue.length === 0) return
    var item = root.queue[0]
    root.queue = root.queue.slice(1)
    root.busy = true
    actionProc.command = [root.helper].concat(item.cmd)
    console.log("font-sizer DEBUG spawn", actionProc.command.join(" "))
    actionProc.running = true
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function applyStatus(output) {
    // Ignore status while writes are pending; it would overwrite the optimistic values.
    if (root.busy || root.queue.length > 0) return
    var lines = String(output || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^([a-z-]+)=([0-9]+)$/)
      if (!m) continue
      if (m[1] === "gtk-pt") root.gtkSize = Number(m[2])
      if (m[1] === "term-pt") root.termSize = Number(m[2])
    }
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.anchorItem = button
    target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onOpenedChanged: if (opened) refresh()
  Component.onCompleted: {
    refresh()
    console.log("font-sizer DEBUG helper", root.helper)
  }

  Process {
    id: statusProc
    command: [root.helper, "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
  }

  Process {
    id: actionProc
    onExited: function(code) {
      console.log("font-sizer DEBUG exited", code)
      root.busy = false
      if (root.queue.length > 0) {
        root.runNext()
      } else {
        root.overrides = ({})
        root.refresh()
      }
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "🌐"
    tooltipText: "Shell " + root.displayed("shell") + "px · GTK " + root.displayed("gtk")
                 + "pt · Terminal " + root.displayed("term") + "pt · click to adjust"
    onPressed: function(b) { root.toggle() }
    onWheelMoved: function(delta) { root.nudge(delta > 0 ? 1 : -1) }
  }
}
