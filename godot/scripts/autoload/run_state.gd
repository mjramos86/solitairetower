extends Node

## The active run: lives, floor, score, gold, inventory and the current board.
## Ported from the `A` object and the progression functions in index.html.
##
## UI listens to the signals here rather than being told to redraw. The web
## build called a global render() after every mutation; in Godot each screen
## reacts to the specific signal it cares about.

signal screen_changed(screen: String)
signal state_changed
signal score_changed(total: int, delta: int, reason: String)
signal lives_changed(lives: int)
signal floor_cleared(floor: int)
signal game_won
signal run_ended(won: bool)
signal toast(message: String)

const MAX_UNDO_STACK := 50

var screen := "title"

var lives := GameData.STARTING_LIVES
var floor := 0
var choices: Array = []
var done: Array = []

var gtype := ""
var gs: Dictionary = {}
var undo_stack: Array = []
var moves := 0
var win_overlay := false

var score := 0
var score_log: Array = []

var gold := 0
var inventory: Array = []
var shop_items: Array = []
var shop_gold_earned := 0
var shop_gold_breakdown: Array = []

var patron := "johndee"

# Per-floor tracking, for the end-of-floor gold breakdown.
var floor_start_lives := GameData.STARTING_LIVES
var floor_undos_used := 0
var floor_start_time := 0
var floor_start_score := 0

# Active item state.
var bonus_undos := 0
var extra_freecell := false
var toolbox_card = null
var toolbox_uses := 0

var _timer_start := 0
var _timer_elapsed := 0
var _timer_running := false


# ══════════════════════════════════════════════════════════════════════════════
#  Run lifecycle
# ══════════════════════════════════════════════════════════════════════════════

func new_run() -> void:
	lives = GameData.STARTING_LIVES
	floor = 0
	choices = GameData.generate_choices()
	done = []
	gtype = ""
	gs = {}
	undo_stack = []
	moves = 0
	win_overlay = false
	score = 0
	score_log = []
	gold = 0
	inventory = []
	shop_items = []
	shop_gold_earned = 0
	shop_gold_breakdown = []
	patron = "johndee"
	bonus_undos = 0
	extra_freecell = false
	toolbox_card = null
	toolbox_uses = 0
	_timer_start = 0
	_timer_elapsed = 0
	_timer_running = false
	SaveManager.clear_run()
	state_changed.emit()


func set_screen(next: String) -> void:
	screen = next
	screen_changed.emit(next)
	_persist()


func start_game(type: String, target_floor: int) -> void:
	gtype = type
	floor = target_floor
	moves = 0
	undo_stack = []
	win_overlay = false
	floor_start_lives = lives
	floor_undos_used = 0
	floor_start_time = Time.get_ticks_msec()
	floor_start_score = score
	toolbox_card = null
	toolbox_uses = 0
	extra_freecell = false

	gs = Rules.init_game(type, target_floor, extra_freecell)
	start_timer()
	set_screen("game")
	state_changed.emit()


## Clears the floor and routes to the next beat: victory, a patron interlude,
## or the shop. Ported from nextFloor.
func next_floor() -> void:
	if not done.has(floor):
		done.append(floor)
	SaveManager.record_game_result(gtype, true)
	add_score(100 * (GameData.TOTAL_FLOORS - floor), "floor cleared")
	floor_cleared.emit(floor)

	if floor >= GameData.TOTAL_FLOORS - 1:
		stop_timer()
		game_won.emit()
		set_screen("victory-dialogue")
		return

	# John Dee interrupts after floors 3, 6 and 9 (indices 2, 5, 8), once each
	# per profile. Ported from the patron checks in nextFloor.
	var interlude := _pending_interlude()
	if interlude != "":
		stop_timer()
		set_screen(interlude)
		return

	proceed_to_shop()


## Returns the dialogue screen owed at this floor, or "" if none.
func _pending_interlude() -> String:
	if patron != "johndee":
		return ""
	match floor:
		2:
			if not bool(SaveManager.profile.get("dee_checkin_done", false)):
				SaveManager.profile["dee_checkin_done"] = true
				SaveManager.mark_dirty()
				return "dee-checkin-dialogue"
		5:
			if not bool(SaveManager.profile.get("dee_dialogue3_done", false)):
				SaveManager.profile["dee_dialogue3_done"] = true
				SaveManager.mark_dirty()
				return "dee-dialogue3"
		8:
			if not bool(SaveManager.profile.get("dee_final_done", false)):
				SaveManager.profile["dee_final_done"] = true
				SaveManager.mark_dirty()
				return "dee-final-dialogue"
	return ""


func proceed_to_shop() -> void:
	var elapsed := Time.get_ticks_msec() - floor_start_time
	shop_gold_breakdown = GameData.floor_gold_breakdown(
		elapsed, score - floor_start_score, floor_undos_used, lives >= floor_start_lives)
	shop_gold_earned = 0
	for row in shop_gold_breakdown:
		if row["earned"]:
			shop_gold_earned += int(row["amount"])
	gold += shop_gold_earned

	var owned := []
	for it in inventory:
		owned.append(it["id"])
	shop_items = GameData.generate_shop_items(owned)

	floor += 1
	set_screen("shop")
	state_changed.emit()


## Gives up the floor. Consumes a no-life-abandon item if held.
## Returns true when a life was spent.
func abandon_floor() -> bool:
	SaveManager.record_game_result(gtype, false)
	var free_idx := _find_item_by_effect("no-life-abandon")
	if free_idx >= 0:
		inventory.remove_at(free_idx)
		_reset_board_flags()
		set_screen("map")
		state_changed.emit()
		return false
	return _lose_life()


func new_shuffle() -> bool:
	SaveManager.record_game_result(gtype, false)
	if not _lose_life():
		return false
	undo_stack = []
	moves = 0
	floor_undos_used = 0
	floor_start_time = Time.get_ticks_msec()
	floor_start_score = score
	gs = Rules.init_game(gtype, floor, extra_freecell)
	state_changed.emit()
	return true


func _lose_life() -> bool:
	lives -= 1
	lives_changed.emit(lives)
	_reset_board_flags()
	if lives <= 0:
		stop_timer()
		set_screen("gameover")
		end_run(false)
		return false
	set_screen("map")
	state_changed.emit()
	return true


func _reset_board_flags() -> void:
	win_overlay = false


func end_run(won: bool) -> void:
	SaveManager.record_run_end(won, score, get_elapsed_seconds(), gold)
	run_ended.emit(won)


func _find_item_by_effect(effect: String) -> int:
	for i in inventory.size():
		if inventory[i]["effect"] == effect:
			return i
	return -1


# ══════════════════════════════════════════════════════════════════════════════
#  Scoring
# ══════════════════════════════════════════════════════════════════════════════

## Score never drops below zero, matching the web build.
func add_score(amount: int, reason: String = "") -> void:
	if amount == 0:
		return
	score = maxi(0, score + amount)
	start_timer()
	score_log.append({
		"amount": amount,
		"reason": reason if reason != "" else "score",
		"floor": floor,
		"gtype": gtype,
		"total": score,
	})
	score_changed.emit(score, amount, reason)


## Awards up to 20 points per distinct card across its whole journey. Returns
## the points actually granted. Ported from klCardScore.
func award_card_points(card: Dictionary, points: int) -> int:
	if not gs.has("card_points"):
		gs["card_points"] = {}
	var ledger: Dictionary = gs["card_points"]
	var key := Cards.key(card)
	var earned := int(ledger.get(key, 0))
	var give := mini(points, Rules.MAX_CARD_POINTS - earned)
	if give > 0:
		ledger[key] = earned + give
		add_score(give, "card points")
	return give


func total_card_points() -> int:
	if gs.is_empty() or not gs.has("card_points"):
		return 0
	var total := 0
	for v in (gs["card_points"] as Dictionary).values():
		total += int(v)
	return total


# ══════════════════════════════════════════════════════════════════════════════
#  Undo
# ══════════════════════════════════════════════════════════════════════════════

func push_undo() -> void:
	undo_stack.append({
		"gs": Cards.clone_state(gs),
		"moves": moves,
		"score": score,
	})
	if undo_stack.size() > MAX_UNDO_STACK:
		undo_stack.pop_front()


func undos_remaining() -> int:
	return maxi(0, GameData.UNDOS_PER_FLOOR - floor_undos_used) + bonus_undos


func undo_move() -> bool:
	if undo_stack.is_empty():
		return false
	if undos_remaining() <= 0:
		toast.emit("No undos left this floor!")
		return false
	var prev: Dictionary = undo_stack.pop_back()
	gs = prev["gs"]
	moves = int(prev["moves"])
	score = int(prev["score"])
	win_overlay = false
	if bonus_undos > 0:
		bonus_undos -= 1
	else:
		floor_undos_used += 1
	state_changed.emit()
	return true


# ══════════════════════════════════════════════════════════════════════════════
#  Timer
# ══════════════════════════════════════════════════════════════════════════════

func start_timer() -> void:
	if _timer_running:
		return
	_timer_start = Time.get_ticks_msec() - _timer_elapsed
	_timer_running = true


func stop_timer() -> void:
	if not _timer_running:
		return
	_timer_elapsed = Time.get_ticks_msec() - _timer_start
	_timer_running = false


func get_elapsed_seconds() -> float:
	if _timer_running:
		return (Time.get_ticks_msec() - _timer_start) / 1000.0
	return _timer_elapsed / 1000.0


func format_elapsed() -> String:
	var total := int(get_elapsed_seconds())
	return "%d:%02d" % [total / 60, total % 60]


# ══════════════════════════════════════════════════════════════════════════════
#  Persistence
# ══════════════════════════════════════════════════════════════════════════════

func to_snapshot() -> Dictionary:
	return {
		"screen": screen,
		"lives": lives,
		"floor": floor,
		"choices": choices,
		"done": done,
		"gtype": gtype,
		"gs": gs,
		"score": score,
		"score_log": score_log,
		"gold": gold,
		"inventory": inventory,
		"shop_items": shop_items,
		"shop_gold_earned": shop_gold_earned,
		"shop_gold_breakdown": shop_gold_breakdown,
		"patron": patron,
		"floor_start_lives": floor_start_lives,
		"floor_undos_used": floor_undos_used,
		"floor_start_score": floor_start_score,
		"bonus_undos": bonus_undos,
		"extra_freecell": extra_freecell,
		"elapsed": get_elapsed_seconds(),
	}


## Restores a saved run. Missing keys fall back to defaults so a save from an
## older build still loads — the web build did the same via fillSaveDefaults.
func from_snapshot(snap: Dictionary) -> void:
	screen = snap.get("screen", "map")
	lives = int(snap.get("lives", GameData.STARTING_LIVES))
	floor = int(snap.get("floor", 0))
	choices = snap.get("choices", [])
	if choices.is_empty():
		choices = GameData.generate_choices()
	done = snap.get("done", [])
	gtype = snap.get("gtype", "")
	gs = snap.get("gs", {})
	score = int(snap.get("score", 0))
	score_log = snap.get("score_log", [])
	gold = int(snap.get("gold", 0))
	inventory = snap.get("inventory", [])
	shop_items = snap.get("shop_items", [])
	shop_gold_earned = int(snap.get("shop_gold_earned", 0))
	shop_gold_breakdown = snap.get("shop_gold_breakdown", [])
	patron = snap.get("patron", "johndee")
	floor_start_lives = int(snap.get("floor_start_lives", lives))
	floor_undos_used = int(snap.get("floor_undos_used", 0))
	floor_start_score = int(snap.get("floor_start_score", score))
	bonus_undos = int(snap.get("bonus_undos", 0))
	extra_freecell = bool(snap.get("extra_freecell", false))
	undo_stack = []
	moves = 0
	win_overlay = false
	floor_start_time = Time.get_ticks_msec()
	_timer_elapsed = int(float(snap.get("elapsed", 0.0)) * 1000.0)
	_timer_running = false
	state_changed.emit()


func _persist() -> void:
	# The undo stack is deliberately not saved: it can be large and a resumed
	# run starting with a clean history is the same choice the web build made.
	SaveManager.store_run(to_snapshot())
