## Yua Loop Video

If you want to temporarily replace the current background + character art with a single loop video:

1. Convert your source clip to `OGV` / Theora format.
2. Put the file here as:
   `assets/video/yua_idle_loop.ogv`

The main scene will automatically switch into video mode when that file exists.

To switch back to the normal background + character setup:

1. Remove or rename `assets/video/yua_idle_loop.ogv`

Notes:

- This project keeps the old art setup intact on purpose, so reverting is easy.
- The current source clip you provided is `.mp4`, which Godot stable does not use directly for `VideoStreamPlayer`.
- If needed, convert with a tool such as FFmpeg or Shutter Encoder before placing it here.
