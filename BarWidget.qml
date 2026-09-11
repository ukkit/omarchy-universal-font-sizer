import QtQuick
import qs.Commons
import qs.Ui

// Bar Dial — scroll the bar widget to resize shell/GTK/terminal text on the
// fly; click opens a panel with a slider and a reset button.
//
// Reads are free: the displayed size is bound straight to the shell's own
// Style.font.baseSize, which already tracks ~/.config/omarchy/shell.toml's
// [font] base-size and hot-reloads on any change, from anywhere.
//
// Writes go through the official `omarchy display text size` CLI rather than
// editing shell.toml ourselves — it already merges into that file safely and
// also scales GTK apps and terminal fonts, so "resize the font" reaches
// further than just this bar.
BarWidget {
  id: root
  moduleName: "io.github.ukkit.bar-dial"

  readonly property int minSize: 8
  readonly property int maxSize: 32

  // Optimistic value shown while a scroll-driven change is in flight, so the
  // bar updates instantly even before the CLI call (which the commitTimer
  // debounces) has actually landed.
  property int pendingSize: Style.font.baseSize
  readonly property int displaySize: commitTimer.running ? pendingSize : Style.font.baseSize
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function clamp(size) { return Math.max(root.minSize, Math.min(root.maxSize, size)) }

  // Applies an absolute size. Used by both the wheel nudge below and the
  // panel's slider/reset controls.
  function apply(size) {
    root.pendingSize = root.clamp(size)
    commitTimer.restart()
  }

  // Scroll ticks accumulate onto whatever is already pending, so a fast
  // multi-notch scroll settles on one CLI call instead of one per notch.
  function nudge(delta) {
    var base = commitTimer.running ? root.pendingSize : Style.font.baseSize
    root.apply(base + delta)
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

  // Coalesces scroll bursts into a single `omarchy display text size` call,
  // the same debounce shape io.github.alexanderpuschkinberlin.keyboard-backlight
  // uses for its own post-action refresh.
  Timer {
    id: commitTimer
    interval: 150
    repeat: false
    onTriggered: if (root.bar) root.bar.run("omarchy display text size " + root.pendingSize)
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
    text: "Aa"
    tooltipText: "Text size: " + root.displaySize + "px · scroll to adjust, click for more"
    onPressed: function(b) { root.toggle() }
    onWheelMoved: function(delta) { root.nudge(delta > 0 ? 1 : -1) }
  }
}
