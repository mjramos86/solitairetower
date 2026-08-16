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

## Troubleshooting: the .ogv files don't show up in Godot

Run the diagnostic first — it converts nothing and tells you which stage failed:

```bash
bash godot/tools/convert_video.sh --check
```

It prints the exact output directory it will write to, your ffmpeg version,
whether the Theora/Vorbis encoders exist, and whether it can find the source
`.mp4` files. Work through the causes in this order:

**1. `.ogv` files have no Import tab — this is normal.** Unlike textures and
audio, Godot does not *import* video; it loads `.ogv` directly at runtime. If
you selected the file and went looking for an Import tab, its absence is not a
failure. Clicking the file should show a `VideoStreamTheora` in the Inspector.

**2. The editor hasn't rescanned.** Godot rescans when its window regains
focus, but that can miss files created by an external process. Use
**Project → Reload Current Project**. That forces a full rescan and fixes most
cases. Restarting Godot also works.

**3. The files landed outside the project.** Godot's `res://` maps to the
`godot/` folder *only* — anything written to the repo root is invisible to it.
The script prints its output path on the first line for exactly this reason.
Confirm the files are at `godot/assets/video/*.ogv`, not elsewhere. Running the
script with `sh` instead of `bash` used to cause this; the script now refuses to
run under `sh`.

**4. ffmpeg has no Theora encoder.** Not every build ships `libtheora` —
minimal and some Windows builds omit it. The script checks for this up front
now and stops with a clear message. Install a full build
(`brew install ffmpeg`, `sudo apt install ffmpeg`, or the *full* Gyan build on
Windows).

**5. The container has the wrong codec inside.** An `.ogv` whose video stream
isn't actually Theora will be silently rejected by Godot. The script verifies
this with `ffprobe` after each conversion. To check by hand:

```bash
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
  -of csv=p=0 godot/assets/video/tower_menu_animation.ogv
```

This must print `theora`. Anything else — or an error — means the conversion
didn't produce a usable file.

**6. On Windows, `.sh` needs a bash shell.** PowerShell and `cmd` can't run it.
Use **Git Bash** (installed with Git for Windows) or WSL. Or skip the script and
run ffmpeg directly:

```
ffmpeg -y -i "Tower Menu Animation 1400.mp4" -c:v libtheora -q:v 7 -pix_fmt yuv420p -an godot/assets/video/tower_menu_animation.ogv
```

## Manual conversion (any platform, no script)

If the script is more trouble than it's worth, these two commands are all it
does. Run them from the repo root:

```bash
ffmpeg -y -i "Tower Menu Animation 1400.mp4" \
  -c:v libtheora -q:v 7 -pix_fmt yuv420p -an \
  godot/assets/video/tower_menu_animation.ogv

ffmpeg -y -i "winning cinematic.mp4" \
  -c:v libtheora -q:v 7 -pix_fmt yuv420p \
  -c:a libvorbis -q:a 5 \
  godot/assets/video/winning_cinematic.ogv
```

`-pix_fmt yuv420p` is not optional: Theora supports no other pixel format, and
a source in `yuv444p` or with an alpha channel will fail the encode without it.

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
