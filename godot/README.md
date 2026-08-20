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
│   ├── tower/                 76 frames of the map tower animation + .tres
│   └── _unused/               Alternate art, exclude from export
├── audio/music/               5 tracks    audio/sfx/  2 card sounds
├── fonts/                     6 TTFs + OFL licences
├── scenes/app.tscn            Main scene — screen router
├── scenes/screens/           Title, map, game, shop, end
├── scripts/                   core, data, autoload, ui
└── tests/test_runner.gd       479 headless assertions
```

**No video, and no video dependency.** The map screen's tower is an MP4 in the
web build. Godot cannot play MP4, so it ships here as its own frames instead —
the same footage, just decoded ahead of time. Details in
[step 5](#5-the-animated-tower).

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

The first screen is the title. There is no separate asset-check scene any more —
the game itself is the check. If assets were missing, the title keyart, fonts or
card backs would visibly fail.

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

Nothing to do — it already works. This section explains what the asset is.

The map screen's tower is `Tower Menu Animation 1400.mp4` in the web build.
Godot cannot play MP4, and its only video format (Ogg Theora) would have meant
an ffmpeg step for everyone who clones this repo plus a video decoder running
behind a menu. So the clip is shipped as **its own frames**, decoded ahead of
time — the real footage, unaltered, baked lightning and all.

| | |
|---|---|
| Frames | 76, in `assets/tower/frames/` |
| Rate | 15 fps — the source is 30 fps, every second frame kept |
| Loop length | 5.07 s, identical to the original |
| Size | 700×933 per frame, lossless WebP, 37 MB total |
| VRAM | ~199 MB once all frames are resident |

`assets/tower/tower_animation.tres` is a `SpriteFrames` referencing all 76, and
`scenes/tower_menu.tscn` is a `TextureRect` that plays it on a loop. Instance
that scene where the map screen's tower goes; it participates in Control layout,
so anchors and containers position it normally.

Two exported properties on the scene root: `fps` and `playing`. Untick `playing`
to freeze on frame 1 while you lay out the map screen.

**700×933 is the display size, not a downscale of convenience.** The source is
1400×1866, but the tower renders at roughly 700 px wide, so the extra pixels
could never be shown. Storing them would have cost ~140 MB on disk and ~1.6 GB
of VRAM, which does not load on most GPUs.

If you want it lighter or smoother later, re-run the extraction with a different
`fps=` or `scale=` and regenerate the `.tres`:

```bash
ffmpeg -y -i "Tower Menu Animation 1400.mp4" \
  -vf "fps=15,scale=700:933:flags=lanczos" \
  -f image2 -vcodec libwebp -lossless 1 \
  godot/assets/tower/frames/tower_%03d.webp
```

Frame count, VRAM, and disk all scale linearly with `fps`, and with the square
of `scale`. Update `speed` in `tower_animation.tres` and `fps` on the scene root
to match if you change the rate.

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
5. Create `steam_appid.txt` next to the executable — for running from the
   editor, in the `godot/` project root — containing just the App ID
   (`5007930`). Needed for local testing only; Steam supplies it in a real
   install. Gitignored.
6. Restart Godot. Initialisation is already wired up: the **`SteamManager`
   autoload** (`scripts/autoload/steam_manager.gd`) initialises Steamworks for
   App ID `5007930` on boot and pumps `run_callbacks()` every frame. It reaches
   the `Steam` singleton through `Engine.get_singleton("Steam")`, so the project
   still runs and the test suite still passes when the extension is absent — it
   simply logs `running without Steam` and no-ops.

   The current GodotSteam GDExtension signature is
   `steamInitEx(app_id, embed_callbacks)` returning `{status, verbal}` with
   `status == 0` on success (the old leading "retrieve stats" argument was
   removed in SDK 1.61). If a future version changes it, that one call in
   `steam_manager.gd` is the only line to update.

Forgetting `run_callbacks()` is the single most common GodotSteam mistake —
achievements and leaderboards silently never respond; `SteamManager` handles it.

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

## 8. What is ported

The game itself is here, not just its assets.

```
scripts/core/       cards.gd        deck, shuffle, seeded RNG, deep clone
                    hints.gd        legal-move finders for all 5 variants
                    item_effects.gd all 19 shop item effects
                    rules.gd        all 5 variants: deal, legality, win, solver
scripts/data/       game_data.gd    shop stock, floor choices, gold breakdown
                    narrative.gd    all story text, generated from index.html
scripts/autoload/   save_manager.gd local save file (replaces Firebase)
                    run_state.gd    lives/floor/score/gold, floor progression
                    audio_manager.gd music crossfade + SFX pool
scripts/ui/         app.gd          screen router
                    game_screen.gd  the card table, all 5 layouts
                    dialogue_screen.gd  plays all five conversations
                    compendium_screen.gd patrons, lore, unlock economy
                    card_view.gd    card faces, drawn not blitted
                    ui_theme.gd     palette + fonts from the CSS
tests/              test_runner.gd  479 assertions, headless
```

### Accounts are gone, replaced by a local save

The web build kept a Firestore `players/{uid}` document behind an email/password
account, plus a `scores_v2` leaderboard collection, and split players into
"signed in" and "guest" with progress only persisting for the former. All of it
is removed. There is no network code in the project.

In its place, `SaveManager` writes one JSON file to `user://savegame.json`:

| Section | Holds |
|---|---|
| `profile` | banked credits, unlocks, card back, dialogue seen, volumes, lifetime stats |
| `run` | the in-progress run including the dealt board, so a run survives quitting |
| `highscores` | local top-20, replacing the online leaderboard |

Writes are atomic — a temp file is written then renamed, so an interrupted write
cannot truncate the save — and the previous file is kept as `.bak`. A file that
fails to parse is moved to `savegame.corrupt.json` and defaults are used, rather
than crashing or silently wiping progress. Autosave runs every 5 seconds while
dirty, plus on quit.

`user://` resolves per-OS (`%APPDATA%` on Windows, `~/Library/Application
Support` on macOS, `~/.local/share` on Linux), and is exactly what Steam Cloud
expects, so cloud sync needs backend configuration and no code change.

Every player now keeps their progress. There is no sign-in, and nothing is lost
by playing offline.

### Card faces are drawn, not textured

There is still no card face art — `card_view.gd` draws them, the way the CSS
did: white rounded rect, Unicode pip, rank in the corners and a large centre
pip. Resolution-independent, and the only card texture in the build is the back.

### Running the tests

```bash
godot --headless --path godot res://tests/test_runner.tscn
```

Exits non-zero on failure, so it can gate CI. Covers all five rulesets, the
20-points-per-card scoring model, shop and floor progression, a full 10-floor
run, and save round-trip including corruption recovery.

### Deliberate deviation: the easy-floor solvability check

`initKlondike` in the web build reshuffles up to 25 times until
`klGreedySolvable` accepts a deal, so that easy floors are always winnable. That
solver only considered tableau-to-tableau moves onto non-empty columns — it
never played from the waste and never used an empty column. Measured over 200
deals it succeeds **0%** of the time, so the guarantee never held: it burned all
25 shuffles (1.34 s of frozen UI per deal) and returned the last one anyway.

`Rules.klondike_greedy_solvable` adds the two missing move types. The check now
does what it was written to do — 25% of deals pass, easy floors really are
winnable, and deal time drops to 228 ms because it succeeds early instead of
exhausting every attempt.

This does make easy floors genuinely easier than the live web build. To restore
the original behaviour exactly, delete the waste-to-tableau block and the
empty-column case in that function; the comment there marks both.

### Item effects

All 19 items work. `scripts/core/item_effects.gd` holds the effect engine and
`scripts/core/hints.gd` the legal-move finders the hint items depend on.

Effects come in four shapes, and `activate()` returns which one applies rather
than touching the UI, so every item is testable headlessly:

| Shape | Items | Behaviour |
|---|---|---|
| Immediate | Knotted Cord, Mortlake Brew, Sealing Wax, Sealed Letter, Wax Seal Press, Philosopher's Sponge, Skeleton Key, Alchemist's Cabinet, Queen's Patronage, Vial of Quicksilver | Applied at once |
| Timed | Scrying Glass, Astrolabe, Obsidian Mirror, Quill of Ravens | Hint glow / reveal / peek that expires |
| Armed | Athame, Brass Compass, Angelic Besom | Arms a mode; the next board click resolves it |
| Picker | Hermetic Casket, Enochian Key | Opens a card chooser |

An armed item is only consumed on a *successful* target, so clicking a
face-down card with the Athame warns and stays armed. Clicking the item again
cancels. The Alchemist's Cabinet stash is a slot in the inventory bar: click it
with a card selected to stash, click again to place.

### Two bug fixes carried over from the web build

**Sealed Letter destroyed cards.** `executeItemEffect` assigned
`s.stock = [...s.waste].reverse()`, replacing the stock rather than adding to
it. Used while the stock still held cards — which the item invites, since it is
sold as a *free* recycle — those cards were deleted outright, and a board could
become unwinnable with no indication why. Here the recycled waste goes
underneath the remaining stock; a test asserts all 52 cards survive.

**The easy-floor solver never worked.** See the deviation note above.

### Story, dialogue and the compendium

`scripts/data/narrative.gd` holds every line of story content — the 59-beat
intro, John Dee's three interludes with their player-chosen topics, the victory
exchange, and the patron/lore entries behind the compendium.

It was **generated, not retyped.** The arrays were pulled out of `index.html`,
evaluated with Node, and converted mechanically, so the text matches the web
build exactly. Only two transformations were applied: image filenames became
`res://` paths, and `<br>` became a real newline, since Godot Labels take plain
text rather than HTML. A test asserts no HTML survived and that every image
reference resolves.

**One dialogue scene plays all five conversations.** The web build had four
near-identical render functions; here `dialogue_screen.gd` reads which
conversation to play from the screen name, so the router knows nothing about
narrative structure. It handles narration beats, Dee beats, player choices,
multi-image arrangements, the screen-flicker effect, and topic menus that mark
themselves as read.

Dee interrupts after floors 3, 6 and 9 — once per profile, tracked in the save
file rather than per-run, so a second playthrough is uninterrupted.

**The compendium** lists patrons and lore chronologically. Entries can be locked
(a silhouette with only its year), unlocked, or revealed — the last replaces an
alias with a true name. Two purchases spend banked Time Energy: `connection_cost`
uncovers an entry's link to Solitaire, `patron_unlock_cost` brings an
in-development patron forward. John Dee's connection stays sealed until his third
transmission, as in the web build.

Both purchases persist in the local save, so **banked Time Energy now carries
between runs for every player** — in the web build it only survived for
signed-in accounts.

### Not yet ported

The playable loop — title, map, 10 floors, shop, game over, victory — works end
to end. Still outstanding:

- **Drag and drop.** Play is click-to-select, click-to-place, which works with
  mouse, touch and the Deck's trackpad. Dragging is additive.
- **Card back selection screen**, and the win cascade animation.
