import QtQuick
import qs.Commons
import qs.Ui

// Click-target popup for Universal Font Sizer: three independent rows
// (shell base size, GTK interface font, terminal font), each with its own
// slider, steppers and reset. All writes go through the host widget, which
// calls scripts/font-size-ctl. No IPC/hotkey summon, so manageIpc stays off.
Panel {
  id: root
  moduleName: "io.github.ukkit.universal-font-sizer"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  // Shell size the preview shows; follows the shell slider while dragging.
  property int previewPx: Style.font.baseSize

  readonly property var targets: [
    { key: "shell", label: "SHELL", unit: "px", min: 8, max: 32 },
    { key: "gtk", label: "GTK", unit: "pt", min: 6, max: 30 },
    { key: "term", label: "TERMINAL", unit: "pt", min: 6, max: 24 }
  ]

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
        spacing: Style.space(12)

        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            anchors.verticalCenter: parent.verticalCenter
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

        Repeater {
          model: root.targets

          Column {
            id: row
            required property var modelData
            width: content.width
            spacing: Style.space(6)

            // Label + live value on the left, reset on the right.
            Item {
              width: parent.width
              height: Math.max(nameLabel.implicitHeight, resetButton.implicitHeight)

              Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(6)

                Text {
                  id: nameLabel
                  text: row.modelData.label
                  color: Qt.darker(root.bar.foreground, 1.4)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                }

                Text {
                  anchors.baseline: nameLabel.baseline
                  text: slider.liveValue + row.modelData.unit
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
                onClicked: if (root.hostWidget) root.hostWidget.reset(row.modelData.key)
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
                onClicked: { console.log("font-sizer DEBUG minus", row.modelData.key, !!root.hostWidget); if (root.hostWidget) root.hostWidget.setValue(row.modelData.key, root.hostWidget.displayed(row.modelData.key) - 1) }
              }

              PanelSlider {
                id: slider
                bar: root.bar
                width: parent.sliderWidth
                anchors.verticalCenter: parent.verticalCenter
                integer: true
                minimum: row.modelData.min
                maximum: row.modelData.max
                step: 1
                value: root.hostWidget ? root.hostWidget.displayed(row.modelData.key) : row.modelData.min
                onLiveValueChanged: if (row.modelData.key === "shell") root.previewPx = Math.round(liveValue)
                onReleased: function(v) { console.log("font-sizer DEBUG slider released", row.modelData.key, v, !!root.hostWidget); if (root.hostWidget) root.hostWidget.setValue(row.modelData.key, v) }
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
                onClicked: if (root.hostWidget) root.hostWidget.setValue(row.modelData.key, root.hostWidget.displayed(row.modelData.key) + 1)
              }
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        // Shell-size preview: caption/body/heading scaled by the same
        // multipliers Style.qml uses for the real shell typography tokens.
        Row {
          width: parent.width
          spacing: Style.space(18)

          Repeater {
            model: [
              { label: "caption", mult: 0.833 },
              { label: "body", mult: 1.0 },
              { label: "heading", mult: 1.333 }
            ]

            Column {
              required property var modelData
              readonly property int scaledSize: Math.max(1, Math.round(root.previewPx * modelData.mult))
              spacing: Style.space(2)

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Aa"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: scaledSize
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label + " " + scaledSize + "px"
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Button {
          anchors.right: parent.right
          text: "Reset all"
          fontSize: Style.font.caption
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          bordered: true
          onClicked: if (root.hostWidget) root.hostWidget.resetAll()
        }
      }
    }
  }
}
