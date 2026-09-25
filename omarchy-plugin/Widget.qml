import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "gpappas.vid2mp3"
  ipcTarget: "gpappas.vid2mp3"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string musicIcon: "🎵"

  property var queue: []
  property int activeIndex: -1
  property int batchDone: 0
  property int batchError: 0

  readonly property int queuedCount: {
    var n = 0
    for (var i = 0; i < queue.length; i++) if (queue[i].status === "queued") n++
    return n
  }
  readonly property int doneCount: {
    var n = 0
    for (var i = 0; i < queue.length; i++) if (queue[i].status === "done") n++
    return n
  }
  readonly property int errorCount: {
    var n = 0
    for (var i = 0; i < queue.length; i++) if (queue[i].status === "error") n++
    return n
  }
  readonly property bool converting: activeIndex >= 0
  readonly property string statusText: converting
    ? "Converting " + (activeIndex + 1) + " of " + queue.length + "…"
    : queue.length === 0 ? "Drag onto icon or add files"
    : queuedCount > 0 ? queuedCount + " queued"
    : (doneCount + " converted" + (errorCount > 0 ? " · " + errorCount + " failed" : ""))
  readonly property string tooltip: "Video to MP3 — " + statusText

  readonly property var videoExts: ["webm", "mp4", "mkv", "mov", "avi", "flv", "wmv", "m4v", "mpg", "mpeg", "ts", "3gp", "ogv"]

  function extOf(path) {
    var m = path.match(/\.([^./]+)$/)
    return m ? m[1].toLowerCase() : ""
  }

  function nameOf(path) {
    return path.substring(path.lastIndexOf("/") + 1)
  }

  function dirOf(path) {
    var i = path.lastIndexOf("/")
    return i >= 0 ? path.substring(0, i) : path
  }

  function addPaths(paths) {
    var q = queue.slice()
    var added = false
    for (var i = 0; i < paths.length; i++) {
      var p = paths[i]
      if (!p) continue
      if (root.videoExts.indexOf(root.extOf(p)) === -1) continue
      var exists = false
      for (var j = 0; j < q.length; j++) if (q[j].path === p) { exists = true; break }
      if (exists) continue
      q.push({ path: p, name: root.nameOf(p), status: "queued", outPath: "", error: "" })
      added = true
    }
    if (added) root.queue = q
  }

  function removeAt(i) {
    if (root.activeIndex === i) return
    var q = queue.slice()
    q.splice(i, 1)
    root.queue = q
  }

  function clearDone() {
    root.queue = queue.filter(function(e) { return e.status !== "done" })
  }

  function startConvert() {
    if (root.converting) return
    root.convertNext()
  }

  function convertNext() {
    for (var i = 0; i < root.queue.length; i++) {
      if (root.queue[i].status === "queued") {
        var q = root.queue.slice()
        var entry = Object.assign({}, q[i])
        entry.status = "converting"
        q[i] = entry
        root.queue = q
        root.activeIndex = i

        var outPath = entry.path.replace(/\.[^./]+$/, "") + ".mp3"
        convertProc.targetIndex = i
        convertProc.outPath = outPath
        convertProc.command = ["ffmpeg", "-y", "-i", entry.path, "-vn", "-acodec", "libmp3lame", "-q:a", "2", outPath]
        convertProc.running = true
        return
      }
    }
    root.activeIndex = -1
    if (root.batchDone + root.batchError > 0) {
      root.notifyBatchComplete()
      root.batchDone = 0
      root.batchError = 0
    }
  }

  function notifyBatchComplete() {
    // The popup's own header already shows the result, so a toast on top
    // of it would just be noise — only notify while it's closed.
    if (root.opened) return
    var body = root.batchDone + " file" + (root.batchDone === 1 ? "" : "s") + " converted"
    if (root.batchError > 0) body += " · " + root.batchError + " failed"
    var level = root.batchDone === 0 && root.batchError > 0 ? "2" : "1"
    Quickshell.execDetached(["busctl", "--user", "--", "call",
      "org.freedesktop.Notifications", "/org/freedesktop/Notifications",
      "org.freedesktop.Notifications", "Notify", "susssasa{sv}i",
      "Video to MP3", "0", "audio-x-generic", "Conversion complete", body,
      "0",
      "1", "urgency", "y", level,
      "-1"])
  }

  function openFolder(path) {
    if (root.bar) root.bar.run("/usr/bin/xdg-open " + root.bar.shellQuote(root.dirOf(path)))
  }

  function pickFiles() {
    if (!pickerProc.running) pickerProc.running = true
  }

  // Resolve a script bundled next to this QML file so the plugin works from
  // any user's plugin directory without a hardcoded install path.
  function bundledPath(name) {
    return decodeURIComponent(String(Qt.resolvedUrl(name)).replace(/^file:\/\//, ""))
  }

  function pathsFromDropUrls(urls) {
    var paths = []
    for (var i = 0; i < urls.length; i++) {
      var u = String(urls[i]).replace(/^file:\/\//, "")
      paths.push(decodeURIComponent(u))
    }
    return paths
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onOpenedChanged: if (opened) Qt.callLater(function() { keys.forceActiveFocus() })

  Process {
    id: pickerProc
    command: [root.bundledPath("vid2mp3-pick")]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var paths = text.split("\n").map(function(s) { return s.trim() }).filter(function(s) { return s.length > 0 })
        root.addPaths(paths)
      }
    }
  }

  Process {
    id: convertProc
    property int targetIndex: -1
    property string outPath: ""
    stderr: StdioCollector { waitForEnd: true }
    onExited: function(exitCode) {
      var q = root.queue.slice()
      if (convertProc.targetIndex >= 0 && convertProc.targetIndex < q.length) {
        var entry = Object.assign({}, q[convertProc.targetIndex])
        if (exitCode === 0) {
          entry.status = "done"
          entry.outPath = convertProc.outPath
          root.batchDone++
        } else {
          entry.status = "error"
          entry.error = "ffmpeg exited with code " + exitCode
          root.batchError++
        }
        q[convertProc.targetIndex] = entry
        root.queue = q
      }
      root.activeIndex = -1
      root.convertNext()
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.musicIcon
    slotSize: Style.bar.statusSlot
    tooltipText: root.tooltip
    onPressed: function(code) { if (code === Qt.LeftButton) root.toggle() }
  }

  // Drag-and-drop only works on the bar icon, not inside the popup: while
  // the popup is open, a full-screen overlay closes it on the first click
  // outside its card, which fires before a drag started in another window
  // (e.g. a file manager) can ever land on it. The bar icon sits in the
  // strip that overlay explicitly leaves click-through, so it stays a
  // reachable drop target whether or not the popup is open.
  DropArea {
    id: iconDrop
    anchors.fill: button
    onDropped: function(drop) {
      if (!drop.hasUrls) return
      root.addPaths(root.pathsFromDropUrls(drop.urls))
      root.open()
    }
  }

  Rectangle {
    anchors.fill: button
    visible: iconDrop.containsDrag
    radius: Style.space(4)
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
    border.width: 1
    border.color: root.foreground
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: content
          width: parent.width
          spacing: Style.space(10)

          PanelHero {
            iconComponent: Component {
              Text {
                text: root.musicIcon
                font.pixelSize: Style.font.display
              }
            }
            title: "Video to MP3"
            meta: root.statusText
            foreground: root.foreground
            fontFamily: root.fontFamily
            trailingControl: Component {
              PanelActionButton {
                iconText: "⬚"
                tooltipText: "Open full app"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: if (root.bar) root.bar.run("vid2mp3")
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          Text {
            width: parent.width
            text: "Tip: drag video files onto the 🎵 bar icon to queue them."
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            width: parent.width
            spacing: Style.space(10)

            Vid2Mp3ActionButton {
              width: (parent.width - Style.space(10)) / 2
              foreground: root.foreground
              dim: root.dim
              fontFamily: root.fontFamily
              label: "Add Videos…"
              onActivated: root.pickFiles()
            }

            Vid2Mp3ActionButton {
              width: (parent.width - Style.space(10)) / 2
              foreground: root.foreground
              dim: root.dim
              fontFamily: root.fontFamily
              label: root.converting ? "Converting…" : "Convert All"
              enabled: !root.converting && root.queuedCount > 0
              onActivated: root.startConvert()
            }
          }

          PanelSeparator { visible: root.queue.length > 0; foreground: root.foreground }

          Text {
            visible: root.queue.length === 0
            width: parent.width
            text: "No files yet. Drag videos onto the bar icon or add them manually."
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Column {
            width: parent.width
            spacing: Style.space(2)
            visible: root.queue.length > 0

            Repeater {
              model: root.queue
              delegate: Vid2Mp3Row {
                required property var modelData
                required property int index
                entryName: modelData.name
                entryStatus: modelData.status
                entryError: modelData.error
                foreground: root.foreground
                dim: root.dim
                fontFamily: root.fontFamily
                onRemoveRequested: root.removeAt(index)
                onOpenRequested: root.openFolder(modelData.path)
              }
            }
          }

          Text {
            visible: root.doneCount > 0
            width: parent.width
            text: "Clear completed"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            MouseArea {
              anchors.fill: parent
              anchors.margins: -Style.space(4)
              cursorShape: Qt.PointingHandCursor
              onClicked: root.clearDone()
            }
          }
        }
      }
    }
  }
}
