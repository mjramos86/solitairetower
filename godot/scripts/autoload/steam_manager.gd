extends Node

## Steam bootstrap for the GodotSteam GDExtension.
##
## The Steam singleton is reached DYNAMICALLY through Engine.get_singleton("Steam")
## rather than the global `Steam` class on purpose: that way this script still
## compiles and the game (and the headless test suite) still run on machines
## where the GodotSteam extension is not installed — CI, a plain checkout, or any
## non-Steam launch. Where the extension IS present, this initialises the
## Steamworks API for our App ID and pumps its callbacks every frame.
##
## Setup (per developer, see addons/README.md):
##   1. Drop the GodotSteam GDExtension into godot/addons/godotsteam/.
##   2. Put steam_appid.txt (containing just the App ID) next to the executable
##      — for running from the editor, in the godot/ project root. Gitignored.
##   3. Have the Steam client running while testing.

## The Steamworks App ID for The Solitaire Tower of Doom.
const APP_ID := 5007930

## True once Steamworks initialised successfully this session.
var enabled := false

## True once the current user's stats/achievements have loaded. Until this is
## set, setAchievement/storeStats do not persist. Also announced via stats_ready.
var stats_received := false

## Emitted once the current user's stats have been received (or immediately, if
## this GodotSteam build loads them on init and offers no request call).
signal stats_ready

var _steam: Object = null
var _pending_achievements: Array[String] = []


func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		print("[Steam] GodotSteam extension not installed — running without Steam.")
		return
	_steam = Engine.get_singleton("Steam")

	# Passing the App ID lets GodotSteam set the SteamAppId/SteamGameId
	# environment for us; steam_appid.txt is the fallback. embed_callbacks is
	# false so we pump callbacks ourselves in _process (the classic pattern).
	var result: Dictionary = _steam.steamInitEx(APP_ID, false)
	var status := int(result.get("status", -1))
	if status != 0:  # 0 == STEAM_API_INIT_RESULT_OK
		push_warning("[Steam] init failed (%d): %s" % [status, str(result.get("verbal", ""))])
		_steam = null
		return

	enabled = true
	set_process(true)
	var user_name := "player"
	if _steam.has_method("getPersonaName"):
		user_name = str(_steam.getPersonaName())
	print("[Steam] initialised for App ID %d — signed in as %s" % [APP_ID, user_name])

	# Achievements only persist once the current user's stats are loaded. Request
	# them and mark ready when the callback fires. If this GodotSteam build has no
	# such call/signal, assume it loads stats on init so grants are never blocked.
	if _steam.has_method("requestCurrentStats") and _steam.has_signal("current_stats_received"):
		if not _steam.is_connected("current_stats_received", _on_current_stats_received):
			_steam.connect("current_stats_received", _on_current_stats_received)
		_steam.requestCurrentStats()
	else:
		stats_received = true
		stats_ready.emit()


func _process(_delta: float) -> void:
	# Steamworks fires nothing until its callbacks are pumped. Forgetting this is
	# the single most common GodotSteam mistake.
	if enabled and _steam != null:
		_steam.run_callbacks()


## GodotSteam callback: the current user's stats finished loading.
func _on_current_stats_received(_game_id: int = 0, _result: int = 0, _user_id: int = 0) -> void:
	if stats_received:
		return
	stats_received = true
	stats_ready.emit()


func _exit_tree() -> void:
	if enabled and _steam != null and _steam.has_method("steamShutdown"):
		_steam.steamShutdown()


# ══════════════════════════════════════════════════════════════════════════════
#  Convenience wrappers — all no-ops when Steam is unavailable, so gameplay code
#  can call them unconditionally.
# ══════════════════════════════════════════════════════════════════════════════

## Unlocks a Steam achievement by its API name and flushes it to the backend.
## If the user's stats have not loaded yet, the unlock is queued and applied the
## moment they arrive (Steam rejects setAchievement before then).
func unlock_achievement(api_name: String) -> void:
	if not enabled or _steam == null:
		return
	if not stats_ready:
		if not _pending_achievements.has(api_name):
			_pending_achievements.append(api_name)
		print("[Steam] '%s' queued until stats load" % api_name)
		return
	print("[Steam] unlocking achievement '%s'" % api_name)
	_steam.setAchievement(api_name)
	_steam.storeStats()


## Sets a Rich Presence line shown to friends (e.g. the current floor).
func set_status(text: String) -> void:
	if not enabled or _steam == null:
		return
	_steam.setRichPresence("steam_display", text)
