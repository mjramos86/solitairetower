# Asset map — web build → Godot project

Every file was **copied**, not moved. The web game at `solitairedoom.com` deploys
from the repo root via `.github/workflows/deploy.yml`, so the originals stay
exactly where they are and keep working.

Names were normalised on the way in: lowercase, `snake_case`, no spaces, no
double extensions. `res://` paths containing spaces work in Godot but make
`load()` calls, shell scripts, and export filters needlessly fragile.

## Card backs — `res://assets/cards/backs/`

All 750×1050. Keys match the `id` field in the web build's `CARDBACKS` array, so
existing save data keeps selecting the right back.

| id | Web file | Godot file |
|---|---|---|
| `classic` | `Cardback Tower - 2.png.png` | `cardback_tower.png` |
| `cult` | `Cardback Cult Leader.jpg` | `cardback_cult.jpg` |
| `dee` | `Cardback_Dee1.png` | `cardback_dee.png` |
| `marie` | `Cardback Mary Stuart V2.png` | `cardback_mary.png` |

## Patron / compendium portraits — `res://assets/patrons/`

| id | Web file | Godot file |
|---|---|---|
| `johndee` | `JohnDee.jpg` (880×880) | `john_dee.jpg` |
| `marie` | `Portrait Mary Stuart V2.png` (1465×2200) | `mary_stuart_portrait.png` |
| `cult` | ⚠️ `Cardback_cult2.png` — **missing** | `cult_of_patience.jpg` |

⚠️ The web build's cult compendium entry (`index.html:1438`) points at
`Cardback_cult2.png`, which was deleted in commit `176727b` and never replaced —
that image is broken on the live site today. `Cardback Cult Leader.jpg` was
added later and is the obvious stand-in, so the Godot project uses it. Swap in
different art if that was not the intent.

## Intro cutscene stills — `res://assets/intro/`

| Web file | Godot file | Size |
|---|---|---|
| `Introclick1.png` | `intro_click_1.png` | 260×220 |
| `Introclick2.png` | `intro_click_2.png` | 260×220 |
| `Introclick3.png` | `intro_click_3.png` | 260×220 |
| `IntroBounce.png` | `intro_bounce.png` | 260×220 |
| `IntroFaceGlimpse.jpg` | `intro_face_glimpse.jpg` | 260×220 |
| `IntroEyesZoom.jpg` | `intro_eyes_zoom.jpg` | 91×41 |
| `IntroEyesPixel.png` | `intro_eyes_pixel.png` | 3230×1224 |
| `IntroMouthPixel.png` | `intro_mouth_pixel.png` | 105×67 |
| `officer_worker1.png` | `intro_office_worker_1.png` | 87×128 |
| `office_worker2.png` | `intro_office_worker_2.png` | 130×139 |
| `Cult_intro_hi.jpg` | `intro_cult.jpg` | 520×440 |

These are small, low-resolution stills sized for a browser window. At 1920×1080
they will be upscaled heavily. `intro_eyes_zoom.jpg` at 91×41 is the extreme
case — it is shown with `noCrop` as a full-bleed image. Plan on re-exporting the
intro art at 2× if you want it to hold up on a 4K monitor; the import settings in
this project keep them lossless so an upgrade is a drop-in replacement.

## UI / branding — `res://assets/ui/`

| Web file | Godot file | Use |
|---|---|---|
| `Solitaire Tower of Doom Key art - 1.png.png` (2496×1274) | `title_keyart.png` | Title screen (`TITLE_KEYART`) |
| `solitairedoom_favicon.png` (692×692) | `logo_sigil.png` | App icon + boot splash |
| `tower.jpg` (880×1039) | `tower_static.jpg` | Static tower art |

## Audio — `res://audio/`

MP3 imports natively in Godot 4; no conversion needed.

| Web file | Godot file | Use |
|---|---|---|
| `music/Ambiance et musique intro.mp3` | `music/intro_ambience.mp3` | Intro / patron dialogue |
| `music/tim_kulig_...-a-dark-and-stormy-night-420657.mp3` | `music/map_dark_and_stormy_night.mp3` | Tower map |
| `music/leberch-horror-creepy-255685.mp3` | `music/game_horror_creepy.mp3` | In-game (random of 3) |
| `music/leberch-spooky-piano-251474.mp3` | `music/game_spooky_piano.mp3` | In-game (random of 3) |
| `music/leberch-horror-piano-250870.mp3` | `music/game_horror_piano.mp3` | In-game (random of 3) |
| `music/card_taken.mp3` | `sfx/card_taken.mp3` | Card pickup |
| `music/card_moved.mp3` | `sfx/card_moved.mp3` | Card drop |

**Not missing, despite appearances.** `index.html:2287-2296` declares
`MUSIC_TRACKS` / `GAME_TRACKS` referencing five files that are not in the repo
(`Umbral_Rites.mp3`, `The_Spider_s_Waltz.mp3`, `Bone_Altar_Hymn.mp3`,
`Pharaoh_s_Dirge.mp3`, `The_Unveiling_of_the_Golden_Staff.mp3`). `playMusic()`
early-returns with the comment *"Background music removed — tracks to be
replaced"*, so this is dead code, not a broken dependency. Nothing to port
unless you intend to commission those tracks.

## Fonts — `res://fonts/`

Downloaded from the Google Fonts repository as real TTFs, replacing the
`fonts.googleapis.com` stylesheet link — a Steam build has no CDN to fall back
on. All five families are SIL Open Font License 1.1; the licences are in
`fonts/licenses/` and must ship with the game.

| CSS family | File | Weights used |
|---|---|---|
| `Cinzel` | `Cinzel-Variable.ttf` | 400, 600, 700 |
| `EB Garamond` | `EBGaramond-Variable.ttf` | 400, 500 |
| `EB Garamond` *italic* | `EBGaramond-Italic-Variable.ttf` | 400 |
| `Playfair Display` | `PlayfairDisplay-Variable.ttf` | 700, 900 |
| `VT323` (`--pixel`) | `VT323-Regular.ttf` | 400 |
| `Share Tech Mono` | `ShareTechMono-Regular.ttf` | 400 |

The first four are variable fonts — one file covers every weight. Use
`FontVariation` to pick one rather than shipping separate static files:

```gdscript
var heading := FontVariation.new()
heading.base_font = load(AssetPaths.FONTS["display"])
heading.variation_opentype = {"wght": 700}
```

The web build also uses `Georgia`/`Times New Roman` as a fallback stack in one
place. Those are system fonts with no redistributable equivalent — EB Garamond
covers the same role and is already bundled.

## Animated tower — `res://assets/tower/`

The web build's map screen plays `Tower Menu Animation 1400.mp4` (5.07 s, 152
frames, 1400×1866, 30 fps). Godot cannot play MP4, and Ogg Theora — its only
video format — would force an ffmpeg step on every developer. The clip ships as
its own frames instead: the real footage, unaltered.

| Godot file | What it is |
|---|---|
| `frames/tower_001..076.webp` | Every second frame of the clip, 700×933, lossless WebP, 37 MB total |
| `tower_animation.tres` | `SpriteFrames` referencing all 76 at `speed = 15.0`, `loop = true` |

76 frames at 15 fps reproduce the original 5.07-second loop exactly. Frames are
lossless, so the pixels are the decoder's output with nothing re-encoded away.

700×933 is the size the tower is actually displayed at — the source is 2× that,
and those pixels can never reach the screen. Keeping them would have cost about
140 MB on disk and 1.6 GB of VRAM; at display size it is 37 MB and ~199 MB.

`res://scenes/tower_menu.tscn` is a `TextureRect` that plays the loop and sits
in Control layout. It exposes `fps` and `playing` as exported properties.

The source `.mp4` stays at the repo root for the web build. `TowerAnimated.mp4`,
`Tower_Menu_Animation.MOV`, `Intro*.mp4` and `winning cinematic.mp4` are unused
by both builds.

## Unused / alternate art — `res://assets/_unused/`

Kept because you asked for all the assets, but nothing in the game references
them. **Exclude this folder from exports** (Project → Export → Resources →
*Filters to exclude*: `assets/_unused/*`) so it does not inflate the build.

| Web file | Godot file |
|---|---|
| `Cardback Tower.jpg` | `cardback_tower_v1.jpg` |
| `Cardback_MaryQueen1.png` | `cardback_mary_v1.png` |
| `cardback.jpg` | `cardback_legacy.jpg` |
| `solitairedoom_cardback.png` | `cardback_solitairedoom.png` |
| `MaryQueenofScots.png` | `mary_queen_of_scots_small.png` |
| `Solitaire Tower of Doom Key art - 2.png.png` | `title_keyart_alt.png` |
| `SolitaireDoom_Keyart.png` | `keyart_v1.png` |
| `SolitaireDoom_Keyart_notitle.jpg` | `keyart_notitle.jpg` |
| `keyart.jpg` | `keyart_legacy.jpg` |

## Store art — `/steam/` (outside the Godot project)

Marketing art must not ship inside the game build, so it lives in a sibling
folder. See `steam/README.md` for the capsule sizes Valve requires.

## There is no card face art

Worth knowing before you start: the web build has **no images for card faces**.
Every card is HTML and CSS — a Unicode suit glyph (`♠♥♦♣`, `index.html:868`) over
a white rounded rectangle, with rank as text. Only the *backs* are images.

So card faces are the one visual asset with nothing to import. Two options in
Godot, in rough order of effort:

1. **Rebuild in nodes** — a `Card` scene with `Panel` + `Label` children and a
   theme, matching the current CSS. Cheapest, closest to the current look, and
   resolution-independent.
2. **Commission or generate a 52-card sprite sheet** — better if you want the
   Steam version to look less like a browser game. `TextureAtlas` import or a
   single `AtlasTexture` per card.

Option 1 is the direct port and keeps the Windows-95 aesthetic intact.
