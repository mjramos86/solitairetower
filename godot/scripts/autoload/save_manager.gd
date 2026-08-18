extends Node

## Local save file. Replaces the web build's Firebase Auth + Firestore entirely.
##
## The web version had two persistence layers: a `players/{uid}` Firestore
## document for the profile and cloud run-resume, and a `scores_v2` collection
## for the global leaderboard, both behind an email/password account. None of
## that survives the port. There are no accounts, no network calls, and no
## guest/signed-in split — every player has one local profile that always
## persists.
##
## Everything lives in a single JSON file under user://, which Godot resolves to
## the right per-OS location (%APPDATA% on Windows, ~/Library/Application
## Support on macOS, ~/.local/share on Linux). Keeping it under user:// is also
## what makes Steam Cloud work later with no code changes.
##
## Three sections:
##   profile     persistent across runs — banked credits, unlocks, card back
##   run         the in-progress run, so the game can be resumed after quitting
##   highscores  local score table, replacing the online leaderboard
##
## Writes are atomic: a temp file is written and then renamed, so a crash or
## power loss mid-save cannot leave a truncated file behind.

const SAVE_PATH := "user://savegame.json"
const TEMP_PATH := "user://savegame.json.tmp"
const BACKUP_PATH := "user://savegame.bak.json"

## Bumped when the on-disk shape changes; `_migrate` handles older files.
const SAVE_VERSION := 1

const MAX_HIGHSCORES := 20

## Emitted after any successful write, so UI can refresh credit counts.
signal saved
## Emitted when a save file was found to be unreadable and defaults were used.
signal save_corrupted(reason: String)

var profile: Dictionary = {}
var run: Dictionary = {}
var highscores: Array = []

var _dirty := false
var _autosave_accumulator := 0.0

## Seconds between autosaves while a run is in progress.
const AUTOSAVE_INTERVAL := 5.0


static func default_profile() -> Dictionary:
	return {
		"banked_credits": 0,
		"unlocked_connections": [],
		"cardback": "classic",
		"dee_checkin_done": false,
		"seen_dee_topics": [],
		"dee_dialogue3_done": false,
		"seen_dee3_topics": [],
		"dee_final_done": false,
		"seen_compendium": [],
		"revealed_patrons": [],
		"music_volume": 0.7,
		"sfx_volume": 0.7,
		"runs_played": 0,
		"runs_won": 0,
		"game_stats": {},
	}


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	if not _dirty:
		return
	_autosave_accumulator += delta
	if _autosave_accumulator >= AUTOSAVE_INTERVAL:
		_autosave_accumulator = 0.0
		save_game()


## Mark state as changed; the next autosave tick writes it. Cheap to call often.
func mark_dirty() -> void:
	_dirty = true


# ══════════════════════════════════════════════════════════════════════════════
#  Load / save
# ══════════════════════════════════════════════════════════════════════════════

func load_game() -> void:
	profile = default_profile()
	run = {}
	highscores = []

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var text := ""
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		_recover("Could not open %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	text = f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_recover("Save file is not valid JSON")
		return

	var data: Dictionary = parsed
	data = _migrate(data)

	# Merge onto defaults rather than replacing, so a save written by an older
	# build that lacks newer keys still loads with sensible values.
	var loaded_profile = data.get("profile", {})
	if typeof(loaded_profile) == TYPE_DICTIONARY:
		for k in loaded_profile:
			profile[k] = loaded_profile[k]

	var loaded_run = data.get("run", {})
	run = loaded_run if typeof(loaded_run) == TYPE_DICTIONARY else {}

	var loaded_scores = data.get("highscores", [])
	highscores = loaded_scores if typeof(loaded_scores) == TYPE_ARRAY else []


## Writes to a temp file then renames, so an interrupted write cannot corrupt
## the real save. The previous file is kept as a .bak.
func save_game() -> bool:
	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"profile": profile,
		"run": run,
		"highscores": highscores,
	}

	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not write save file: error %d" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("Could not open user:// to finalise save")
		return false
	if dir.file_exists(SAVE_PATH.get_file()):
		dir.copy(SAVE_PATH, BACKUP_PATH)
	var err := dir.rename(TEMP_PATH, SAVE_PATH)
	if err != OK:
		push_error("Could not finalise save file: error %d" % err)
		return false

	_dirty = false
	saved.emit()
	return true


## A save we cannot read is moved aside rather than deleted, so the player can
## send it to us if they report lost progress.
func _recover(reason: String) -> void:
	push_warning("Save unreadable (%s) — starting fresh." % reason)
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(SAVE_PATH.get_file()):
		dir.rename(SAVE_PATH, "user://savegame.corrupt.json")
	profile = default_profile()
	run = {}
	highscores = []
	save_corrupted.emit(reason)


func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version >= SAVE_VERSION:
		return data
	# Version 0 predates this format; nothing shipped with it, so there is
	# nothing to translate. Future migrations chain from here.
	data["version"] = SAVE_VERSION
	return data


# ══════════════════════════════════════════════════════════════════════════════
#  Run persistence — replaces the Firestore cloud-resume
# ══════════════════════════════════════════════════════════════════════════════

func has_run() -> bool:
	return not run.is_empty() and int(run.get("lives", 0)) > 0


func store_run(snapshot: Dictionary) -> void:
	run = snapshot
	mark_dirty()


func clear_run() -> void:
	run = {}
	mark_dirty()


# ══════════════════════════════════════════════════════════════════════════════
#  Profile
# ══════════════════════════════════════════════════════════════════════════════

func add_banked_credits(amount: int) -> void:
	profile["banked_credits"] = int(profile.get("banked_credits", 0)) + amount
	mark_dirty()


func spend_banked_credits(amount: int) -> bool:
	var have := int(profile.get("banked_credits", 0))
	if have < amount:
		return false
	profile["banked_credits"] = have - amount
	mark_dirty()
	return true


func set_cardback(id: String) -> void:
	profile["cardback"] = id
	mark_dirty()


func mark_seen(list_key: String, id: String) -> void:
	var list: Array = profile.get(list_key, [])
	if not list.has(id):
		list.append(id)
		profile[list_key] = list
		mark_dirty()


func has_seen(list_key: String, id: String) -> bool:
	return (profile.get(list_key, []) as Array).has(id)


func reveal_patron(id: String) -> void:
	mark_seen("revealed_patrons", id)


## Whether a patron's identity is revealed. Ported from the web build, where
## `marie.revealed` is not stored on its own — it is derived from John Dee's
## connection being uncovered (unlockConnection/applyProfileToPatrons both do
## `if id == "johndee": mary.revealed = true`). Deriving it here means the link
## holds however the save was written, exactly as the web recompute-on-load did.
func is_patron_revealed(id: String) -> bool:
	if has_seen("revealed_patrons", id):
		return true
	if id == "marie":
		return has_seen("unlocked_connections", "johndee")
	return false


# ══════════════════════════════════════════════════════════════════════════════
#  Local high scores — replaces the Firestore `scores_v2` leaderboard
# ══════════════════════════════════════════════════════════════════════════════

## Records a finished run. Sorted by score desc then time asc, matching the
## ordering the online board used, and capped at MAX_HIGHSCORES.
## Returns the placement index, or -1 if it did not make the table.
func record_score(player_name: String, score: int, time_seconds: float, all_floors: bool) -> int:
	var entry := {
		"name": player_name.strip_edges().substr(0, 24),
		"score": score,
		"time": time_seconds,
		"all_floors": all_floors,
		"date": Time.get_unix_time_from_system(),
	}
	if entry["name"] == "":
		entry["name"] = "Anonymous"

	highscores.append(entry)
	highscores.sort_custom(func(a, b):
		if int(a["score"]) != int(b["score"]):
			return int(a["score"]) > int(b["score"])
		return float(a["time"]) < float(b["time"]))

	if highscores.size() > MAX_HIGHSCORES:
		highscores.resize(MAX_HIGHSCORES)

	mark_dirty()
	save_game()
	return highscores.find(entry)


func record_run_end(won: bool, _score: int, _elapsed: float, leftover_credits: int) -> void:
	profile["runs_played"] = int(profile.get("runs_played", 0)) + 1
	if won:
		profile["runs_won"] = int(profile.get("runs_won", 0)) + 1
	if leftover_credits > 0:
		add_banked_credits(leftover_credits)
	clear_run()
	save_game()


## Per-variant win/loss tally, replacing the Firestore stats document.
func record_game_result(type: String, won: bool) -> void:
	var stats: Dictionary = profile.get("game_stats", {})
	var row: Dictionary = stats.get(type, {"played": 0, "won": 0})
	row["played"] = int(row.get("played", 0)) + 1
	if won:
		row["won"] = int(row.get("won", 0)) + 1
	stats[type] = row
	profile["game_stats"] = stats
	mark_dirty()


## Absolute path of the save file, for a "show my save" button or bug reports.
func save_file_path() -> String:
	return ProjectSettings.globalize_path(SAVE_PATH)


## Wipes everything. Used by a "delete save data" settings option.
func erase_all() -> void:
	var dir := DirAccess.open("user://")
	if dir != null:
		for p in [SAVE_PATH, BACKUP_PATH, TEMP_PATH]:
			if dir.file_exists(p.get_file()):
				dir.remove(p)
	profile = default_profile()
	run = {}
	highscores = []
	_dirty = false
