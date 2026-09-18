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
2. **Add… → Windows Desktop.**
3. Set:
   - **Binary format / Architecture:** `x86_64` (64-bit only — matches the
     "64 bit only" box on the store).
   - **Export Path:** something outside the project, e.g.
     `build/windows/SolitaireTowerOfDoom.exe`.
   - (Optional) **Application → Product/File version:** `0.6.0` to match
     `project.godot`.
4. Leave "Export With Debug" **off** for the review build.
5. This writes `godot/export_presets.cfg` — commit it so the preset is
   reproducible. **Never commit** the export templates, the built binaries, or
   `steam_appid.txt`.

---

## Phase 2 — Produce the build (every time)

1. Make sure the branch you want to ship is checked out, tests pass, and the
   version in `project.godot` is what you intend.
2. Export a clean build. From the editor: **Project → Export → Export
   Project…** (uncheck debug), or headless:
   ```
   godot --headless --path godot --export-release "Windows Desktop" \
     ../build/windows/SolitaireTowerOfDoom.exe
   ```
3. In the **same output folder** as the `.exe`, place:
   - `steam_appid.txt` — a plain text file containing exactly `5007930` (no
     newline fuss, just the number). Required for GodotSteam to init.
   - The **GodotSteam runtime libraries** (`steam_api64.dll` and the GodotSteam
     `.dll`), if not already emitted by the export. The game must find the
     Steam API dll next to the exe.
4. Sanity-check locally: with the **Steam client running and signed in**,
   double-click the exe. The log should print
   `[Steam] initialised for App ID 5007930 — signed in as <you>`. If it prints
   "extension not installed" or an init failure, fix that before uploading —
   Valve tests that the build launches.

Result: a folder (the "content root") holding the exe + data + `steam_appid.txt`
+ Steam dlls, e.g. `build/windows/`.

---

## Phase 3 — Write the SteamPipe build scripts

Put these two files anywhere convenient (e.g. `steam/steampipe/`). Fill in the
absolute path to your content root.

**`depot_build_5007931.vdf`**
```
"DepotBuildConfig"
{
  "DepotID" "5007931"
  "ContentRoot" "C:\path\to\solitairetower\build\windows\"
  "FileMapping"
  {
    "LocalPath" "*"
    "DepotPath" "."
    "recursive" "1"
  }
  "FileExclusion" "*.pdb"
}
```

**`app_build_5007930.vdf`**
```
"AppBuild"
{
  "AppID" "5007930"
  "Desc" "v0.6.0 review build"          // shows in the Builds list

  "ContentRoot" "C:\path\to\solitairetower\build\windows\"
  "BuildOutput" "C:\path\to\solitairetower\steam\steampipe\output\"

  "Depots"
  {
    "5007931" "depot_build_5007931.vdf"
  }
}
```

Notes:
- Do **not** set a `"SetLive"` here for a review build — leave it empty so the
  build uploads without going live, then set the branch in the web UI (Phase 5).
- `BuildOutput` is a scratch/log folder; it can be gitignored.

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
