extends Node

## Steam achievements. Keeps a single source of truth for every achievement's
## Steamworks API name and the condition that unlocks it, and grants them through
## SteamManager (which no-ops cleanly when Steam is absent, so this all runs in the
## headless test suite too).
##
## Design:
##   * grant(id) is idempotent — it unlocks on Steam once, records the id in a
##     session set, and emits `unlocked` for any future in-game UI. We do NOT show
##     our own toast: when Steam is running it pops its own achievement banner, and
##     a second in-game toast would double up.
##   * refresh() re-derives every profile-based achievement from SaveManager's
##     profile. It is cheap and idempotent, so it is safe to call on every save,
##     on load, and right after any triggering action. This is also what makes the
##     count achievements retroactive: a player who already has 100 wins unlocks
##     the moment the profile is next evaluated.
##   * On Steam, the session set is seeded from Steam's own achievement state at
##     startup, so we never re-fire for something already unlocked on the account.

signal unlocked(id: String)

# ── API names (must match the achievements configured in Steamworks) ──
const MEET_JOHN_DEE := "ACH_MEET_JOHN_DEE"          # The original 007
const FIRST_CONNECTION := "ACH_FIRST_CONNECTION"    # Why Solitaire?
const CHANGE_CARDBACK := "ACH_CHANGE_CARDBACK"      # Make yourself at home
const REVEAL_MARY := "ACH_REVEAL_MARY"              # The other Queen
const KLONDIKE_MASTER := "ACH_KLONDIKE_MASTER"      # Klondike Master
const SPIDER_MASTER := "ACH_SPIDER_MASTER"          # Spider Master
const TRIPEAKS_MASTER := "ACH_TRIPEAKS_MASTER"      # Tripeaks Master
const PYRAMID_MASTER := "ACH_PYRAMID_MASTER"        # Pyramid Master
const FREECELL_MASTER := "ACH_FREECELL_MASTER"      # Freecell Master
const PATIENCE := "ACH_PATIENCE"                    # Patience is all you need
const SACRED_SHUFFLE := "ACH_SACRED_SHUFFLE"        # A sacred Destiny (unwired)

## Win thresholds by variant → achievement. Read from game_stats[type]["won"].
const WIN_THRESHOLDS := {
	"klondike": [[100, KLONDIKE_MASTER]],
	"spider": [[100, SPIDER_MASTER]],
	"tripeaks": [[100, TRIPEAKS_MASTER]],
	"pyramid": [[100, PYRAMID_MASTER]],
	"freecell": [[10, FREECELL_MASTER], [25, PATIENCE]],
}

## Every achievement's display metadata, for a Steamworks setup doc and any future
## in-game list. Steam itself renders the localized text configured on its side.
const CATALOG := [
	{"api": MEET_JOHN_DEE, "name": "The original 007", "desc": "Meet John Dee."},
	{"api": FIRST_CONNECTION, "name": "Why Solitaire?",
		"desc": "Uncover any Time Patron's connection to Solitaire in the compendium."},
	{"api": CHANGE_CARDBACK, "name": "Make yourself at home", "desc": "Change your card back."},
	{"api": REVEAL_MARY, "name": "The other Queen", "desc": "Unlock Mary Stuart as a Time Patron."},
	{"api": KLONDIKE_MASTER, "name": "Klondike Master", "desc": "Win 100 Klondike games."},
	{"api": SPIDER_MASTER, "name": "Spider Master", "desc": "Win 100 Spider games."},
	{"api": TRIPEAKS_MASTER, "name": "Tripeaks Master", "desc": "Win 100 TriPeaks games."},
	{"api": PYRAMID_MASTER, "name": "Pyramid Master", "desc": "Win 100 Pyramid games."},
	{"api": FREECELL_MASTER, "name": "Freecell Master", "desc": "Win 10 FreeCell games."},
	{"api": PATIENCE, "name": "Patience is all you need", "desc": "Win 25 FreeCell games."},
	{"api": SACRED_SHUFFLE, "name": "A sacred Destiny", "desc": "Find the Sacred Shuffle."},
]

## API names unlocked this session (prevents re-firing the signal / re-storing).
var _granted := {}


func _ready() -> void:
	if not SaveManager.saved.is_connected(_on_saved):
		SaveManager.saved.connect(_on_saved)
	# On Steam, achievement reads/writes only work once the user's stats have
	# loaded, so wait for that before seeding and the first evaluation. Without
	# Steam (or if stats are already in), do it now. The active slot is already
	# loaded by this point, so existing progress unlocks as soon as we evaluate.
	if SteamManager.enabled and not SteamManager.stats_received:
		if not SteamManager.stats_ready.is_connected(_on_stats_ready):
			SteamManager.stats_ready.connect(_on_stats_ready)
	else:
		_seed_from_steam()
		call_deferred("refresh")


## Steam stats finished loading — safe now to read existing state and grant.
func _on_stats_ready() -> void:
	_seed_from_steam()
	refresh()


func _on_saved() -> void:
	refresh()


## Unlocks an achievement by its Steamworks API name. Idempotent.
func grant(api_name: String) -> void:
	if _granted.has(api_name):
		return
	# On Steam, don't record the grant until the user's stats are loaded — the
	# unlock would silently no-op and, once recorded, never retry. A later
	# refresh() (on stats_ready, or the next save) grants it when the write sticks.
	if SteamManager.enabled and not SteamManager.stats_received:
		return
	_granted[api_name] = true
	SteamManager.unlock_achievement(api_name)
	unlocked.emit(api_name)


func is_granted(api_name: String) -> bool:
	return _granted.has(api_name)


## Re-derives every profile-based achievement. Cheap and idempotent.
func refresh() -> void:
	var profile: Dictionary = SaveManager.profile
	if profile.is_empty():
		return

	# ── The original 007: meet John Dee ──
	# The first-contact dialogue is completed before a run can start, so any prior
	# play with the default patron already counts.
	if bool(profile.get("met_johndee", false)) \
			or int(profile.get("runs_played", 0)) > 0 \
			or not (profile.get("game_stats", {}) as Dictionary).is_empty():
		grant(MEET_JOHN_DEE)

	# ── Make yourself at home: changed the card back away from the default ──
	if String(profile.get("cardback", "classic")) != "classic":
		grant(CHANGE_CARDBACK)

	# ── Why Solitaire?: any compendium connection uncovered ──
	if not (profile.get("unlocked_connections", []) as Array).is_empty():
		grant(FIRST_CONNECTION)

	# ── The other Queen: Mary Stuart revealed ──
	if SaveManager.is_patron_revealed("marie"):
		grant(REVEAL_MARY)

	# ── Variant mastery: win counts ──
	var stats: Dictionary = profile.get("game_stats", {})
	for type in WIN_THRESHOLDS:
		var won := int((stats.get(type, {}) as Dictionary).get("won", 0))
		for pair in WIN_THRESHOLDS[type]:
			if won >= int(pair[0]):
				grant(String(pair[1]))


# ── Explicit trigger helpers, for immediacy right after an action ──

func on_meet_john_dee() -> void:
	SaveManager.profile["met_johndee"] = true
	SaveManager.mark_dirty()
	grant(MEET_JOHN_DEE)


func on_cardback_changed() -> void:
	refresh()


func on_connection_unlocked() -> void:
	refresh()


func on_game_won() -> void:
	refresh()


## Seeds the session set from Steam's own achievement state so we never re-fire
## for something already unlocked on the account. No-op without Steam.
func _seed_from_steam() -> void:
	if not SteamManager.enabled:
		return
	var steam: Object = SteamManager.get("_steam")
	if steam == null or not steam.has_method("getAchievement"):
		return
	for entry in CATALOG:
		var api := String(entry["api"])
		var res = steam.getAchievement(api)
		# GodotSteam returns {"ret":bool, "achieved":bool} (or a bare bool on some
		# builds); treat either shape as "already unlocked".
		var done := false
		if typeof(res) == TYPE_DICTIONARY:
			done = bool(res.get("achieved", false))
		elif typeof(res) == TYPE_BOOL:
			done = res
		if done:
			_granted[api] = true
