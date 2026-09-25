import QtQuick
import QtQuick.Layouts
import qs.Ui
import qs.Commons

Item {
  id: row

  required property string entryName
  required property string entryStatus
  required property string entryError
  required property color foreground
  required property color dim
  required property string fontFamily
  property bool removable: true

  signal removeRequested()
  signal openRequested()

  width: parent ? parent.width : 0
  implicitHeight: Style.space(44)

  readonly property string statusGlyph: entryStatus === "converting" ? "⏳"
    : entryStatus === "done" ? "✓"
    : entryStatus === "error" ? "✕"
    : "•"
  readonly property color statusColor: entryStatus === "done" ? "#8fbf8f"
    : entryStatus === "error" ? (row.dim === row.foreground ? "#e08a8a" : "#e08a8a")
    : row.dim
  readonly property string statusLabel: entryStatus === "converting" ? "Converting…"
    : entryStatus === "done" ? "Saved as MP3"
    : entryStatus === "error" ? (entryError !== "" ? entryError : "Failed")
    : "Queued"

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Style.space(4)
    anchors.rightMargin: Style.space(4)
    spacing: Style.space(10)

    Text {
      text: row.statusGlyph
      color: row.statusColor
      font.family: row.fontFamily
      font.pixelSize: Style.font.body
      Layout.preferredWidth: Style.space(16)
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0
      Text {
        Layout.fillWidth: true
        text: row.entryName
        textFormat: Text.PlainText
        color: row.foreground
        elide: Text.ElideRight
        font.family: row.fontFamily
        font.pixelSize: Style.font.body
      }
      Text {
        Layout.fillWidth: true
        text: row.statusLabel
        textFormat: Text.PlainText
        color: row.statusColor
        elide: Text.ElideRight
        font.family: row.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    PanelActionButton {
      visible: row.entryStatus === "done"
      iconText: ""
      tooltipText: "Show in folder"
      foreground: row.foreground
      fontFamily: row.fontFamily
      onClicked: row.openRequested()
    }

    PanelActionButton {
      visible: row.removable && row.entryStatus !== "converting"
      iconText: "✕"
      tooltipText: "Remove"
      foreground: row.foreground
      hoverColor: "#e08a8a"
      fontFamily: row.fontFamily
      onClicked: row.removeRequested()
    }
  }
}
