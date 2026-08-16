extends Control

## The card table. Lays out and drives all five variants.
##
## Interaction is click-to-select / click-to-place, which is what the web build
## falls back to when not dragging, and works identically with a mouse, a
## touchscreen, or a Steam Deck trackpad. Drag-and-drop can be layered on top
## later without changing any of the rules calls below.
##
## Layout constants are proportional to card width so the whole board scales
## with the window rather than assuming the web build's pixel sizes.

const CARD_VIEW := preload("res://scenes/card_view.tscn")

## Fraction of the board width one card occupies, per variant.
const CARD_WIDTH_RATIO := {
	"klondike": 0.115,
	"spider": 0.082,
	"tripeaks": 0.088,
	"pyramid": 0.098,
	"freecell": 0.100,
}

const FAN_DOWN_FACE_UP := 0.30
const FAN_DOWN_FACE_DOWN := 0.14
const PILE_GAP := 0.18

@onready var _board: Control = $Board
@onready var _status: Label = $Top/Status
@onready var _score_label: Label = $Top/Score
@onready var _progress: ProgressBar = $Top/Progress
@onready var _inventory_bar: HBoxContainer = $Bottom/Inventory
@onready var _undo_button: Button = $Bottom/Undo
@onready var _abandon_button: Button = $Bottom/Abandon
@onready var _banner: Label = $Banner

## {"kind": "tableau"/"waste"/"freecell"/"pyramid", "col": int, "index": int}
var _selection: Dictionary = {}
var _card_size := Vector2(70, 98)

## Armed click-targeting item, e.g. the Athame waiting for a card to remove.
var _item_mode: Dictionary = {}
## Slots currently glowing from a hint item.
var _hint_slots: Array = []
var _hint_timer: SceneTreeTimer


func _ready() -> void:
	RunState.state_changed.connect(_rebuild)
	RunState.score_changed.connect(_on_score)
	resized.connect(_rebuild)
	_undo_button.pressed.connect(_on_undo)
	_abandon_button.pressed.connect(_on_abandon)
	_banner.visible = false
	_rebuild()


func _on_undo() -> void:
	RunState.undo_move()


func _on_abandon() -> void:
	var confirm := ConfirmationDialog.new()
	var free := false
	for item in RunState.inventory:
		if item["effect"] == "no-life-abandon":
			free = true
	confirm.dialog_text = "Abandon this floor?\n\n" + (
		"Your Vial of Quicksilver will be used — no life lost."
		if free else "You will lose a life.")
	add_child(confirm)
	confirm.popup_centered()
	confirm.confirmed.connect(func():
		RunState.abandon_floor()
		confirm.queue_free())
	confirm.canceled.connect(confirm.queue_free)


func _on_score(total: int, _delta: int, _reason: String) -> void:
	_refresh_header()


func _refresh_header() -> void:
	var hearts := ""
	for i in RunState.lives:
		hearts += "♥"
	_status.text = "%s   Floor %d   %s   %s" % [
		hearts,
		GameData.TOTAL_FLOORS - RunState.floor_index,
		GameData.NAMES.get(RunState.gtype, RunState.gtype),
		RunState.format_elapsed(),
	]
	_score_label.text = "★ %d pts" % RunState.score
	_progress.max_value = GameData.MAX_CARD_POINTS
	_progress.value = RunState.total_card_points()
	_undo_button.text = "UNDO (%d)" % RunState.undos_remaining()
	_undo_button.disabled = RunState.undo_stack.is_empty() or RunState.undos_remaining() <= 0


# ══════════════════════════════════════════════════════════════════════════════
#  Items
# ══════════════════════════════════════════════════════════════════════════════

func _refresh_inventory() -> void:
	for child in _inventory_bar.get_children():
		child.queue_free()

	for i in RunState.inventory.size():
		var item: Dictionary = RunState.inventory[i]
		var button := Button.new()
		button.text = "%s %s" % [item["icon"], item["name"]]
		button.tooltip_text = "%s\n\n%s" % [item["desc"], item["use"]]
		# Re-clicking an armed item cancels it, as the web build did.
		if not _item_mode.is_empty() and int(_item_mode.get("inv_index", -1)) == i:
			button.text = "✕ CANCEL"
		button.pressed.connect(_on_item_pressed.bind(i))
		_inventory_bar.add_child(button)

	if RunState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "No items — buy some in the shop"
		empty.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_inventory_bar.add_child(empty)

	if RunState.toolbox_uses > 0 or RunState.toolbox_card != null:
		_inventory_bar.add_child(_build_toolbox_slot())


## The Alchemist's Cabinet: an off-board slot holding one card for 8 uses.
func _build_toolbox_slot() -> Control:
	var button := Button.new()
	if RunState.toolbox_card == null:
		button.text = "🗄️ stash empty (%d)" % RunState.toolbox_uses
	else:
		var c: Dictionary = RunState.toolbox_card
		button.text = "🗄️ %s%s (%d)" % [Cards.rank_name(c), Cards.symbol(c), RunState.toolbox_uses]
	button.tooltip_text = "Click a board card to stash it, or click here to take the stashed card back."
	button.pressed.connect(_on_toolbox_pressed)
	return button


func _on_toolbox_pressed() -> void:
	if RunState.toolbox_card == null:
		RunState.toast.emit("Select a card on the board to stash it.")
		return
	# Taking the card back puts it in hand: select it as the pending move source.
	_item_mode = {"effect": "toolbox-place", "inv_index": -1,
		"banner": "ALCHEMIST'S CABINET: click where the stashed card should go"}
	_show_banner()
	_rebuild()


func _on_item_pressed(index: int) -> void:
	if not _item_mode.is_empty() and int(_item_mode.get("inv_index", -1)) == index:
		_cancel_item_mode()
		return
	if index < 0 or index >= RunState.inventory.size():
		return

	var item: Dictionary = RunState.inventory[index]
	var result := ItemEffects.activate(item, index)
	_apply_result(result, index)


func _apply_result(result: Dictionary, inv_index: int) -> void:
	if String(result.get("message", "")) != "":
		RunState.toast.emit(result["message"])

	var mode: Dictionary = result.get("mode", {})
	var picker: Dictionary = result.get("picker", {})
	var timed: Dictionary = result.get("timed", {})

	if bool(result.get("consumed", false)) and inv_index >= 0 \
			and inv_index < RunState.inventory.size():
		RunState.inventory.remove_at(inv_index)

	if not mode.is_empty():
		_item_mode = mode
		_show_banner()
	else:
		_item_mode = {}
		_banner.visible = false

	if not picker.is_empty():
		_open_picker(picker)

	if not timed.is_empty():
		_start_timed(timed)

	_selection = {}
	_rebuild()
	_check_win()


func _cancel_item_mode() -> void:
	_item_mode = {}
	_banner.visible = false
	_rebuild()


func _show_banner() -> void:
	_banner.text = String(_item_mode.get("banner", ""))
	_banner.visible = _banner.text != ""


## Hint glow, temporary reveal and stock peek all expire on a timer.
func _start_timed(timed: Dictionary) -> void:
	match String(timed["kind"]):
		"hints":
			_hint_slots = []
			for h in timed["hints"]:
				_hint_slots.append(h)
			_rebuild()
			_hint_timer = get_tree().create_timer(float(timed["seconds"]))
			_hint_timer.timeout.connect(func():
				_hint_slots = []
				if is_inside_tree():
					_rebuild())

		"reveal":
			var hidden: Array = timed["hidden"]
			get_tree().create_timer(float(timed["seconds"])).timeout.connect(func():
				if not is_inside_tree():
					return
				var s := Cards.clone_state(RunState.gs)
				for pair in hidden:
					var c := int(pair[0])
					var i := int(pair[1])
					if c < s["tableau"].size() and i < s["tableau"][c].size():
						s["tableau"][c][i]["face_up"] = false
				RunState.gs = s
				_rebuild())

		"peek":
			var names := PackedStringArray()
			for c in timed["cards"]:
				names.append("%s%s" % [Cards.rank_name(c), Cards.symbol(c)])
			var dialog := AcceptDialog.new()
			dialog.title = "Quill of Ravens"
			dialog.dialog_text = "Next from the stock:\n\n  " + "\n  ".join(names)
			add_child(dialog)
			dialog.popup_centered()
			var close := func():
				if is_instance_valid(dialog):
					dialog.queue_free()
			dialog.confirmed.connect(close)
			dialog.canceled.connect(close)
			get_tree().create_timer(float(timed["seconds"])).timeout.connect(close)


func _open_picker(picker: Dictionary) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = String(picker["title"])
	dialog.ok_button_text = "Cancel"

	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	dialog.add_child(grid)

	for card in picker["cards"]:
		var button := Button.new()
		button.text = "%s%s" % [Cards.rank_name(card), Cards.symbol(card)]
		button.custom_minimum_size = Vector2(56, 44)
		button.pressed.connect(func():
			var result := ItemEffects.resolve_picker(picker, card)
			dialog.queue_free()
			_apply_result(result, int(picker["inv_index"])))
		grid.add_child(button)

	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


func _is_hinted(meta: Dictionary) -> bool:
	if _hint_slots.is_empty():
		return false
	var kind: String = meta.get("kind", "")
	# Hints use the web build's shorter source names.
	# Dictionary.get() returns Variant, so the type has to be declared.
	var as_hint: String = {"tableau": "tab", "waste": "waste", "freecell": "fc",
		"pyramid": "pycard", "foundation": "found"}.get(kind, kind)
	for h in _hint_slots:
		if h.get("src") == as_hint \
				and int(h.get("col", -1)) == int(meta.get("col", -1)) \
				and int(h.get("index", -1)) == int(meta.get("index", -1)):
			return true
		if h.get("tsrc") == as_hint and int(h.get("tcol", -99)) == int(meta.get("col", -1)):
			return true
	return false


func _rebuild() -> void:
	if not is_inside_tree():
		return
	_refresh_header()
	_refresh_inventory()
	for child in _board.get_children():
		child.queue_free()

	var gs := RunState.gs
	if gs.is_empty():
		return

	var ratio: float = CARD_WIDTH_RATIO.get(gs.get("type", "klondike"), 0.115)
	var width := maxf(40.0, _board.size.x * ratio)
	_card_size = Vector2(width, width / UITheme.CARD_ASPECT)

	match gs["type"]:
		"klondike": _layout_klondike(gs)
		"spider": _layout_spider(gs)
		"freecell": _layout_freecell(gs)
		"tripeaks": _layout_tripeaks(gs)
		"pyramid": _layout_pyramid(gs)


# ══════════════════════════════════════════════════════════════════════════════
#  Card spawning
# ══════════════════════════════════════════════════════════════════════════════

func _spawn(card, pos: Vector2, meta: Dictionary, face_up_override = null) -> Control:
	var view := CARD_VIEW.instantiate()
	_board.add_child(view)
	view.position = pos
	view.custom_minimum_size = _card_size
	view.size = _card_size
	if card != null:
		view.setup(card)
		if face_up_override != null:
			view.face_up = face_up_override
	view.set_meta("slot", meta)
	view.card_pressed.connect(_on_card_pressed)
	view.selected = _is_selected(meta)
	view.hinted = _is_hinted(meta)
	return view


## Empty pile marker — a dashed outline the player can click as a drop target.
func _spawn_slot(pos: Vector2, meta: Dictionary, label: String = "") -> Control:
	var slot := Panel.new()
	_board.add_child(slot)
	slot.position = pos
	slot.size = _card_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = UITheme.GOLD_DIM
	style.set_corner_radius_all(5)
	slot.add_theme_stylebox_override("panel", style)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.set_meta("slot", meta)
	slot.gui_input.connect(func(e): _on_slot_input(e, slot))
	if label != "":
		var l := Label.new()
		l.text = label
		l.add_theme_color_override("font_color", UITheme.GOLD_DIM)
		l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(l)
	return slot


func _on_slot_input(event: InputEvent, slot: Panel) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_target(slot.get_meta("slot"))


func _is_selected(meta: Dictionary) -> bool:
	if _selection.is_empty():
		return false
	return _selection.get("kind") == meta.get("kind") \
		and _selection.get("col", -1) == meta.get("col", -1) \
		and int(meta.get("index", -1)) >= int(_selection.get("index", -1))


# ══════════════════════════════════════════════════════════════════════════════
#  Layouts
# ══════════════════════════════════════════════════════════════════════════════

func _layout_klondike(gs: Dictionary) -> void:
	var gap := _card_size.x * PILE_GAP
	var step := _card_size.x + gap

	# Row 1: stock, waste, then the four foundations right-aligned.
	if gs["stock"].is_empty():
		_spawn_slot(Vector2.ZERO, {"kind": "stock"}, "↻")
	else:
		_spawn(gs["stock"][gs["stock"].size() - 1], Vector2.ZERO, {"kind": "stock"}, false)

	var waste: Array = gs["waste"]
	if waste.is_empty():
		_spawn_slot(Vector2(step, 0), {"kind": "waste"})
	else:
		# Fan the last three so the player can see what is coming.
		var show := mini(3, waste.size())
		for i in show:
			var idx := waste.size() - show + i
			_spawn(waste[idx], Vector2(step + i * _card_size.x * 0.28, 0),
				{"kind": "waste", "index": idx})

	for s in 4:
		var pos := Vector2(step * (3 + s), 0)
		var f: Array = gs["foundations"][s]
		if f.is_empty():
			_spawn_slot(pos, {"kind": "foundation", "col": s}, Cards.SUIT_SYMBOLS[s])
		else:
			_spawn(f[f.size() - 1], pos, {"kind": "foundation", "col": s})

	# Row 2: seven fanned tableau columns.
	var top := _card_size.y + gap
	for c in 7:
		var pile: Array = gs["tableau"][c]
		var x := step * c
		if pile.is_empty():
			_spawn_slot(Vector2(x, top), {"kind": "tableau", "col": c})
			continue
		var y := top
		for i in pile.size():
			_spawn(pile[i], Vector2(x, y), {"kind": "tableau", "col": c, "index": i})
			y += _card_size.y * (FAN_DOWN_FACE_UP if pile[i]["face_up"] else FAN_DOWN_FACE_DOWN)


func _layout_spider(gs: Dictionary) -> void:
	var gap := _card_size.x * PILE_GAP
	var step := _card_size.x + gap

	var groups: int = gs["stock_groups"].size()
	if groups > 0:
		_spawn_slot(Vector2.ZERO, {"kind": "stock"}, "%d" % groups)
	_spawn_slot(Vector2(step * 8, 0), {"kind": "info"}, "%d/8" % gs["foundations"].size())

	var top := _card_size.y * 0.5 + gap
	for c in 10:
		var pile: Array = gs["tableau"][c]
		var x := step * c
		if pile.is_empty():
			_spawn_slot(Vector2(x, top), {"kind": "tableau", "col": c})
			continue
		var y := top
		for i in pile.size():
			_spawn(pile[i], Vector2(x, y), {"kind": "tableau", "col": c, "index": i})
			y += _card_size.y * (FAN_DOWN_FACE_UP if pile[i]["face_up"] else FAN_DOWN_FACE_DOWN)


func _layout_freecell(gs: Dictionary) -> void:
	var gap := _card_size.x * PILE_GAP
	var step := _card_size.x + gap

	var cells: Array = gs["freecells"]
	for i in cells.size():
		var pos := Vector2(step * i, 0)
		if cells[i] == null:
			_spawn_slot(pos, {"kind": "freecell", "col": i})
		else:
			_spawn(cells[i], pos, {"kind": "freecell", "col": i})

	for s in 4:
		var pos := Vector2(step * (cells.size() + 0.5 + s), 0)
		var f: Array = gs["foundations"][s]
		if f.is_empty():
			_spawn_slot(pos, {"kind": "foundation", "col": s}, Cards.SUIT_SYMBOLS[s])
		else:
			_spawn(f[f.size() - 1], pos, {"kind": "foundation", "col": s})

	var top := _card_size.y + gap
	for c in 8:
		var pile: Array = gs["tableau"][c]
		var x := step * c
		if pile.is_empty():
			_spawn_slot(Vector2(x, top), {"kind": "tableau", "col": c})
			continue
		var y := top
		for i in pile.size():
			_spawn(pile[i], Vector2(x, y), {"kind": "tableau", "col": c, "index": i})
			y += _card_size.y * FAN_DOWN_FACE_UP


func _layout_tripeaks(gs: Dictionary) -> void:
	var gap := _card_size.x * 0.10
	var tw := _card_size.x + gap
	var half := tw * 0.5
	var row_y := [0.0, _card_size.y * 0.42, _card_size.y * 0.84, _card_size.y * 1.26]
	var peaks := [tw + half, tw * 4 + half, tw * 7 + half]
	var shoulders := [tw, tw * 2, tw * 4, tw * 5, tw * 7, tw * 8]

	for i in 28:
		var c = gs["pyramid"][i]
		if c == null:
			continue
		var pos: Vector2
		if i <= 2:
			pos = Vector2(peaks[i], row_y[0])
		elif i <= 8:
			pos = Vector2(shoulders[i - 3], row_y[1])
		elif i <= 17:
			pos = Vector2(half + (i - 9) * tw, row_y[2])
		else:
			pos = Vector2((i - 18) * tw, row_y[3])
		var view := _spawn(c, pos, {"kind": "pyramid", "index": i})
		view.playable = Rules.tripeaks_free(gs["pyramid"], i)

	var base_y: float = row_y[3] + _card_size.y * 1.25
	if gs["stock"].is_empty():
		_spawn_slot(Vector2(0, base_y), {"kind": "stock"}, "—")
	else:
		_spawn(gs["stock"][0], Vector2(0, base_y), {"kind": "stock"}, false)
	var waste: Array = gs["waste"]
	if not waste.is_empty():
		_spawn(waste[waste.size() - 1], Vector2(_card_size.x * 1.3, base_y), {"kind": "waste"})


func _layout_pyramid(gs: Dictionary) -> void:
	var gap := _card_size.x * 0.10
	var tw := _card_size.x + gap
	var total := tw * 7 - gap

	for row in 7:
		var row_w := tw * (row + 1) - gap
		for col in range(row + 1):
			var idx := Rules.pyramid_index(row, col)
			var c = gs["pyramid"][idx]
			if c == null:
				continue
			var pos := Vector2((total - row_w) * 0.5 + col * tw, row * _card_size.y * 0.52)
			var view := _spawn(c, pos, {"kind": "pyramid", "index": idx})
			view.playable = not Rules.pyramid_blocked(gs["pyramid"], row, col)

	var base_y := 7 * _card_size.y * 0.52 + _card_size.y * 0.3
	if gs["stock"].is_empty():
		_spawn_slot(Vector2(0, base_y), {"kind": "stock"}, "↻")
	else:
		_spawn(gs["stock"][gs["stock"].size() - 1], Vector2(0, base_y), {"kind": "stock"}, false)
	var waste: Array = gs["waste"]
	if not waste.is_empty():
		_spawn(waste[waste.size() - 1], Vector2(_card_size.x * 1.3, base_y), {"kind": "waste"})


# ══════════════════════════════════════════════════════════════════════════════
#  Interaction
# ══════════════════════════════════════════════════════════════════════════════

func _on_card_pressed(view: Control) -> void:
	var meta: Dictionary = view.get_meta("slot")
	var gs := RunState.gs
	if gs.is_empty():
		return

	# An armed item takes priority over normal play.
	if not _item_mode.is_empty():
		_resolve_item_click(meta)
		return

	# With an empty toolbox stash armed, the next card click stores it.
	if RunState.toolbox_uses > 0 and RunState.toolbox_card == null and _selection.is_empty():
		if _try_stash(meta):
			return

	if meta.get("kind") == "stock":
		_draw_stock()
		return

	# Pyramid and TriPeaks are single-click games: a card is either playable now
	# or it is not, so there is nothing to select.
	match gs["type"]:
		"tripeaks":
			_tripeaks_play(meta)
			return
		"pyramid":
			_pyramid_click(meta)
			return

	if _selection.is_empty():
		_begin_selection(meta)
	else:
		_handle_target(meta)


func _begin_selection(meta: Dictionary) -> void:
	var gs := RunState.gs
	var kind: String = meta.get("kind", "")

	if kind == "tableau":
		var pile: Array = gs["tableau"][meta["col"]]
		var idx := int(meta.get("index", pile.size() - 1))
		if idx >= pile.size() or not pile[idx]["face_up"]:
			return
		# A run must be legally movable as a unit before it can be picked up.
		if gs["type"] == "klondike" and not _is_valid_run(pile, idx):
			return
		if gs["type"] == "spider" and pile.size() - idx > Rules.spider_sequence_length(pile):
			return
		if gs["type"] == "freecell" and pile.size() - idx > Rules.freecell_max_movable(gs):
			return
	elif kind == "waste":
		if gs["waste"].is_empty():
			return
	elif kind == "freecell":
		if gs["freecells"][meta["col"]] == null:
			return
	elif kind == "foundation":
		return

	_selection = meta
	AudioManager.card_taken()
	_rebuild()


## Klondike runs must descend in alternating colours to move together.
func _is_valid_run(pile: Array, from_index: int) -> bool:
	for i in range(from_index, pile.size() - 1):
		var a: Dictionary = pile[i]
		var b: Dictionary = pile[i + 1]
		if a["rank"] != b["rank"] + 1 or Cards.is_red(a["suit"]) == Cards.is_red(b["suit"]):
			return false
	return true


func _handle_target(target: Dictionary) -> void:
	if _selection.is_empty():
		_begin_selection(target)
		return
	if _selection.get("kind") == target.get("kind") and _selection.get("col", -1) == target.get("col", -1):
		_selection = {}
		_rebuild()
		return

	var moved := _try_move(_selection, target)
	_selection = {}
	if moved:
		AudioManager.card_moved()
		_after_move()
	else:
		_rebuild()


## Applies a move if the rules allow it. Returns whether the board changed.
func _try_move(from: Dictionary, to: Dictionary) -> bool:
	var gs := Cards.clone_state(RunState.gs)
	var cards := _take_cards(gs, from, true)
	if cards.is_empty():
		return false

	var accepted := false
	match to.get("kind"):
		"foundation":
			if cards.size() == 1 and Rules.klondike_can_foundation(cards[0], gs["foundations"]) \
					and int(to["col"]) == int(cards[0]["suit"]):
				gs["foundations"][cards[0]["suit"]].append(cards[0])
				accepted = true
		"tableau":
			var target: Array = gs["tableau"][to["col"]]
			var ok := false
			match gs["type"]:
				"klondike": ok = Rules.klondike_can_tableau(cards, target)
				"spider": ok = Rules.spider_can_drop(cards, target)
				"freecell": ok = Rules.freecell_can_tableau(cards[0], target)
			if ok:
				for c in cards:
					target.append(c)
				accepted = true
		"freecell":
			if cards.size() == 1 and gs["freecells"][to["col"]] == null:
				gs["freecells"][to["col"]] = cards[0]
				accepted = true

	if not accepted:
		return false

	RunState.push_undo()
	_score_move(gs, from, to, cards)
	_take_cards(gs, from, false)
	if gs["type"] == "klondike" or gs["type"] == "spider":
		for revealed in Rules.klondike_auto_reveal(gs):
			RunState.gs = gs
			RunState.award_card_points(revealed, Rules.PTS_REVEAL)
	if gs["type"] == "spider":
		for c in 10:
			var suit := Rules.spider_check_complete(gs["tableau"][c])
			if suit >= 0:
				var pile: Array = gs["tableau"][c]
				pile.resize(pile.size() - 13)
				if not pile.is_empty():
					pile[pile.size() - 1]["face_up"] = true
				gs["foundations"].append(suit)
				RunState.add_score(Rules.PTS_SUIT_COMPLETED, "suit completed")
	RunState.gs = gs
	RunState.moves += 1
	return true


## peek=true returns a copy without mutating; peek=false removes the cards.
func _take_cards(gs: Dictionary, from: Dictionary, peek: bool) -> Array:
	match from.get("kind"):
		"tableau":
			var pile: Array = gs["tableau"][from["col"]]
			var idx := int(from.get("index", pile.size() - 1))
			if idx < 0 or idx >= pile.size():
				return []
			var slice := pile.slice(idx)
			if not peek:
				pile.resize(idx)
			return slice
		"waste":
			if gs["waste"].is_empty():
				return []
			if peek:
				return [gs["waste"][gs["waste"].size() - 1]]
			return [gs["waste"].pop_back()]
		"freecell":
			var c = gs["freecells"][from["col"]]
			if c == null:
				return []
			if not peek:
				gs["freecells"][from["col"]] = null
			return [c]
	return []


func _score_move(gs: Dictionary, from: Dictionary, to: Dictionary, cards: Array) -> void:
	RunState.gs = gs
	if to.get("kind") == "foundation":
		RunState.award_card_points(cards[0], Rules.PTS_FOUNDATION)
	elif from.get("kind") == "waste" and to.get("kind") == "tableau":
		RunState.award_card_points(cards[0], Rules.PTS_WASTE_TO_TABLEAU)


func _draw_stock() -> void:
	var gs := RunState.gs
	RunState.push_undo()
	match gs["type"]:
		"klondike": RunState.gs = Rules.klondike_draw(gs)
		"pyramid": RunState.gs = Rules.pyramid_draw(gs)
		"tripeaks": RunState.gs = Rules.tripeaks_draw(gs)
		"spider":
			var result := Rules.spider_deal(gs)
			RunState.gs = result["state"]
			for _s in result["completed"]:
				RunState.add_score(Rules.PTS_SUIT_COMPLETED, "suit completed")
	_selection = {}
	AudioManager.card_moved()
	_after_move()


func _tripeaks_play(meta: Dictionary) -> void:
	var gs := Cards.clone_state(RunState.gs)
	if meta.get("kind") != "pyramid":
		return
	var idx := int(meta["index"])
	if not Rules.tripeaks_free(gs["pyramid"], idx):
		return
	var waste_top = null
	if not gs["waste"].is_empty():
		waste_top = gs["waste"][gs["waste"].size() - 1]
	var card: Dictionary = gs["pyramid"][idx]
	if not Rules.tripeaks_can_play(card, waste_top):
		return
	RunState.push_undo()
	gs["pyramid"][idx] = null
	card["face_up"] = true
	gs["waste"].append(card)
	Rules.tripeaks_update_face_up(gs["pyramid"])
	RunState.gs = gs
	RunState.award_card_points(card, Rules.PTS_FOUNDATION)
	AudioManager.card_moved()
	_after_move()


## Pyramid needs two clicks unless the card is a King, which clears alone.
func _pyramid_click(meta: Dictionary) -> void:
	var gs := Cards.clone_state(RunState.gs)
	var picked = _pyramid_card(gs, meta)
	if picked == null:
		return

	if int(picked["rank"]) == Cards.RANK_KING:
		RunState.push_undo()
		_pyramid_remove(gs, meta)
		RunState.gs = gs
		RunState.award_card_points(picked, Rules.PTS_FOUNDATION)
		_selection = {}
		AudioManager.card_moved()
		_after_move()
		return

	if _selection.is_empty():
		_selection = meta
		AudioManager.card_taken()
		_rebuild()
		return

	var first = _pyramid_card(gs, _selection)
	if first == null:
		_selection = meta
		_rebuild()
		return

	if Rules.pyramid_pairs(first, picked):
		RunState.push_undo()
		_pyramid_remove(gs, _selection)
		_pyramid_remove(gs, meta)
		RunState.gs = gs
		RunState.award_card_points(first, Rules.PTS_FOUNDATION)
		RunState.award_card_points(picked, Rules.PTS_FOUNDATION)
		_selection = {}
		AudioManager.card_moved()
		_after_move()
	else:
		_selection = {}
		_rebuild()


func _pyramid_card(gs: Dictionary, meta: Dictionary):
	match meta.get("kind"):
		"pyramid":
			var idx := int(meta["index"])
			var row := 0
			while Rules.pyramid_index(row + 1, 0) <= idx and row < 6:
				row += 1
			var col := idx - Rules.pyramid_index(row, 0)
			if Rules.pyramid_blocked(gs["pyramid"], row, col):
				return null
			return gs["pyramid"][idx]
		"waste":
			if gs["waste"].is_empty():
				return null
			return gs["waste"][gs["waste"].size() - 1]
	return null


func _pyramid_remove(gs: Dictionary, meta: Dictionary) -> void:
	match meta.get("kind"):
		"pyramid": gs["pyramid"][int(meta["index"])] = null
		"waste": gs["waste"].pop_back()


func _resolve_item_click(meta: Dictionary) -> void:
	# The toolbox "place" mode is a move, not an item effect, so it is handled
	# here rather than in ItemEffects.
	if String(_item_mode.get("effect", "")) == "toolbox-place":
		_try_unstash(meta)
		return

	var result := ItemEffects.resolve_mode(_item_mode, meta)
	var message := String(result.get("message", ""))

	# A failed target keeps the mode armed so the player can try again, which
	# is what the web build did — only a successful use consumes the item.
	if not bool(result.get("consumed", false)):
		if message != "":
			RunState.toast.emit(message)
		return

	_apply_result(result, int(_item_mode.get("inv_index", -1)))


## Moves a board card into the toolbox stash.
func _try_stash(meta: Dictionary) -> bool:
	var kind: String = meta.get("kind", "")
	if not ["tableau", "waste", "freecell"].has(kind):
		return false
	var gs := RunState.gs
	var pile_top := true
	if kind == "tableau":
		var pile: Array = gs["tableau"][meta["col"]]
		pile_top = int(meta.get("index", -1)) == pile.size() - 1
	if not pile_top:
		return false

	var card = ItemEffects._card_at(gs, meta)
	if card == null or not bool(card.get("face_up", false)):
		return false

	RunState.push_undo()
	RunState.gs = ItemEffects._remove_card_at(gs, meta)
	RunState.toolbox_card = card
	RunState.toolbox_uses -= 1
	AudioManager.card_taken()
	RunState.toast.emit("Stashed %s%s" % [Cards.rank_name(card), Cards.symbol(card)])
	_rebuild()
	return true


## Plays the stashed card back onto the board, if the target accepts it.
func _try_unstash(meta: Dictionary) -> void:
	var card = RunState.toolbox_card
	if card == null:
		_cancel_item_mode()
		return

	var gs := Cards.clone_state(RunState.gs)
	var accepted := false

	match meta.get("kind"):
		"tableau":
			var target: Array = gs["tableau"][meta["col"]]
			match gs["type"]:
				"klondike": accepted = Rules.klondike_can_tableau([card], target)
				"spider": accepted = Rules.spider_can_drop([card], target)
				"freecell": accepted = Rules.freecell_can_tableau(card, target)
			if accepted:
				target.append(card)
		"foundation":
			if Rules.klondike_can_foundation(card, gs["foundations"]) \
					and int(meta["col"]) == int(card["suit"]):
				gs["foundations"][card["suit"]].append(card)
				accepted = true
		"freecell":
			if gs["freecells"][meta["col"]] == null:
				gs["freecells"][meta["col"]] = card
				accepted = true

	if not accepted:
		RunState.toast.emit("The stashed card does not fit there.")
		return

	RunState.push_undo()
	RunState.gs = gs
	RunState.toolbox_card = null
	RunState.moves += 1
	AudioManager.card_moved()
	_cancel_item_mode()
	_check_win()


func _after_move() -> void:
	_rebuild()
	_check_win()


func _check_win() -> void:
	if Rules.is_won(RunState.gs):
		RunState.win_overlay = true
		RunState.next_floor()
