extends Node

## Local save file with four independent save slots. Replaces the web build's
## Firebase Auth + Firestore entirely — there are no accounts and no network, and
## instead of one profile per signed-in user there are four on-disk slots the
## player picks between at the menu, each with its own name, profile and
## in-progress run.
##
## Everything lives in one JSON file under user://, which Godot resolves per-OS
## (%APPDATA% on Windows, ~/Library/Application Support on macOS, ~/.local/share
## on Linux). Keeping it under user:// is also what makes Steam Cloud work later.
##
## File shape (version 2):
##   {version, slots:[4], highscores:[...]}
##   each slot: {} (empty) or {name, profile, run, updated_at}
##
## The rest of the game keeps talking to `profile`, `run` and `highscores` as
## before — those always mirror the ACTIVE slot (highscores are shared/global).
## The slot layer sits on top: new_game / load_slot / delete_slot switch which
## slot is active. Writes are atomic (temp file + rename), with a .bak kept.

const SAVE_PATH := "user://savegame.json"
const TEMP_PATH := "user://savegame.json.tmp"
const BACKUP_PATH := "user://savegame.bak.json"

## Bumped when the on-disk shape changes; `_migrate` handles older files.
const SAVE_VERSION := 2

const MAX_HIGHSCORES := 20
const MAX_SLOTS := 4
const MAX_NAME_LEN := 18

## Emitted after any successful write, so UI can refresh credit counts.
signal saved
## Emitted when a save file was found to be unreadable and defaults were used.
signal save_corrupted(reason: String)

## Live state — always mirrors the active slot (highscores are global).
var profile: Dictionary = {}
var run: Dictionary = {}
var highscores: Array = []

## The four slots, each {} or {name, profile, run, updated_at}.
var slots: Array = []
## Which slot the live state mirrors. Defaults to 0 so the low-level API works
## before the player has explicitly chosen a slot at the menu.
var active_slot := 0
## The active slot's player name, shown on the tower map and the card table.
var player_name := ""

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


static func _empty_slots() -> Array:
	var s := []
	for i in MAX_SLOTS:
		s.append({})
	return s


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
	slots = _empty_slots()
	highscores = []
	active_slot = 0
	_load_active_defaults()

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		_recover("Could not open %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	var text := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_recover("Save file is not valid JSON")
		return

	var data: Dictionary = _migrate(parsed)

	var loaded_slots = data.get("slots", [])
	if typeof(loaded_slots) == TYPE_ARRAY:
		for i in MAX_SLOTS:
			if i < loaded_slots.size() and typeof(loaded_slots[i]) == TYPE_DICTIONARY:
				slots[i] = loaded_slots[i]

	var loaded_scores = data.get("highscores", [])
	highscores = loaded_scores if typeof(loaded_scores) == TYPE_ARRAY else []

	_sync_from_slot()


## Writes to a temp file then renames, so an interrupted write cannot corrupt the
## real save. The previous file is kept as a .bak.
func save_game() -> bool:
	_sync_to_slot()

	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"slots": slots,
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
	slots = _empty_slots()
	highscores = []
	active_slot = 0
	_load_active_defaults()
	save_corrupted.emit(reason)


func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version >= SAVE_VERSION:
		return data
	# Version 1 stored a single {profile, run, highscores}. Fold that lone profile
	# into slot 0 named "Player 1" so existing players keep their progress.
	if version == 1 or data.has("profile"):
		var migrated := {"version": SAVE_VERSION, "slots": _empty_slots(),
			"highscores": data.get("highscores", [])}
		var old_profile = data.get("profile", {})
		if typeof(old_profile) == TYPE_DICTIONARY and not old_profile.is_empty():
			migrated["slots"][0] = {
				"name": "Player 1",
				"profile": old_profile,
				"run": data.get("run", {}),
				"updated_at": Time.get_unix_time_from_system(),
			}
		return migrated
	data["version"] = SAVE_VERSION
	return data


# ══════════════════════════════════════════════════════════════════════════════
#  Save slots
# ══════════════════════════════════════════════════════════════════════════════

func _load_active_defaults() -> void:
	profile = default_profile()
	run = {}
	player_name = ""


## Copies the live state into the active slot before a write.
func _sync_to_slot() -> void:
	if active_slot < 0 or active_slot >= MAX_SLOTS:
		return
	slots[active_slot] = {
		"name": player_name,
		"profile": profile,
		"run": run,
		"updated_at": Time.get_unix_time_from_system(),
	}


## Loads the active slot into the live state, filling defaults for missing keys
## so a slot written by an older build still loads.
func _sync_from_slot() -> void:
	var slot: Dictionary = slots[active_slot] if active_slot >= 0 and active_slot < MAX_SLOTS else {}
	player_name = str(slot.get("name", ""))
	profile = default_profile()
	var loaded_profile = slot.get("profile", {})
	if typeof(loaded_profile) == TYPE_DICTIONARY:
		for k in loaded_profile:
			profile[k] = loaded_profile[k]
	var loaded_run = slot.get("run", {})
	run = loaded_run if typeof(loaded_run) == TYPE_DICTIONARY else {}


## A slot counts as used once it has a non-empty player name — every real slot is
## created through new_game, which sets one.
func slot_exists(index: int) -> bool:
	if index < 0 or index >= MAX_SLOTS:
		return false
	var slot: Dictionary = slots[index]
	return slot.has("name") and str(slot.get("name", "")).strip_edges() != ""


func any_slot_exists() -> bool:
	for i in MAX_SLOTS:
		if slot_exists(i):
			return true
	return false


## A compact description of a slot for the slot-select screen.
func slot_summary(index: int) -> Dictionary:
	if not slot_exists(index):
		return {"index": index, "exists": false}
	var slot: Dictionary = slots[index]
	var slot_run: Dictionary = slot.get("run", {})
	var slot_profile: Dictionary = slot.get("profile", {})
	var has_active_run := not slot_run.is_empty() and int(slot_run.get("lives", 0)) > 0
	var floor_index := int(slot_run.get("floor", 0))
	return {
		"index": index,
		"exists": true,
		"name": str(slot.get("name", "")),
		"has_run": has_active_run,
		"floor": GameData.TOTAL_FLOORS - floor_index if has_active_run else GameData.TOTAL_FLOORS,
		"banked_credits": int(slot_profile.get("banked_credits", 0)),
		"runs_won": int(slot_profile.get("runs_won", 0)),
		"updated_at": float(slot.get("updated_at", 0.0)),
	}


## Starts a fresh save in a slot with the given name and makes it active. The
## run itself is set up later by RunState.new_run; this just creates the profile.
func new_game(index: int, name: String) -> void:
	if index < 0 or index >= MAX_SLOTS:
		return
	active_slot = index
	player_name = name.strip_edges().substr(0, MAX_NAME_LEN)
	if player_name == "":
		player_name = "Player %d" % (index + 1)
	profile = default_profile()
	run = {}
	_sync_to_slot()
	save_game()


## Makes a slot active and loads its data. Returns true if it holds a resumable
## run.
func load_slot(index: int) -> bool:
	if not slot_exists(index):
		return false
	active_slot = index
	_sync_from_slot()
	return has_run()


## Wipes a slot. If it was the active one, the live state resets to defaults.
func delete_slot(index: int) -> void:
	if index < 0 or index >= MAX_SLOTS:
		return
	slots[index] = {}
	if index == active_slot:
		_load_active_defaults()
	save_game()


func set_player_name(name: String) -> void:
	player_name = name.strip_edges().substr(0, MAX_NAME_LEN)
	mark_dirty()


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
## `marie.revealed` is derived from John Dee's connection being uncovered.
func is_patron_revealed(id: String) -> bool:
	if has_seen("revealed_patrons", id):
		return true
	if id == "marie":
		return has_seen("unlocked_connections", "johndee")
	return false


# ══════════════════════════════════════════════════════════════════════════════
#  Local high scores — global across slots, replacing the Firestore leaderboard
# ══════════════════════════════════════════════════════════════════════════════

## Records a finished run. Sorted by score desc then time asc, capped at
## MAX_HIGHSCORES. Returns the placement index, or -1 if it did not make the table.
func record_score(player: String, score: int, time_seconds: float, all_floors: bool) -> int:
	var entry := {
		"name": player.strip_edges().substr(0, 24),
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


## Wipes everything. Used by a "delete save data" settings option and by tests.
func erase_all() -> void:
	var dir := DirAccess.open("user://")
	if dir != null:
		for p in [SAVE_PATH, BACKUP_PATH, TEMP_PATH]:
			if dir.file_exists(p.get_file()):
				dir.remove(p)
	slots = _empty_slots()
	highscores = []
	active_slot = 0
	_load_active_defaults()
	_dirty = false
