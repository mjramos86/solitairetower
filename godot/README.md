# The Solitaire Tower of Doom — Godot 4 / Steam port

This folder is a ready-to-open Godot 4 project containing every art, audio, and
font asset from the web build, organised into Godot's conventional layout, plus
project settings tuned for a 2D desktop game.

**What is here:** assets, project configuration, an asset-verification scene,
and a working animated tower for the map screen.
**What is not here:** the game itself. `index.html` is 4,590 lines of DOM-driven
solitaire that has to be rewritten as Godot scenes — that is the port, and this
is the foundation it stands on. [Porting notes](#8-porting-notes) at the end.

The web build is untouched. Assets were copied, not moved, so
`solitairedoom.com` keeps deploying from the repo root exactly as before.

```
godot/
├── project.godot              Project settings (renderer, resolution, importers)
├── default_bus_layout.tres    Master / Music / SFX audio buses
├── ASSET_MAP.md               Web filename → Godot filename, with notes
├── assets/
│   ├── cards/backs/           4 selectable card backs (750×1050)
│   ├── patrons/               Compendium portraits
│   ├── intro/                 11 intro cutscene stills
│   ├── ui/                    Title keyart, logo, tower
│   ├── tower/                 Animated map tower: plate + lightning sheet
│   └── _unused/               Alternate art, exclude from export
├── audio/music/               5 tracks    audio/sfx/  2 card sounds
├── fonts/                     6 TTFs + OFL licences
├── scenes/main.tscn           Asset verification screen
├── scenes/tower_menu.tscn     Animated tower (drop-in for the map screen)
└── scripts/asset_paths.gd     Central asset registry
```

**No video, and no video dependency.** The map screen's tower was a looping MP4
in the web build. Godot only plays Ogg Theora, which would have meant an ffmpeg
step for every developer — so the animation was rebuilt as a static plate plus a
lightning sprite sheet instead. Details in [step 5](#5-the-animated-tower).

---

## 1. Install Godot

Download **Godot 4.5 (Standard, not .NET)** from
[godotengine.org/download](https://godotengine.org/download). Standard is the
GDScript build; take .NET only if you specifically want C#.

The project declares `config/features = ("4.5", "GL Compatibility")`. Opening it
in 4.6+ shows a one-click "configuration is from an older version" upgrade
prompt — that is expected and safe. On 4.4 it warns the project is from a newer
version; edit that line in `project.godot` to `"4.4"` if you want to stay there.
Do not use Godot 3.x, none of this is compatible.

Nothing else to install. There is no ffmpeg step and no video codec to worry
about — see [step 5](#5-the-animated-tower).

## 2. Open the project

1. Launch Godot. The Project Manager appears.
2. **Import** → navigate to this repo → select `godot/project.godot` → **Import & Edit**.

Point it at `godot/project.godot`, *not* the repo root. The root has no
`project.godot` and Godot would offer to create one, which is not what you want.

First open takes 10–60 seconds: Godot scans every asset, generates a `.import`
file next to each one, and writes converted resources into `godot/.godot/`.
That folder is the import cache — it is gitignored and rebuilt automatically, so
never commit it and never edit it by hand.

Ignore any "files have been modified on disk" prompt on first launch; that is
just the importer catching up.

## 3. Verify the import

Press **F5** (Run Project). The main scene is a verification screen that attempts
to load every asset in `scripts/asset_paths.gd` and reports the result:

- **Green ✓** — imported correctly.
- **Red ✗** — failed to import or misnamed. Fix before porting anything.

You should also see the six fonts rendered as sample lines, the four card backs
as thumbnails, and two buttons that play the card SFX through the `SFX` bus. If
the fonts render but all look identical, the TTFs did not import — check the
FileSystem dock.

A summary line prints to the Output panel: `Asset check: 37/37 loaded`
(4 card backs, 3 portraits, 11 intro stills, 3 UI, 3 tower, 5 music, 2 SFX,
6 fonts).

Once you start building the real title screen, set
`Project → Project Settings → Application → Run → Main Scene` to it and delete
`scenes/main.tscn` and `scripts/main.gd`.

## 4. Confirm the import settings

`project.godot` presets sensible defaults under `[importer_defaults]`, so this
is a verification pass rather than a configuration one. Select any card back in
the FileSystem dock and open the **Import** tab:

| Setting | Value | Why |
|---|---|---|
| `Compress → Mode` | **Lossless** | VRAM compression puts visible artefacts on flat card art and text. |
| `Mipmaps → Generate` | **Off** | UI drawn at ~1:1; mipmaps only blur it. |
| `Detect 3D → Compress To` | **Disabled** | Stops Godot silently switching 2D textures to VRAM compression if a 3D node ever touches them. This one bites people. |
| `Process → Fix Alpha Border` | **On** | Prevents dark halos on scaled transparent PNGs. |

If you change anything, hit **Reimport**, then **Preset → Set as Default for
'Texture'** to apply it to future files.

For audio, select a track and check the Import tab: leave **Loop** off for SFX,
turn it **on** for the three in-game music tracks and the map track (the web
build sets `audio.loop = true` for those). Reimport after changing.

Fonts need nothing — Godot imports TTFs directly. Antialiasing and hinting
default correctly; if VT323 looks soft at small sizes, set its
**Rendering → Antialiasing** to *Disabled* and **Hinting** to *None* for a
crisper pixel look, which suits the Windows-95 chrome.

## 5. The animated tower

Nothing to do here — it already works. This section explains why it looks the
way it does, because it is the one place the port deliberately diverges from the
web build.

The map screen's tower was `Tower Menu Animation 1400.mp4`, a 5-second, 152-frame
loop at 1400×1866. Godot cannot play MP4 at all; its `VideoStreamPlayer` accepts
only Ogg Theora, which would have meant an ffmpeg conversion step for every
developer who clones this repo, plus a CPU video decoder running behind a menu.

Frame analysis of that clip showed something better: **the tower never moves.**
Every animated pixel is lightning in the sky — the building, the fire, the clock
and the windows are identical in all 152 frames. So the clip was decomposed:

| Layer | File | What it is |
|---|---|---|
| Base | `assets/tower/tower_base.png` | Temporal median of all 152 frames — the tower with every bolt removed |
| Bolts | `assets/tower/tower_lightning_sheet.png` | 9 distinct bolt shapes, isolated by connected-component analysis, packed with soft alpha |
| Frames | `assets/tower/tower_lightning.tres` | `SpriteFrames` whose `AtlasTexture` margins place each bolt back at its original position |

`scenes/tower_menu.tscn` composites them and strikes on a 2–8 second random
timer, reproducing the web build's `scheduleLightning()` exactly, including the
60/40 split between a 0.12 s flash and the 0.6 s stuttering one and the sky-glow
gradient from the `.tower-lightning` CSS.

This is smaller than the video it replaces (2.5 MB of PNG vs 1.2 MB of MP4, but
9.4 MB of VRAM and no decoder), sharper at any resolution, and the strike timing
is now a tunable constant instead of being baked into a loop. It also reunites
two systems the web build had drifted apart: `startTowerAtmosphere()` already
implemented procedural lightning, but sat behind `TOWER_OVERLAYS_ENABLED = false`
because the video supplied its own.

To use it, instance `scenes/tower_menu.tscn` where the map screen's tower goes.
It exposes a `thunder` signal on each strike — the web build synthesises thunder
with the Web Audio API rather than a sample (`playThunder`: filtered noise plus a
40–70 Hz sawtooth), so there is no audio file to import and you will need to
either synthesise or source one.

Tuning is at the top of `scripts/tower_menu.gd`: `STRIKE_DELAY_MIN` /
`STRIKE_DELAY_MAX` and `LONG_FLASH_CHANCE`.

## 6. Add Steam integration (GodotSteam)

Use the **GodotSteam GDExtension**, which drops into a stock Godot install. Do
not use the old "GodotSteam custom engine build" route unless you need something
the extension lacks — the extension means you keep using official Godot binaries
and official export templates.

1. Create your app on [partner.steamgames.com](https://partner.steamgames.com)
   and note the **App ID** (use `480`, Spacewar, for testing before you have one).
2. Download the GDExtension release matching your Godot version from
   [github.com/GodotSteam/GodotSteam-GDExtension/releases](https://github.com/GodotSteam/GodotSteam-GDExtension/releases).
3. Unzip it into `godot/addons/godotsteam/` — it ships the `.gdextension` file
   plus platform binaries.
4. Put the Steamworks redistributable binaries (`steam_api64.dll`,
   `libsteam_api.so`, `libsteam_api.dylib`) beside your exported executable.
   They are **already gitignored** — the Steamworks SDK Access Agreement does
   not allow redistributing them in a public repo, so each developer downloads
   the SDK themselves.
5. Create `steam_appid.txt` next to the executable containing just your App ID.
   Needed for local testing only; Steam supplies it in a real install. Also
   gitignored.
6. Restart Godot. `Steam` is now a global singleton:

```gdscript
func _ready() -> void:
    var result := Steam.steamInitEx(true, YOUR_APP_ID)
    if result["status"] != 0:
        push_error("Steam init failed: %s" % result["verbal"])

func _process(_delta: float) -> void:
    Steam.run_callbacks()   # required every frame, or nothing fires
```

Forgetting `run_callbacks()` is the single most common GodotSteam mistake —
achievements and leaderboards silently never respond.

## 7. Export

1. **Editor → Manage Export Templates → Download and Install** (~800 MB, once
   per Godot version).
2. **Project → Export → Add…** → Windows Desktop / Linux / macOS.
3. On each preset, under **Resources → Filters to exclude**, add:
   ```
   assets/_unused/*
   ```
4. Windows and macOS builds need signing for a clean install experience —
   macOS in particular requires notarisation or players get a Gatekeeper block.
5. Export to a folder **outside** this project (`build/` is gitignored) and drop
   the Steam redistributable binaries in beside the executable.

Ship at minimum a Windows build; Linux costs almost nothing extra and gets you
Steam Deck compatibility, which suits a card game well. The 1280×720 window
override and `expand` stretch mode already handle the Deck's 1280×800 screen.

Upload with SteamPipe (`steamcmd` + an app build script) — see Valve's
[SteamPipe docs](https://partner.steamgames.com/doc/sdk/uploading).

## 8. Porting notes

The assets are done; the game is not. The main things the web build does that
have no automatic Godot equivalent:

**Card faces have no art.** Every card is CSS — a Unicode suit glyph over a
white rounded rectangle. Rebuild as a `Card` scene (`Panel` + `Label`) with a
theme. Details and the alternative in [ASSET_MAP.md](ASSET_MAP.md#there-is-no-card-face-art).

**The whole UI is DOM.** `render()` (`index.html:2016`) rebuilds screens by
regenerating HTML strings on every state change. That maps to Godot as one scene
per screen with signals — there are 11 screens: `title`, `patron-dialogue`,
`map`, `game`, `shop`, `gameover`, `victory`, `victory-dialogue`,
`dee-checkin-dialogue`, `dee-final-dialogue`, `cardback-select`. Immediate-mode
rebuilding is the wrong pattern in Godot; port to retained scenes rather than
translating `render()` literally.

**Five game variants share one state machine.** Klondike, Spider, TriPeaks,
Pyramid, and FreeCell each have `init*`, `*CanDrop`/`*Won`, and `findHints*`
functions. This logic is pure and portable — it is the easiest part to move to
GDScript nearly line for line, and the best place to start. Scoring rules are
already documented in [`../klondike.md`](../klondike.md).

**Firebase must go or change.** The web build uses Firebase Auth (email/password)
and Firestore for the leaderboard (`index.html:24-60`). On Steam you have two
options: replace it with **Steam Leaderboards + Stats** via GodotSteam, which is
the native fit and gives you achievements for free; or keep Firestore and talk to
its REST API through `HTTPRequest`. The former is a better Steam citizen. Note
the Firebase web API key is currently committed in `index.html` — that is normal
for Firebase web apps (it is an identifier, not a secret; `firestore.rules` does
the enforcement), but the desktop port is a natural moment to move off it.

**Saves move to `user://`.** Browser `localStorage` becomes
`FileAccess.open("user://save.cfg", ...)` or a `ConfigFile`. Godot resolves
`user://` to the right per-OS location. Steam Cloud sync is configured in the
partner backend and needs no code changes if you keep saves under `user://`.

**Layout is responsive, not fixed.** The CSS uses `max-width` breakpoints at
600/700/820 px. Godot Control anchors and containers cover this, but the
translation is manual — plan the screens against the 1920×1080 design resolution
set in `project.godot`.

**Intro art is small.** The stills are 260×220 and will upscale poorly at 1080p.
Re-export at 2× when you get the chance; the lossless import settings make it a
straight file swap.
