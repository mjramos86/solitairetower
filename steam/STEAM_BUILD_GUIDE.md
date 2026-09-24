# Uploading a build to Steam for review

Step-by-step for **The Solitaire Tower of Doom** — App ID **5007930**, Godot 4.5
+ GodotSteam. "Review" here means getting a runnable build onto the `default`
branch and submitting the app to Valve so they can approve it for release.

---

## Phase 0 — One-time prerequisites

1. **Steamworks access.** You (mjramos86@gmail.com) must be signed in at
   <https://partner.steamgames.com> with the app **5007930** visible on your
   dashboard.
2. **Confirm the depot exists.** Steamworks → app 5007930 → **SteamPipe →
   Depots**. Valve auto-creates a depot when the app is made; note its ID (it is
   usually `5007931`). This guide assumes **depot 5007931 = Windows 64-bit
   content**. Adjust if yours differs.
3. **Install the Steamworks SDK (ContentBuilder).** Download the SDK zip from
   <https://partner.steamgames.com/downloads/list> and unzip it. The tool you
   need is `sdk/tools/ContentBuilder/` which contains `builder/steamcmd.exe`
   (Windows) and example VDF scripts.
4. **Godot export templates.** In the Godot editor: **Editor → Manage Export
   Templates → Download and Install** (must match 4.5-stable).
5. **GodotSteam addon** in the project at `godot/addons/godotsteam/` (the
   GDExtension `.dll`/`.so` and `steamworks` libs), matching Godot 4.5. Without
   it the game still runs, but Steam features (achievements, overlay, presence)
   are inert.

---

## Phase 1 — Create the Godot export preset (first time only)

1. Open the project (`godot/`) in the editor → **Project → Export**.
2. **Add…** one preset per platform: **Windows Desktop**, **Linux/X11**, and
   **macOS**.
3. On each preset set:
   - **Binary format / Architecture:** `x86_64` (64-bit only — matches the
     "64 bit only" box on the store). For macOS pick a universal (Apple Silicon
     + Intel) template so the one `.app` runs on both.
   - **Export Path:** into that platform's build folder, outside the project:
     `build/windows/SolitaireTowerofDoom.exe`,
     `build/linux/SolitaireTowerofDoom.x86_64`,
     `build/mac/SolitaireTowerofDoom.app`.
   - (Optional) **Application → Product/File version:** `0.6.0` to match
     `project.godot`.
   - (macOS) fill in the **code signing / notarisation** fields if you have an
     Apple Developer ID — see the signing warning in Phase 2.
4. Leave "Export With Debug" **off** for the review build.
5. This writes `godot/export_presets.cfg` — commit it so the presets are
   reproducible. **Never commit** the export templates, the built binaries, or
   `steam_appid.txt`.

---

## Phase 2 — Produce the build (every time)

1. Make sure the branch you want to ship is checked out, tests pass, and the
   version in `project.godot` is what you intend.
2. Export a clean build **for each platform** (uncheck "Export With Debug").
   From the editor: **Project → Export → Export Project…**, or headless:
   ```
   godot --headless --path godot --export-release "Windows Desktop" ../build/windows/SolitaireTowerofDoom.exe
   godot --headless --path godot --export-release "Linux/X11"      ../build/linux/SolitaireTowerofDoom.x86_64
   godot --headless --path godot --export-release "macOS"          ../build/mac/SolitaireTowerofDoom.app
   ```
   Each platform ships from its **own folder** (`build/windows/`, `build/linux/`,
   `build/mac/`) — those are the three depot content roots.

3. In each folder, place the Steam runtime bits next to the game binary. Add
   `steam_appid.txt` — a plain text file containing exactly `5007930` — for
   local testing (Steam supplies it in a real install):

   | Platform | Binary | Steam libraries | Notes |
   |---|---|---|---|
   | Windows (depot 5007931) | `SolitaireTowerofDoom.exe` + `.pck` | `steam_api64.dll` + GodotSteam `.dll` | next to the exe |
   | Linux + SteamOS (depot 5007933) | `SolitaireTowerofDoom.x86_64` + `.pck` | `libsteam_api.so` + GodotSteam `.so` | next to the binary; must be executable |
   | macOS (depot 5007932) | `SolitaireTowerofDoom.app` bundle | `libsteam_api.dylib` + GodotSteam `.dylib` | **inside** `SolitaireTowerofDoom.app/Contents/MacOS/` |

4. Sanity-check each build locally with the **Steam client running and signed
   in** — launch it and confirm the log prints
   `[Steam] initialised for App ID 5007930 — signed in as <you>`. Test Mac on a
   Mac and Linux on Linux (or the Deck) where you can; Valve tests that each
   build launches. If it prints "extension not installed" or an init failure,
   fix that before uploading.

   ⚠️ **macOS signing.** Exporting the `.app` from Windows works, but it cannot
   be **code-signed or notarised** without a Mac (or `rcodesign`-style tooling).
   An unsigned `.app` triggers a Gatekeeper "damaged / unidentified developer"
   block and Valve may flag it. Either sign/notarise on a Mac before uploading,
   or hold the macOS depot back and ship Windows + Linux first.

Result: three content-root folders — `build/windows/`, `build/linux/`,
`build/mac/` — each holding that platform's binary + data + `steam_appid.txt`
+ Steam libraries.

---

## Phase 3 — Write the SteamPipe build scripts

These scripts are already in `steam/steampipe/`, one per platform depot plus
the app build that ties them together:

| File | Depot | Content root |
|---|---|---|
| `depot_build_5007931.vdf` | 5007931 Windows | `build/windows/` |
| `depot_build_5007932.vdf` | 5007932 macOS | `build/mac/` |
| `depot_build_5007933.vdf` | 5007933 Linux + SteamOS | `build/linux/` |
| `app_build_5007930.vdf` | — | lists all three depots |

Each depot script sets its own absolute `ContentRoot`, so the three builds live
in separate folders. Confirm the `ContentRoot` paths match where you exported,
and that each `DepotID` matches Steamworks (app 5007930 → SteamPipe → Depots),
with the right **Operating System** set on each depot.

`app_build_5007930.vdf` references them together:
```
"Depots"
{
  "5007931" "depot_build_5007931.vdf"   // Windows
  "5007932" "depot_build_5007932.vdf"   // macOS
  "5007933" "depot_build_5007933.vdf"   // Linux + SteamOS
}
```

Notes:
- **Each depot must be referenced by the app's package(s)** (Steamworks →
  SteamPipe → Depots, or the Packages page). A depot not in a package uploads
  fine but never reaches players — Steamworks shows a red "not referenced by any
  packages" warning until you add it.
- Do **not** set a `"SetLive"` here for a review build — leave it empty so the
  build uploads without going live, then set the branch in the web UI (Phase 5).
- `BuildOutput` is a scratch/log folder; it can be gitignored.
- To ship only some platforms in a given upload, remove the others from the
  `Depots` block for that run (e.g. hold macOS back until it is signed).

---

## Phase 4 — Upload with steamcmd

From the ContentBuilder `builder/` folder:

```
steamcmd.exe +login <your_steam_username> +run_app_build "C:\path\to\steam\steampipe\app_build_5007930.vdf" +quit
```

- First login may prompt for **Steam Guard** — enter the code; it caches after.
- Use a **Steamworks account that has upload/publish permission** on this app.
- On success it prints `Success! App '5007930'` and a **BuildID**.

---

## Phase 5 — Set the build on a branch

1. Steamworks → app 5007930 → **SteamPipe → Builds**.
2. Find your new BuildID. In the **"Set build live on branch"** dropdown choose
   **`default`** (Valve reviews the default branch), then **Preview Change →
   Publish**.
   - Prefer to test privately first? Set it live on a **beta branch** you create
     (e.g. `review`), password-optional, verify it downloads and runs through the
     Steam client, then move it to `default`.
3. Publishing a build change is itself a small publish step — confirm it in the
   yellow banner.

---

## Phase 6 — Make the app reviewable, then submit

A build alone is not "submitted for review." Valve reviews the **whole app**.
Complete these on the app's landing page (Steamworks → app 5007930):

1. **Store page** filled in and set to review-ready (capsules, description,
   screenshots ≥5, trailer, tags, release date). See `steam/README.md` for the
   asset spec.
2. **Default branch has a working build** (Phase 5).
3. **App content / legal:** finish **Edit Store Page → not needed for build
   review**, but you must complete the **"Content Survey"** (violence, etc.) and
   **Build → Ready for review** checklist items shown on the landing page.
4. Click **Submit for review** (store page review) and, for the app itself,
   **"Request review"** on the build/launch checklist. Valve then:
   - runs your `default` build to confirm it launches, and
   - reviews the store page.
5. Turnaround is typically **~5 business days**. You cannot release publicly
   until both the **build/app review** and **store review** pass. Valve also
   enforces the rule that the store page must be live **at least 2 weeks** before
   your chosen release date.

---

## Quick recap (the loop you repeat per build)

```
1. bump version in project.godot
2. export release  -> build/windows/  (+ steam_appid.txt + Steam dlls)
3. launch locally with Steam running -> confirm "[Steam] initialised"
4. steamcmd +run_app_build app_build_5007930.vdf
5. Steamworks -> Builds -> set live on default -> Publish
6. (first submission only) complete store page + Submit for review
```

## Things that trip people up

- **`steam_appid.txt` missing** → build runs but Steam never inits; Valve may
  flag it. Ship it in the content root.
- **Committing binaries** → keep `build/`, export templates, and `steam_appid.txt`
  out of git.
- **Wrong architecture** → export must be `x86_64`; the store is set to
  "64 bit only".
- **Setting a build live before it's tested** → use a beta branch first.
- **Expecting instant release** → review is manual and takes days; submit early.
