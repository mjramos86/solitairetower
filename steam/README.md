# Steam store assets

Marketing art, deliberately kept **outside** the Godot project so it never ships
inside the game build.

## Source files here

| File | Size | Use |
|---|---|---|
| `keyart_source_2496x1274.png` | 2496×1274 | Master for all capsule art |
| `keyart_social_1200x630.jpg` | 1200×630 | Already the right shape for social |
| `logo_sigil_692.png` | 692×692 | Community icon source |

The trailer master, `Solitaire Doom Trailer 1.mp4` (25 MB), stays at the repo
root — it is already H.264/MP4, which is exactly what Valve wants, so no
conversion is needed for the store page.

## What Valve requires

All capsules are PNG or JPG. The 2496×1274 keyart is a good master for the wide
formats but will need recomposition (not just a crop) for the tall and square
ones, since the title lockup will not survive a 1:1 crop.

| Asset | Size | Notes |
|---|---|---|
| Header capsule | 460×215 | The one everyone sees — store search, DLC, related |
| Small capsule | 231×87 | Search results; title must be legible this small |
| Main capsule | 616×353 | Front page features, daily deals |
| Vertical capsule | 374×448 | Front page promos — needs a tall recomposition |
| Page background | 1438×810 | Blurred behind the store page |
| Library capsule | 600×900 | Player's library grid — portrait, no title text needed |
| Library header | 460×215 | Library detail view |
| Library hero | 3840×1240 | Wide banner at the top of the library page |
| Library logo | 1280×720 | Transparent PNG, logo only, sits over the hero |
| Community icon | 184×184 | Derived from `logo_sigil_692.png` |
| Screenshots | 1920×1080 | Minimum 5; Valve prefers no marketing overlay |
| Trailer | 1920×1080, H.264 | 30 s–2 min |

Current sizes and the full spec:
<https://partner.steamgames.com/doc/store/assets>

Valve rejects capsules that are just the logo on a plain background, and
requires the game's name to be legible on every capsule. Budget real design time
for the vertical and library formats — they are not crops of the keyart.
