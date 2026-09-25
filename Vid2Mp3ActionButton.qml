import QtQuick
import qs.Commons

Rectangle {
  id: button
  required property color foreground
  required property color dim
  required property string fontFamily
  property string label: ""
  property bool enabled: true
  signal activated()

  height: Style.space(36)
  radius: Style.space(4)
  opacity: enabled ? 1 : 0.45
  color: enabled && mouse.containsMouse ? Qt.rgba(foreground.r, foreground.g, foreground.b, 0.10) : "transparent"
  border.width: 1
  border.color: dim

  Text {
    anchors.centerIn: parent
    text: button.label
    textFormat: Text.PlainText
    color: button.foreground
    font.family: button.fontFamily
    font.pixelSize: Style.font.body
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: button.enabled
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: button.activated()
  }
}
