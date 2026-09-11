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
          spacing: Style.space(8)

          Text {
            text: "Aa"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Bar Dial"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        // Label + live value on the left, reset tucked on the right of the
        // same row — one line instead of three separate ones.
        Item {
          width: parent.width
          height: Math.max(sizeLabel.implicitHeight, resetButton.implicitHeight)

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Text {
              id: sizeLabel
              text: "TEXT SIZE"
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              text: slider.liveValue + "px"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }

          Button {
            id: resetButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Reset"
            fontSize: Style.font.caption
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: if (root.bar) root.bar.run("omarchy display text size reset")
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(6)
          readonly property real sliderWidth: Math.max(0, width - minusButton.width - plusButton.width - spacing * 2)

          Button {
            id: minusButton
            width: Style.space(30)
            text: "−"
            fontSize: Style.font.title
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: if (root.hostWidget) root.hostWidget.apply(root.currentSize - 1)
          }

          PanelSlider {
            id: slider
            bar: root.bar
            width: parent.sliderWidth
            anchors.verticalCenter: parent.verticalCenter
            integer: true
            minimum: root.minSize
            maximum: root.maxSize
            step: 1
            value: root.currentSize
            onReleased: function(v) { if (root.hostWidget) root.hostWidget.apply(v) }
          }

          Button {
            id: plusButton
            width: Style.space(30)
            text: "+"
            fontSize: Style.font.title
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: if (root.hostWidget) root.hostWidget.apply(root.currentSize + 1)
          }
        }
      }
    }
  }
}
