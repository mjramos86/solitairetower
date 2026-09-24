# SteamPipe upload scripts

Scripts for uploading a build to Steam via `steamcmd`. App ID **5007930**.
Full walkthrough is in `../STEAM_BUILD_GUIDE.md`.

One upload ships all three platforms; each has its own depot and depot script.

| Depot | OS | Script | Content root |
|---|---|---|---|
| 5007931 | Windows | `depot_build_5007931.vdf` | `build\windows\` |
| 5007932 | macOS | `depot_build_5007932.vdf` | `build\mac\` |
| 5007933 | Linux + SteamOS | `depot_build_5007933.vdf` | `build\linux\` |

## Before first use
1. **Confirm the depot IDs** on Steamworks → app 5007930 → SteamPipe → Depots.
   If any differs, rename the matching `depot_build_*.vdf`, update the `DepotID`
   inside it, and update the `Depots` block in `app_build_5007930.vdf`.
2. **Set each depot's Operating System** on that Depots page (Windows / macOS /
   Linux + SteamOS), and make sure **each depot is referenced by the app's
   package(s)** — Steamworks shows a red "not referenced by any packages"
   warning otherwise, and unreferenced depots never reach players.
3. Make sure each build folder exists and contains that platform's release build
   with `steam_appid.txt` (exactly `5007930`) and the Steam runtime library:
   - `build\windows\` — `SolitaireTowerOfDoom.exe` + data + `steam_api64.dll`
   - `build\mac\` — `SolitaireTowerOfDoom.app` (with `libsteam_api.dylib` inside
     `SolitaireTowerOfDoom.app/Contents/MacOS/`); sign/notarise it first
   - `build\linux\` — `SolitaireTowerOfDoom.x86_64` + data + `libsteam_api.so`

## Upload
From `<steamworks_sdk>\tools\ContentBuilder\builder\`:

```
steamcmd.exe +login YOUR_STEAM_USERNAME +run_app_build "C:\Users\mjram\OneDrive\Documents\GitHub\solitairetower\steam\steampipe\app_build_5007930.vdf" +quit
```

Success prints `Success! App '5007930'` and a BuildID.

To ship only some platforms in one run, remove the others from the `Depots`
block in `app_build_5007930.vdf` (e.g. hold macOS back until it is signed).

## Then
Steamworks → SteamPipe → Builds → set that BuildID live on the `default`
branch → Preview Change → Publish. The one build carries all listed platforms.

## Per-build
Bump `Desc` in `app_build_5007930.vdf`, re-export every platform, re-run the
upload command.
