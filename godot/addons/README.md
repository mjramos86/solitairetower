# Addons

Empty by design. Godot addons are third-party code and mostly should not be
committed here — install them per-developer. GodotSteam in particular is
gitignored (the Steamworks binaries may not be redistributed in a public repo).

---

# Installing GodotSteam (required for Steam features)

The game talks to Steam through the **GodotSteam GDExtension**, which works with a
stock Godot 4 install — no custom engine build, no custom export templates. The
same install is required to test in the editor AND to ship: without it the game
runs fine but every Steam feature (achievements, overlay, cloud) is silently
disabled (`SteamManager` no-ops when the `Steam` singleton is absent).

App ID: **5007930**. Tested against Godot **4.5** with GodotSteam **4.22.1**
(Steamworks SDK 1.65).

## 1. Prerequisites
- The **Steam client installed and running**, signed into an account that has
  access to app 5007930.
- The 11 achievements **created and PUBLISHED** in Steamworks (see
  `../../steam/ACHIEVEMENTS.md`). Creating without publishing does nothing.

## 2. Download the GDExtension build
- Go to <https://github.com/GodotSteam/GodotSteam/releases> (or codeberg mirror).
- Download the release that says **GDExtension** and **Godot 4.x** — e.g.
  `GodotSteam 4.22.1`. Do **not** grab the "module"/precompiled-editor build; the
  GDExtension is the one that drops into a normal Godot.

## 3. Unzip into the project
- The zip contains an `addons/godotsteam/` folder. Copy it so the final path is:
  ```
  godot/addons/godotsteam/godotsteam.gdextension
  godot/addons/godotsteam/win64/…      (libgodotsteam.windows.*.dll + steam_api64.dll)
  godot/addons/godotsteam/linuxbsd/…   (libgodotsteam.linux.*.so  + libsteam_api.so)
  godot/addons/godotsteam/macos/…      (libgodotsteam.macos.*      + libsteam_api.dylib)
  ```
  (Exact subfolder names vary by release — keep whatever the zip ships; do not
  rename them, the `.gdextension` file points at them.)

## 4. steam_appid.txt (dev only)
- Create a file `steam_appid.txt` containing just `5007930` in the Godot project
  root (`godot/`), next to `project.godot`. This lets the editor and dev builds
  attach to Steam without launching through the client.
- It is gitignored. **Do not ship it** in the store build — Steam provides the
  App ID to a released game itself.

## 5. Restart Godot and verify
- Fully close and reopen Godot (GDExtensions load at startup). No Project
  Settings → Plugins toggle is needed for a GDExtension.
- Run the game from the editor **with Steam running**. The output log should show:
  ```
  [Steam] initialised for App ID 5007930 — signed in as <you>
  [Steam] stats received (result 1) — flushing 0 queued achievement(s)
  ```
- If instead you see `GodotSteam extension not installed`, the folder/paths are
  wrong or Godot wasn't restarted.

## 6. Test an achievement
- Trigger one (e.g. change your card back → `ACH_CHANGE_CARDBACK`, or clear a
  floor). The log prints `[Steam] unlocking achievement '…'` and Steam pops its
  banner. Reset while testing via Steamworks → your app → *Achievements* →
  *Reset stats*, or the Steam console `reset_all_stats`.

## 7. Exporting a build that includes Steam
- The `.gdextension` libraries are packed into the export automatically **as long
  as `addons/godotsteam/` exists at export time** — so make sure it's present
  before you export (it's gitignored, so a fresh clone won't have it).
- The Steamworks redistributable must sit **next to the exported executable**:
  - Windows: `steam_api64.dll` beside `SolitaireTowerofDoom.exe`
  - Linux: `libsteam_api.so` beside the binary
  - macOS: `libsteam_api.dylib` inside the `.app` bundle
  These ship inside the GodotSteam addon's platform folders — copy the matching
  one next to the exe if the export didn't place it there.
- Do **not** include `steam_appid.txt` in the store build.
- Verify: launch the exported build **through Steam** and confirm the same
  `[Steam] initialised …` / `stats received` log lines.

## Why it's not in the repo
The Steamworks redistributables (`steam_api64.dll`, `libsteam_api.so`,
`libsteam_api.dylib`) are covered by the Steamworks SDK Access Agreement, which
does not permit redistributing them in a public repository. Each developer
installs GodotSteam locally. See step 6 of [../README.md](../README.md) for the
initialisation snippet and the `run_callbacks()` gotcha.
