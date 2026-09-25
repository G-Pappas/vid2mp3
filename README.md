# vid2mp3

A drag-and-drop video → MP3 converter for Linux, plus a matching [Omarchy](https://omarchy.org/) status bar plugin.

## What's in here

```
bin/
  vid2mp3            Standalone GTK4 app: drag-and-drop or pick files, batch convert, open folder
desktop/
  vid2mp3.desktop    App-grid launcher entry for the standalone app
omarchy-plugin/
  manifest.json      Omarchy shell plugin manifest (bar-widget)
  Widget.qml         Bar icon + popup: queue, ffmpeg batch conversion, notifications
  Vid2Mp3Row.qml      One row in the popup's file list
  Vid2Mp3ActionButton.qml   Shared button styling
  vid2mp3-pick       Headless GTK4 multi-file picker, used by the popup's "Add Videos…" button
```

Both pieces share the same core: `ffmpeg -y -i <in> -vn -acodec libmp3lame -q:a 2 <out>.mp3`, output written next to the source file.

## Requirements

- `ffmpeg`
- Python 3 with PyGObject (`python3-gobject` / `python-gobject`) and GTK 4
- For the Omarchy plugin: an [Omarchy](https://omarchy.org/) install (Quickshell-based shell)

## Install — standalone app

```sh
cp bin/vid2mp3 ~/.local/bin/
cp desktop/vid2mp3.desktop ~/.local/share/applications/
chmod +x ~/.local/bin/vid2mp3
```

Make sure `~/.local/bin` is on your `PATH`. Launch it from your app grid ("Video to MP3") or by running `vid2mp3`.

## Install — Omarchy bar plugin

```sh
cp -r omarchy-plugin ~/.config/omarchy/plugins/<yourname>.vid2mp3
omarchy plugin enable <yourname>.vid2mp3 --section right
```

The plugin is self-contained — `vid2mp3-pick` is bundled and resolved relative to the plugin directory, so no separate install step is needed for it. The popup's "open full app" button does expect the standalone `vid2mp3` binary on `PATH` (see above); everything else works without it.

## Using the bar plugin

- Click the 🎵 icon to open the popup — "Add Videos…", "Convert All", per-file status, open-folder/remove actions.
- Drag a video file **onto the bar icon itself** to queue it (not onto the popup — see below).
- A desktop notification fires when a batch finishes, if the popup is closed.

### Why drag-and-drop only works on the icon, not inside the popup

Omarchy's panel popups (`KeyboardPanel`) sit behind a full-screen overlay that closes the popup on the first click outside it. Starting a drag from another window (e.g. a file manager) requires that window to receive the initial mouse-down — but the overlay intercepts it first, closing the popup before a drag can land inside it. The bar strip itself is excluded from that overlay so bar icons keep working while a popup is open, which makes the bar icon the only reliable external drop target.

## License

No license file yet — ask before reusing outside personal use.
