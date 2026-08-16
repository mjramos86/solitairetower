# Addons

Empty by design. Godot addons are third-party code and mostly should not be
committed here — install them per-developer.

## GodotSteam (required for the Steam release)

Install the **GDExtension** version, which works with a stock Godot 4 install —
no custom engine build, no custom export templates.

1. Download the release matching your Godot version:
   <https://github.com/GodotSteam/GodotSteam-GDExtension/releases>
2. Unzip into `godot/addons/godotsteam/`.
3. Restart Godot. `Steam` becomes available as a global singleton — no
   Project Settings → Plugins toggle needed for a GDExtension.

The Steamworks redistributable binaries (`steam_api64.dll`, `libsteam_api.so`,
`libsteam_api.dylib`) go **next to your exported executable**, not in this
folder. They are gitignored: the Steamworks SDK Access Agreement does not permit
redistributing them in a public repository, so each developer downloads the SDK
from <https://partner.steamgames.com/downloads/steamworks_sdk.zip> themselves.

See step 6 of [../README.md](../README.md) for the initialisation snippet and
the `run_callbacks()` gotcha.
