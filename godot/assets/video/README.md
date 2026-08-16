# Video assets

**This folder is empty until you run the conversion.**

Godot 4's `VideoStreamPlayer` supports exactly one format: **Ogg Theora
(`.ogv`)**. H.264/MP4 and QuickTime `.MOV` cannot be imported — the editor will
not list them in the FileSystem dock at all. There is no import setting that
changes this; the codec support is not in the engine.

The source masters live at the repo root (still used by the web build). Convert
them from the repo root with:

```bash
./godot/tools/convert_video.sh
```

Produces:

| Source | Output | Notes |
|---|---|---|
| `Tower Menu Animation 1400.mp4` | `tower_menu_animation.ogv` | Map screen loop; audio stripped (muted in the web build) |
| `winning cinematic.mp4` | `winning_cinematic.ogv` | Not wired up in the web build |

Then switch back to the Godot editor so it picks up the new files.

## Consider not using video for the tower loop

Theora is a 2004 codec and Godot decodes it on the CPU with no seek support. For
a short, silent, looping background animation this is a poor trade. An
**`AnimatedTexture`, `AnimatedSprite2D`, or a sprite sheet** will look sharper,
decode for free, and loop seamlessly.

To go that route, export frames instead:

```bash
ffmpeg -i "Tower Menu Animation 1400.mp4" -vf fps=24 godot/assets/video/frames/tower_%03d.png
```

Then select the frames in Godot and build a `SpriteFrames` resource. Reserve
`VideoStreamPlayer` for the long-form cinematic, where the file-size saving
actually matters.
