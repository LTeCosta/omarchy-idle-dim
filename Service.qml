import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Dims the built-in display backlight after a period of inactivity and
// restores the previous brightness on the next activity. Idle inhibitors
// (video playback, `omarchy toggle idle`) keep the display at full brightness.
// `idleSeconds` and `dimPercent` come from this plugin's entry in the
// `plugins` list of ~/.config/omarchy/shell.json, which is only read.
Item {
  id: root

  property var shell: null

  readonly property string pluginId: "io.github.ltecosta.idle-dim"
  property var entry: ({})
  readonly property int idleSeconds: setting("idleSeconds", 300, 30, 7200)
  readonly property int dimPercent: setting("dimPercent", 20, 1, 100)
  readonly property string script: decodeURIComponent(String(Qt.resolvedUrl("idle-dim.sh")).replace(/^file:\/\//, ""))

  function readEntry(text) {
    var next = {}
    try {
      var config = JSON.parse(text)
      var list = config && Array.isArray(config.plugins) ? config.plugins : []
      for (var i = 0; i < list.length; i++)
        if (list[i] && list[i].id === pluginId) next = list[i]
    } catch (e) {}
    entry = next
  }

  // A whole number in [low, high], else the default.
  function setting(key, fallback, low, high) {
    var value = entry[key]
    return typeof value === "number" && value === Math.floor(value) && value >= low && value <= high ? value : fallback
  }

  function run(args) {
    console.log("idle-dim: " + args.join(" "))
    Quickshell.execDetached(["bash", root.script].concat(args))
  }

  IdleMonitor {
    id: idleMonitor
    timeout: root.idleSeconds
    respectInhibitors: true
    onIsIdleChanged: {
      if (isIdle) root.run(["dim", String(root.dimPercent)])
      else root.run(["restore"])
    }
  }

  // A shell restart or plugin reload while dimmed leaves the saved brightness
  // behind; restore it so the display never stays dimmed.
  onIdleSecondsChanged: report()
  onDimPercentChanged: report()

  function report() { console.log("idle-dim: dims to " + dimPercent + "% after " + idleSeconds + " s idle") }

  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.readEntry(text())
    onLoadFailed: root.entry = ({})
  }

  Component.onCompleted: {
    report()
    run(["restore"])
  }
  Component.onDestruction: run(["restore"])
}
