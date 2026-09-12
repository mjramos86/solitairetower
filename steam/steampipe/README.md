# SteamPipe upload scripts

Scripts for uploading a build to Steam via `steamcmd`. App ID **5007930**.
Full walkthrough is in `../STEAM_BUILD_GUIDE.md`.

## Before first use
1. **Confirm the depot ID** on Steamworks → app 5007930 → SteamPipe → Depots.
   If it is not `5007931`, rename `depot_build_5007931.vdf` and update the
   `DepotID` in it plus the `Depots` block in `app_build_5007930.vdf`.
2. Make sure the build folder exists and contains the release build:
   `C:\Users\mjram\OneDrive\Documents\GitHub\build\windows\` with
   - `SolitaireTowerOfDoom.exe` + game data
   - `steam_appid.txt` containing exactly `5007930`
   - `steam_api64.dll` (Steam runtime)

## Upload
From `<steamworks_sdk>\tools\ContentBuilder\builder\`:

```
steamcmd.exe +login YOUR_STEAM_USERNAME +run_app_build "C:\Users\mjram\OneDrive\Documents\GitHub\solitairetower\steam\steampipe\app_build_5007930.vdf" +quit
```

Success prints `Success! App '5007930'` and a BuildID.

## Then
Steamworks → SteamPipe → Builds → set that BuildID live on the `default`
branch → Preview Change → Publish.

## Per-build
Bump `Desc` in `app_build_5007930.vdf`, re-export, re-run the upload command.
