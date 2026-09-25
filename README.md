# vid2mp3

An [Omarchy](https://omarchy.org/) bar plugin that converts video files to MP3 — drag a video onto the bar icon, or pick files from a popup, and get an MP3 next to the source file. A standalone GTK4 app for bigger batches is included too.

## Screenshots

The bar icon (🎵) sits in the status bar; clicking it opens a popup styled to match Omarchy's built-in panels (OpenVPN, PortWatch):

- Add videos via file picker or by dragging them onto the bar icon
- Convert one or many, with live per-file status (queued / converting / done / failed)
- Open the containing folder or remove a file from the queue
- Desktop notification when a batch finishes and the popup is closed

## Requirements

- [Omarchy](https://omarchy.org/) (Quickshell-based shell), Omarchy 4.x
- `ffmpeg`
- Python 3 with PyGObject (`python3-gobject` / `python-gobject`) and GTK 4 — used for the file-picker dialog

## Install

```sh
git clone https://github.com/G-Pappas/vid2mp3 ~/.config/omarchy/plugins/gpappas.vid2mp3
omarchy plugin enable gpappas.vid2mp3 --section right
```

Or, from within Omarchy:

```sh
omarchy plugin add https://github.com/G-Pappas/vid2mp3 --enable
```

The plugin is self-contained — the bundled `vid2mp3-pick` file picker is resolved relative to the plugin directory, no separate install step needed. The popup's "open full app" button expects the standalone app (see below) on your `PATH`; everything else works without it.

## Remove

```sh
omarchy plugin remove gpappas.vid2mp3
```

Or by hand:

```sh
rm -rf ~/.config/omarchy/plugins/gpappas.vid2mp3
# then remove the "id": "gpappas.vid2mp3" entry from ~/.config/omarchy/shell.json
omarchy restart shell
```

## Using it

- Click the 🎵 bar icon to open the popup — "Add Videos…", "Convert All", per-file status, open-folder/remove actions.
- Drag a video file **onto the bar icon itself** to queue it. (Not onto the popup — see below for why.)
- A desktop notification fires when a batch finishes, if the popup is closed.

### Why drag-and-drop only works on the icon, not inside the popup

Omarchy's panel popups (`KeyboardPanel`) sit behind a full-screen overlay that closes the popup on the first click outside it. Starting a drag from another window (e.g. a file manager) requires that window to receive the initial mouse-down — but the overlay intercepts it first, closing the popup before a drag can land inside it. The bar strip itself is excluded from that overlay so bar icons keep working while a popup is open, which makes the bar icon the only reliable external drop target.

## Standalone app

`standalone-app/vid2mp3` is a full GTK4 + Adwaita window (drag-and-drop, file picker, batch convert, open folder) for when you want a bigger, resizable view than the bar popup gives you — same underlying `ffmpeg` conversion.

```sh
cp standalone-app/vid2mp3 ~/.local/bin/
cp standalone-app/vid2mp3.desktop ~/.local/share/applications/
chmod +x ~/.local/bin/vid2mp3
```

Make sure `~/.local/bin` is on your `PATH`. Launch it from your app grid ("Video to MP3") or by running `vid2mp3`.

## How conversion works

Both the plugin and the standalone app run:

```sh
ffmpeg -y -i <in> -vn -acodec libmp3lame -q:a 2 <out>.mp3
```

Output is written next to the source file.

## License

[MIT](LICENSE)
