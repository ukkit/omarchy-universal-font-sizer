import QtQuick
import qs.Commons
import qs.Ui

// Click-target popup for Universal Font Sizer: a slider covering the same
// range the bar widget's scroll gesture uses, plus a reset button. No
// IPC/hotkey summon — this is a click-only convenience panel, so manageIpc
// stays off.
Panel {
  id: root
  moduleName: "io.github.ukkit.universal-font-sizer"
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
    contentWidth: panel.fittedContentWidth(Style.space(300))
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
            text: "🌐"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Universal Font Sizer"
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
              text: "BASE FONT"
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              // Baseline-locked to sizeLabel rather than center-anchored, so
              // the two differently-sized labels sit on the same text line
              // instead of just sharing a bounding-box center.
              anchors.baseline: sizeLabel.baseline
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
            width: Style.space(26)
            horizontalPadding: Style.space(4)
            verticalPadding: Style.space(2)
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
            width: Style.space(26)
            horizontalPadding: Style.space(4)
            verticalPadding: Style.space(2)
            text: "+"
            fontSize: Style.font.title
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            bordered: true
            onClicked: if (root.hostWidget) root.hostWidget.apply(root.currentSize + 1)
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        // Live preview: three sample sizes scaled by the same multipliers
        // Style.qml uses for its real typography tokens (caption/body/
        // heading), so dragging the slider shows exactly how the rest of
        // the shell's text will move — not just this one number.
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "PREVIEW"
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            spacing: Style.space(18)

            Repeater {
              model: [
                { label: "caption", mult: 0.833 },
                { label: "body", mult: 1.0 },
                { label: "heading", mult: 1.333 }
              ]

              Column {
                required property var modelData
                spacing: Style.space(2)

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Aa"
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Math.max(1, Math.round(slider.liveValue * modelData.mult))
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  color: Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }
      }
    }
  }
}
