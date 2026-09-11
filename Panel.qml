import QtQuick
import qs.Commons
import qs.Ui

// Click-target popup for Bar Dial: a slider covering the same range the bar
// widget's scroll gesture uses, plus a reset button. No IPC/hotkey summon —
// this is a click-only convenience panel, so manageIpc stays off.
Panel {
  id: root
  moduleName: "io.github.ukkit.bar-dial"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property int minSize: hostWidget ? hostWidget.minSize : 8
  readonly property int maxSize: hostWidget ? hostWidget.maxSize : 32
  readonly property int currentSize: hostWidget ? hostWidget.displaySize : Style.font.baseSize

  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function") return bar.switchPanelFrom(hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(280))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Row {
          width: parent.width
          spacing: Style.space(12)

          Text {
            text: "Aa"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Bar Dial"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              text: root.currentSize + "px"
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }
        PanelSectionHeader { text: "TEXT SIZE"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }

        PanelSlider {
          id: slider
          bar: root.bar
          width: parent.width
          integer: true
          minimum: root.minSize
          maximum: root.maxSize
          step: 1
          value: root.currentSize
          onReleased: function(v) { if (root.hostWidget) root.hostWidget.apply(v) }
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: slider.liveValue + "px"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        PanelSeparator { foreground: root.bar.foreground }

        Button {
          width: parent.width
          text: "Reset to default"
          fontSize: Style.font.bodySmall
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          bordered: true
          onClicked: if (root.bar) root.bar.run("omarchy display text size reset")
        }
      }
    }
  }
}
