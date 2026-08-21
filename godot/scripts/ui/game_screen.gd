extends PanelContainer

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

## Per-variant sizing budget. `cols` is how many piles sit across; `stack` is a
## generous guess at the tallest fanned column, so a card is sized to keep that
## column inside the board height. `top` counts extra card-height rows above the
## tableau (foundation/free-cell row). Cards are sized to satisfy both the width
## and the height budget, whichever is tighter.
## Card-sizing budget per variant. `w` is the widest row measured in card widths
## (including inter-pile gaps); `h` is the content height in card heights; `header`
## is how many card heights the non-tableau rows take, used by the adaptive fan.
## Column games are deliberately sized generously — near-width-limited, like a
## desktop solitaire — and the fan compresses tall columns to keep them on-screen
## rather than shrinking every card to fit a rare 13-high pile. Pyramid/TriPeaks
## carry the real height of their fixed shapes so they never overflow.
const LAYOUT := {
	"klondike": {"w": 8.08, "h": 3.4, "header": 1.25},
	"freecell": {"w": 9.26, "h": 3.4, "header": 1.25},
	"spider": {"w": 11.62, "h": 3.6, "header": 0.75},
	"tripeaks": {"w": 11.0, "h": 3.6, "header": 0.0},
	"pyramid": {"w": 8.3, "h": 5.1, "header": 0.0},
}

## Default (loosest) fan spacing for face-up cards; the actual value is computed
## per rebuild in _compute_fan so long columns stay inside the board.
const FAN_DOWN_FACE_UP := 0.30
const FAN_DOWN_FACE_DOWN := 0.14
## Smallest face-up fan that still leaves the covered card's rank+suit corner
## legible (the corner index runs to ~0.26 of the card height). Rather than pack
## tighter than this, tall columns shrink the whole card — see _apply_column_fit.
const MIN_FAN_UP := 0.26
const PILE_GAP := 0.18

## The live face-up fan, recomputed each rebuild by _compute_fan.
var _fan_up := FAN_DOWN_FACE_UP

## Margins kept clear of the board edges when centring, as a fraction.
const BOARD_MARGIN := 0.03

@onready var _window: PanelContainer = self as PanelContainer
@onready var _title_bar: PanelContainer = $Rows/TitleBar
@onready var _title_icon: Label = $Rows/TitleBar/TitleRow/TitleIcon
@onready var _title_text: Label = $Rows/TitleBar/TitleRow/TitleText
@onready var _win_btns: HBoxContainer = $Rows/TitleBar/TitleRow/WinBtns
@onready var _toolbar: PanelContainer = $Rows/Toolbar
@onready var _moves_label: Label = $Rows/Toolbar/ToolRow/Moves
@onready var _gold_label: Label = $Rows/Toolbar/ToolRow/Gold
@onready var _hearts_label: Label = $Rows/Toolbar/ToolRow/Hearts
@onready var _progress: ProgressBar = $Rows/ScoreBar
@onready var _rules_label: Label = $Rows/Rules
@onready var _inventory_bar: HBoxContainer = $Rows/Toolbar/ToolRow/Inventory
@onready var _undo_button: Button = $Rows/Toolbar/ToolRow/Undo
@onready var _shuffle_button: Button = $Rows/Toolbar/ToolRow/Shuffle
@onready var _pause_button: Button = $Rows/Toolbar/ToolRow/Pause
@onready var _abandon_button: Button = $Rows/Toolbar/ToolRow/Abandon
@onready var _banner: Label = $Rows/Banner
@onready var _board: Control = $Rows/Board/Felt
@onready var _board_frame: PanelContainer = $Rows/Board
@onready var _status_bar: PanelContainer = $Rows/StatusBar
@onready var _status_row: HBoxContainer = $Rows/StatusBar/StatusRow
@onready var _overlays: CanvasLayer = $Overlays

## The clickable "★ N pts" status pane, built in code so it can open the ledger.
var _score_pane: Button
## The five status-bar text panes: floor, variant, lives, score, timer.
var _status_panes: Array = []

## {"kind": "tableau"/"waste"/"freecell"/"pyramid", "col": int, "index": int}
var _selection: Dictionary = {}
var _card_size := Vector2(70, 98)

## Armed click-targeting item, e.g. the Athame waiting for a card to remove.
var _item_mode: Dictionary = {}
## Slots currently glowing from a hint item.
var _hint_slots: Array = []
var _hint_timer: SceneTreeTimer

## Drag-and-drop. A press records here without acting; release decides whether it
## was a click (no movement) or a drag (moved past the threshold). Click-to-place
## still works untouched — drag is an alternative, not a replacement.
##
## The threshold is in *screen* pixels. Input positions arrive in the 1920x1080
## design canvas, which is scaled down to the window (≈0.67x at 1280 wide), so a
## raw 8px would trip after only ~5 real pixels of jitter and turn ordinary
## clicks into drags. _drag_threshold() converts this to canvas units live.
const DRAG_THRESHOLD := 14.0
var _press: Dictionary = {}
var _dragging := false
var _drag_source: Dictionary = {}
var _drag_cards: Array = []
var _ghost: Control
## Cursor position within the grabbed card, so the ghost tracks from that point.
var _grab_offset := Vector2.ZERO
## Pointer position at the last button-down, in canvas coords. Captured in _input
## before the card's press signal fires, since the signal carries no event. Using
## event positions rather than get_mouse_position keeps this working with both
## real input and pushed test events.
var _pending_start := Vector2.ZERO


func _ready() -> void:
	RunState.state_changed.connect(_rebuild)
	RunState.score_changed.connect(_on_score)
	# The board only reaches its real size after the container lays it out, which
	# happens a frame after this screen resizes — so listen to the board's own
	# resize, not the screen's, or the first build measures a zero-width board.
	_board.resized.connect(_rebuild)
	_undo_button.pressed.connect(_on_undo)
	_shuffle_button.pressed.connect(_on_shuffle)
	_pause_button.pressed.connect(_on_pause)
	_abandon_button.pressed.connect(_on_abandon)
	_banner.visible = false
	_style_chrome()
	_build_window_buttons()
	_build_status_panes()
	_rebuild()


## Applies the Windows-95 desktop look the web build wrapped the table in: a
## beveled grey window, a dark gradient title bar, a toolbar, a sunken felt board
## and a status bar. Done here rather than in the .tscn so the exact CSS colours
## live next to the palette that named them.
func _style_chrome() -> void:
	var pixel := UITheme.font("pixel")

	# The window frame: raised bevel, grey fill.
	_window.add_theme_stylebox_override("panel", UITheme.bevel_raised(UITheme.W95_BG, Vector2(2, 2)))

	# Title bar: the --w95-titlebar gradient, white pixel text.
	var grad := Gradient.new()
	grad.set_color(0, UITheme.W95_TITLEBAR1)
	grad.set_color(1, UITheme.W95_TITLEBAR2)
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 256
	grad_tex.height = 8
	var title_box := StyleBoxTexture.new()
	title_box.texture = grad_tex
	title_box.content_margin_left = 6
	title_box.content_margin_right = 4
	title_box.content_margin_top = 3
	title_box.content_margin_bottom = 3
	_title_bar.add_theme_stylebox_override("panel", title_box)
	for label in [_title_icon, _title_text]:
		label.add_theme_font_override("font", pixel)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color.WHITE)

	# Toolbar: flat grey with a dark bottom rule.
	var tool_box := UITheme.bevel_raised(UITheme.W95_BG, Vector2(6, 4))
	tool_box.light_color = UITheme.W95_BG  # no top/left highlight, just the fill
	_toolbar.add_theme_stylebox_override("panel", tool_box)
	for label in [_moves_label, _gold_label, _hearts_label]:
		label.add_theme_font_override("font", pixel)
		label.add_theme_font_size_override("font_size", 18)
	_hearts_label.add_theme_color_override("font_color", UITheme.CARD_RED)
	# The gold "time credits" pill: yellow, sunken.
	_gold_label.add_theme_stylebox_override("normal", _pill_box())
	_gold_label.add_theme_color_override("font_color", UITheme.GOLD_PILL_TEXT)

	# Rules strip: light grey band, small pixel text.
	var rules_box := StyleBoxFlat.new()
	rules_box.bg_color = UITheme.W95_HOVER
	rules_box.border_width_top = 1
	rules_box.border_width_bottom = 1
	rules_box.border_color = UITheme.W95_DARKER
	rules_box.content_margin_left = 8
	rules_box.content_margin_right = 8
	rules_box.content_margin_top = 3
	rules_box.content_margin_bottom = 3
	_rules_label.add_theme_stylebox_override("normal", rules_box)
	_rules_label.add_theme_font_override("font", pixel)
	_rules_label.add_theme_font_size_override("font_size", 15)
	_rules_label.add_theme_color_override("font_color", Color("333333"))

	# The felt board: sunken well, dark purple fill.
	_board_frame.add_theme_stylebox_override("panel",
		UITheme.bevel_sunken(UITheme.FELT, Vector2(4, 4)))

	# Status bar: grey band of sunken panes.
	var status_box := UITheme.bevel_raised(UITheme.W95_BG, Vector2(2, 2))
	status_box.light_color = UITheme.W95_DARK  # just a top rule
	status_box.dark_color = UITheme.W95_BG
	_status_bar.add_theme_stylebox_override("panel", status_box)

	# The klondike score bar sits flush under the rules strip.
	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.GOLD
	_progress.add_theme_stylebox_override("fill", fill)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.06)
	_progress.add_theme_stylebox_override("background", track)


## A yellow, sunken pixel-text pill, shared by the gold display.
func _pill_box() -> BevelStyleBox:
	var s := UITheme.bevel_sunken(UITheme.GOLD_PILL_BG, Vector2(8, 2))
	return s


## The three decorative title-bar window buttons (_ □ ✕).
func _build_window_buttons() -> void:
	for glyph in ["_", "□", "✕"]:
		var b := Label.new()
		b.text = glyph
		b.custom_minimum_size = Vector2(18, 16)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_theme_font_override("font", UITheme.font("mono"))
		b.add_theme_font_size_override("font_size", 10)
		b.add_theme_color_override("font_color", Color.BLACK)
		b.add_theme_stylebox_override("normal", UITheme.bevel_raised(UITheme.W95_BG, Vector2(0, 0), 1.5))
		# Label has no "normal" stylebox slot; wrap it in a PanelContainer instead.
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", UITheme.bevel_raised(UITheme.W95_BG, Vector2(4, 1), 1.5))
		frame.add_child(b)
		_win_btns.add_child(frame)


## Builds the bottom status bar's sunken panes. The score pane is a button so it
## opens the score history, matching the web's clickable score pane. Text is set
## later by _refresh_header; the panes themselves are built once.
func _build_status_panes() -> void:
	for child in _status_row.get_children():
		child.queue_free()
	_status_panes = []

	# The player's name leads the status bar (static for the run).
	if SaveManager.player_name != "":
		var name_label := _make_status_label()
		name_label.text = "👤 %s" % SaveManager.player_name
		name_label.add_theme_color_override("font_color", UITheme.W95_TITLE)
		_status_row.add_child(_wrap_pane(name_label))

	# Floor / variant / lives / score / timer, then the version, pushed right.
	for i in 5:
		_status_panes.append(_add_status_pane(i == 3))
	_score_pane = _status_panes[3]

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_row.add_child(spacer)

	var version := _make_status_label()
	version.text = "Solitaire Tower of Doom v2.0"
	_status_row.add_child(_wrap_pane(version))


func _make_status_label() -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", UITheme.font("pixel"))
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UITheme.W95_DARKER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


## A pane's sunken frame: 1px dark top-left, white bottom-right, per .win95-status-pane.
func _pane_box() -> BevelStyleBox:
	var s := UITheme.bevel_sunken(UITheme.W95_BG, Vector2(10, 3), 1.0)
	s.light_color = UITheme.W95_DARK
	s.dark_color = UITheme.W95_WHITE
	return s


func _wrap_pane(child: Control) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _pane_box())
	frame.add_child(child)
	return frame


## Adds a text pane; when `clickable` it is a Button that opens the score history.
func _add_status_pane(clickable: bool) -> Control:
	if clickable:
		var button := Button.new()
		button.flat = true
		button.add_theme_font_override("font", UITheme.font("pixel"))
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", UITheme.W95_DARKER)
		button.add_theme_color_override("font_hover_color", UITheme.W95_TITLE)
		button.tooltip_text = "View this floor's score history"
		button.pressed.connect(_show_score_history)
		_status_row.add_child(_wrap_pane(button))
		return button
	var label := _make_status_label()
	_status_row.add_child(_wrap_pane(label))
	return label


func _on_undo() -> void:
	RunState.undo_move()


## Re-deals the current floor from scratch. Like abandoning, it costs a life —
## RunState.new_shuffle enforces that — so it is behind a confirmation.
func _on_shuffle() -> void:
	Modal.confirm(self, "Shuffle",
		"Re-deal this floor with a fresh shuffle?\n\nYou will lose a life.",
		func(): RunState.new_shuffle(),
		"Shuffle", "Cancel", true)


## Pauses the clock and covers the board, matching the web build's togglePause.
func _on_pause() -> void:
	RunState.stop_timer()
	_show_pause_overlay()


func _on_abandon() -> void:
	var free := false
	for item in RunState.inventory:
		if item["effect"] == "no-life-abandon":
			free = true
	var message := "Abandon this floor?\n\n" + (
		"Your Vial of Quicksilver will be used — no life lost."
		if free else "You will lose a life.")
	Modal.confirm(self, "Abandon Floor", message,
		func(): RunState.abandon_floor(),
		"Abandon", "Cancel", not free)


func _on_score(total: int, _delta: int, _reason: String) -> void:
	_refresh_header()


func _refresh_header() -> void:
	var floor_no := GameData.TOTAL_FLOORS - RunState.floor_index
	var name: String = GameData.NAMES.get(RunState.gtype, RunState.gtype)
	var icon: String = GameData.ICONS.get(RunState.gtype, "")

	_title_text.text = "Solitaire Tower of Doom — %s (Floor %d)" % [name, floor_no]

	var hearts := ""
	for i in RunState.lives:
		hearts += "♥"
	_hearts_label.text = hearts if hearts != "" else "—"
	_moves_label.text = "%dmv" % RunState.moves
	_gold_label.text = "⏳%d" % RunState.gold

	if _status_panes.size() >= 5:
		_status_panes[0].text = "Floor %d of 10" % floor_no
		_status_panes[1].text = "%s %s" % [icon, name]
		_status_panes[2].text = "♥ %d" % RunState.lives
		_status_panes[3].text = "★ %s pts" % _comma(RunState.score)
		_status_panes[4].text = "⏱ %s" % RunState.format_elapsed()

	# The card-point bar only means anything in Klondike, as in the web build.
	_progress.visible = RunState.gtype == "klondike"
	_progress.max_value = GameData.MAX_CARD_POINTS
	_progress.value = RunState.total_card_points()

	var rule_items := PackedStringArray()
	for r in GameData.RULES.get(RunState.gtype, []):
		rule_items.append("▸ " + str(r))
	_rules_label.text = "  ".join(rule_items)

	_undo_button.text = "↩ Undo (%d)" % RunState.undos_remaining()
	_undo_button.disabled = RunState.undo_stack.is_empty() or RunState.undos_remaining() <= 0
	_abandon_button.add_theme_color_override("font_color", UITheme.MAROON)
	_shuffle_button.add_theme_color_override("font_color", UITheme.MAROON)


## Thousands separators, matching the web's toLocaleString on the score.
func _comma(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


# ══════════════════════════════════════════════════════════════════════════════
#  Items
# ══════════════════════════════════════════════════════════════════════════════

func _refresh_inventory() -> void:
	for child in _inventory_bar.get_children():
		child.queue_free()

	# Three fixed Win95 slots, icon-only, like the web toolbar's .inv-slot-btn.
	for i in GameData.INVENTORY_SLOTS:
		if i < RunState.inventory.size():
			var item: Dictionary = RunState.inventory[i]
			var armed := not _item_mode.is_empty() and int(_item_mode.get("inv_index", -1)) == i
			var button := _make_inv_slot(String(item["icon"]), armed)
			button.tooltip_text = "%s: %s" % [item["name"], item["use"]]
			button.pressed.connect(_on_item_pressed.bind(i))
			_inventory_bar.add_child(button)
		else:
			_inventory_bar.add_child(_make_inv_slot("·", false, true))

	if RunState.toolbox_uses > 0 or RunState.toolbox_card != null:
		_inventory_bar.add_child(_build_toolbox_slot())


## A compact 34×28 Win95 inventory slot. Empty slots are dim and inert; an armed
## item glows yellow, matching .inv-slot-btn / .empty-inv / .armed.
func _make_inv_slot(glyph: String, armed: bool, empty := false) -> Button:
	var button := Button.new()
	button.text = glyph
	button.custom_minimum_size = Vector2(34, 28)
	button.focus_mode = Control.FOCUS_NONE
	var bg := UITheme.W95_BG
	if empty:
		bg = Color("a0a0a0")
	elif armed:
		bg = UITheme.ITEM_ARMED
	var box := UITheme.bevel_sunken(bg, Vector2(2, 2)) if armed \
		else UITheme.bevel_raised(bg, Vector2(2, 2))
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", UITheme.bevel_raised(UITheme.W95_HOVER, Vector2(2, 2)))
	button.add_theme_stylebox_override("pressed", UITheme.bevel_sunken(bg, Vector2(2, 2)))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.BLACK)
	return button


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
	# An item that auto-clears the floor (Executive Chair) raises the win overlay
	# even though the board itself is not solved, so _check_win would miss it.
	if bool(result.get("win", false)):
		_show_win_overlay()
	else:
		_check_win()


func _cancel_item_mode() -> void:
	_item_mode = {}
	_banner.visible = false
	_rebuild()


func _show_banner() -> void:
	_banner.text = String(_item_mode.get("banner", ""))
	_banner.visible = _banner.text != ""
	# The web item-mode banner is a bright yellow bar with black pixel text.
	var box := StyleBoxFlat.new()
	box.bg_color = UITheme.ITEM_BANNER_BG
	box.border_width_bottom = 2
	box.border_color = Color("cccc00")
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	_banner.add_theme_stylebox_override("normal", box)
	_banner.add_theme_font_override("font", UITheme.font("pixel"))
	_banner.add_theme_font_size_override("font_size", 18)
	_banner.add_theme_color_override("font_color", Color.BLACK)


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
			var layer := Modal.alert(self, "Quill of Ravens",
				"Next from the stock:\n\n  " + "\n  ".join(names))
			get_tree().create_timer(float(timed["seconds"])).timeout.connect(func():
				if is_instance_valid(layer):
					layer.queue_free())


func _open_picker(picker: Dictionary) -> void:
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)

	var layer: CanvasLayer
	for card in picker["cards"]:
		var button := Button.new()
		button.text = "%s%s" % [Cards.rank_name(card), Cards.symbol(card)]
		button.custom_minimum_size = Vector2(56, 44)
		button.pressed.connect(func():
			var result := ItemEffects.resolve_picker(picker, card)
			if is_instance_valid(layer):
				layer.queue_free()
			_apply_result(result, int(picker["inv_index"])))
		grid.add_child(button)

	layer = Modal.custom(self, String(picker["title"]), grid, [{"text": "Cancel"}])


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

	var gs := RunState.gs
	var board_w := _board.size.x
	var board_h := _board.size.y

	# Animate only between two layouts of the same game at the same board size;
	# a new floor or a resize just snaps. Positions are captured from the current
	# (pre-clear) cards, so this must run before they are freed.
	var type := String(gs.get("type", ""))
	var can_anim := _animate and _last_gtype == type and not type.is_empty() \
		and _last_board_size == Vector2(board_w, board_h) and _board.get_child_count() > 0
	var prev: Dictionary = _capture_positions() if can_anim else {}

	# Detach the previous cards immediately (not just queue_free, which is
	# deferred) so a stale card is never captured or measured twice.
	for child in _board.get_children():
		_board.remove_child(child)
		child.queue_free()

	if gs.is_empty():
		return
	if board_w < 1.0 or board_h < 1.0:
		# Laid out before the board has a size; the board.resized signal calls
		# back once it does.
		return

	_card_size = _fit_card_size(type, board_w, board_h)
	_compute_fan(gs, board_h)

	match gs["type"]:
		"klondike": _layout_klondike(gs)
		"spider": _layout_spider(gs)
		"freecell": _layout_freecell(gs)
		"tripeaks": _layout_tripeaks(gs)
		"pyramid": _layout_pyramid(gs)

	_centre_board(board_w, board_h)
	_last_gtype = type
	_last_board_size = Vector2(board_w, board_h)

	if not prev.is_empty():
		_animate_transition(prev)

	# Re-show the floor-clear overlay if a run was resumed on an already-won
	# board. Guarded on an empty overlay layer so normal rebuilds don't stack it.
	if RunState.win_overlay and _overlays.get_child_count() == 0 and Rules.is_won(gs):
		_show_win_overlay()


# ══════════════════════════════════════════════════════════════════════════════
#  Move animation — cards slide to their new home instead of snapping there.
# ══════════════════════════════════════════════════════════════════════════════
#
# This is automatic: every rebuild compares each card's new position to where it
# was (matched by uid) and slides the difference. Cards that vanished (pyramid
# pairs, spider suit completions, removed cards) fly off and fade. No move code
# has to know about the animation.

const ANIM_DUR := 0.18
const MAX_ANIM_CARDS := 26
var _animate := true
var _last_gtype := ""
var _last_board_size := Vector2.ZERO


func _capture_positions() -> Dictionary:
	var m := {}
	for child in _board.get_children():
		if not (child is Control) or not child.has_meta("card_ref"):
			continue
		var card = child.get_meta("card_ref")
		if typeof(card) == TYPE_DICTIONARY and card.has("uid"):
			m[card["uid"]] = {"pos": (child as Control).global_position, "card": card, "node": child}
	return m


func _animate_transition(prev: Dictionary) -> void:
	var cur := _capture_positions()
	var live := _state_uids(RunState.gs)
	var count := 0
	for uid in prev:
		if count >= MAX_ANIM_CARDS:
			break
		var p: Dictionary = prev[uid]
		if cur.has(uid):
			var c: Dictionary = cur[uid]
			if (p["pos"] as Vector2).distance_to(c["pos"]) > 2.0:
				_fly(c["card"], p["pos"], c["pos"], c["node"])
				count += 1
		elif not live.has(uid):
			# Gone from the board AND from the game state — a card truly removed
			# from play (a completed sequence). A card that merely stopped being
			# rendered because another landed on top of it (a foundation card
			# covered by the next rank) stays put, so it must not launch off.
			_fly_off(p["card"], p["pos"])
			count += 1


## Every card uid anywhere in the game state, however the variant nests its
## piles (tableau columns, foundation stacks, waste, stock, free cells, pyramid
## rows…). Used to tell a card that was removed from play apart from one merely
## buried under a card that landed on it.
func _state_uids(gs: Dictionary) -> Dictionary:
	var out := {}
	_collect_uids(gs.values(), out)
	return out


func _collect_uids(value: Variant, out: Dictionary) -> void:
	if value is Array:
		for item in value:
			_collect_uids(item, out)
	elif value is Dictionary:
		if value.has("uid"):
			out[value["uid"]] = true
		else:
			_collect_uids(value.values(), out)


## A ghost card slides from `from` to `to`; the real card is hidden until it lands.
func _fly(card: Dictionary, from: Vector2, to: Vector2, real_node: Node) -> void:
	if is_instance_valid(real_node):
		(real_node as Control).modulate.a = 0.0
	var ghost := _ghost_card(card)
	ghost.global_position = from
	var tw := create_tween()
	tw.tween_property(ghost, "global_position", to, ANIM_DUR) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if is_instance_valid(real_node):
			(real_node as Control).modulate.a = 1.0
		ghost.queue_free())


## A removed card lifts away and fades, like the web build's launchOff.
func _fly_off(card: Dictionary, from: Vector2) -> void:
	var ghost := _ghost_card(card)
	ghost.global_position = from
	var dir := 1.0 if randf() > 0.5 else -1.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ghost, "global_position", from + Vector2(dir * 80.0, -180.0), 0.42) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.42)
	tw.chain().tween_callback(ghost.queue_free)


func _ghost_card(card: Dictionary) -> Control:
	var ghost := CARD_VIEW.instantiate()
	add_child(ghost)
	ghost.top_level = true
	ghost.z_index = 300
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.custom_minimum_size = _card_size
	ghost.size = _card_size
	var face := card.duplicate()
	face["face_up"] = true
	ghost.setup(face)
	return ghost


## Largest card that keeps the widest row across the board and the fixed content
## height inside it. Column games come out near the width limit (big cards); the
## fan, computed separately, keeps tall columns from spilling off the bottom.
func _fit_card_size(type: String, board_w: float, board_h: float) -> Vector2:
	var spec: Dictionary = LAYOUT.get(type, LAYOUT["klondike"])
	var usable_w := board_w * (1.0 - BOARD_MARGIN * 2.0)
	var usable_h := board_h * (1.0 - BOARD_MARGIN * 2.0)

	var by_width := usable_w / float(spec["w"])
	var by_height := (usable_h / float(spec["h"])) * UITheme.CARD_ASPECT

	var width := clampf(minf(by_width, by_height), 44.0, 260.0)
	return Vector2(width, width / UITheme.CARD_ASPECT)


## Fits the tallest tableau column into the board height. The face-up fan is
## never squeezed below MIN_FAN_UP (which keeps covered ranks readable); once a
## column would overflow at that spacing, the whole card shrinks instead. Only
## the column games fan; the fixed-shape games leave the defaults untouched.
##
## Column height, in card-heights, is `1 + down·FAN_DOWN_FACE_DOWN + up·fan`
## (every card but the last adds a fan step by its own face state), and it sits
## below a header row of `header` card-heights plus a small breathing gap.
func _compute_fan(gs: Dictionary, board_h: float) -> void:
	_fan_up = FAN_DOWN_FACE_UP
	var type: String = gs.get("type", "")
	if not ["klondike", "freecell", "spider"].has(type):
		return
	var spec: Dictionary = LAYOUT[type]
	var ch := _card_size.y
	if ch <= 0.0:
		return
	var usable_h := board_h * (1.0 - BOARD_MARGIN * 2.0)
	var overhead := float(spec["header"]) + 0.35  # header row + breathing gap, in card-heights

	# The card height that lets each column fit at the readable minimum fan; the
	# binding column is the one that demands the smallest card.
	var ch_cap := ch
	for col in gs["tableau"]:
		var counts := _fan_counts(col)
		var up: int = counts[0]
		if up <= 0:
			continue
		var units := 1.0 + float(counts[1]) * FAN_DOWN_FACE_DOWN + float(up) * MIN_FAN_UP + overhead
		ch_cap = minf(ch_cap, usable_h / units)
	if ch_cap < ch:
		# Shrink the card (keeping aspect) so the tallest column fits at MIN_FAN_UP.
		ch = maxf(ch_cap, 44.0 / UITheme.CARD_ASPECT)
		_card_size = Vector2(ch * UITheme.CARD_ASPECT, ch)

	# With the final card height, open the fan as wide as every column allows,
	# between the readable minimum and the loose default.
	var fan := FAN_DOWN_FACE_UP
	for col in gs["tableau"]:
		var counts := _fan_counts(col)
		var up: int = counts[0]
		if up <= 0:
			continue
		var room := usable_h / ch - 1.0 - float(counts[1]) * FAN_DOWN_FACE_DOWN - overhead
		fan = minf(fan, room / float(up))
	_fan_up = clampf(fan, MIN_FAN_UP, FAN_DOWN_FACE_UP)


## [face_up_steps, face_down_steps] a column contributes to its fan — every card
## but the last, counted by its face state.
func _fan_counts(col: Array) -> Array:
	var up := 0
	var down := 0
	for i in range(0, col.size() - 1):
		if col[i]["face_up"]:
			up += 1
		else:
			down += 1
	return [up, down]


## Shifts everything the layout built so the whole board is centred horizontally
## and sits just below the top margin. Layouts can therefore place cards from a
## simple (0,0) origin and stay agnostic about the board's real size.
##
## Centring is measured against the variant's fixed full-board footprint, NOT the
## bounding box of the cards currently on the table. TriPeaks and Pyramid drop a
## cleared card without leaving a placeholder, so a measured box would shrink and
## shift as cards are removed — re-centring the remaining cards and making the
## board visibly jump on every click. A fixed footprint keeps it anchored.
func _centre_board(board_w: float, board_h: float) -> void:
	var content_w := _content_width(RunState.gs)
	if content_w <= 0.0:
		return
	# Every layout builds from a (0,0) origin, so the offset alone places it: the
	# top-left stays pinned to the top margin regardless of which cards remain.
	var offset := Vector2((board_w - content_w) * 0.5, board_h * BOARD_MARGIN)
	for child in _board.get_children():
		if child is Control:
			(child as Control).position += offset


## The board's full horizontal footprint for this variant — the right edge of the
## widest structural row, independent of which cards are still on the table. Pile
## and slot counts are fixed for a floor, so cleared cards never change this and
## the board never re-centres out from under the player.
func _content_width(gs: Dictionary) -> float:
	var card_w := _card_size.x
	match String(gs.get("type", "klondike")):
		"klondike":
			# Seven tableau columns; the four foundations end at the same edge.
			var step := card_w * (1.0 + PILE_GAP)
			return step * 6.0 + card_w
		"spider":
			# Ten tableau columns.
			var step := card_w * (1.0 + PILE_GAP)
			return step * 9.0 + card_w
		"freecell":
			# Whichever is wider: eight tableau columns, or the free-cell row plus
			# the half-gap and the four foundations (cell count varies by floor).
			var step := card_w * (1.0 + PILE_GAP)
			var cells: int = (gs.get("freecells", []) as Array).size()
			var tableau_right := step * 7.0 + card_w
			var foundation_right := step * (cells + 3.5) + card_w
			return maxf(tableau_right, foundation_right)
		"tripeaks":
			# Ten cards across the base row (tw = card width + a 0.10 gap).
			var tw := card_w * 1.10
			return tw * 9.0 + card_w
		"pyramid":
			# Seven cards across the base row, matching the layout's `total`.
			var tw := card_w * 1.10
			return tw * 7.0 - card_w * 0.10
	return card_w


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
		# Keep a handle to the card dict so the animation layer can follow it
		# across a move by its uid.
		view.set_meta("card_ref", card)
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
			y += _card_size.y * (_fan_up if pile[i]["face_up"] else FAN_DOWN_FACE_DOWN)


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
			y += _card_size.y * (_fan_up if pile[i]["face_up"] else FAN_DOWN_FACE_DOWN)


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
			y += _card_size.y * _fan_up


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

## A card was pressed. Record it and wait: motion past the threshold starts a
## drag, a release in place is a click. Acting on release keeps click-to-place
## working exactly as before.
func _on_card_pressed(view: Control) -> void:
	if RunState.gs.is_empty():
		return
	_press = {
		"view": view,
		"meta": view.get_meta("slot"),
		"start": _pending_start,
	}


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			# Remember where the press landed; the card's press signal fires
			# immediately after this and reads _pending_start.
			_pending_start = mb.position
		else:
			if _dragging:
				_end_drag(mb.position)
			elif not _press.is_empty():
				# No movement: treat exactly as a click.
				_click_slot(_press["meta"])
			_press = {}
		return

	if event is InputEventMouseMotion and (not _press.is_empty() or _dragging):
		var pointer := (event as InputEventMouseMotion).position
		if _dragging:
			_ghost.global_position = pointer - _grab_offset
		elif pointer.distance_to(_press["start"]) > _drag_threshold() and _is_draggable(_press["meta"]):
			_begin_drag()


## DRAG_THRESHOLD is in screen pixels; convert to the design-canvas units the
## input positions actually use, so the feel is the same at any window size.
func _drag_threshold() -> float:
	var win := get_window()
	if win == null or win.size.x <= 0:
		return DRAG_THRESHOLD
	var ratio := get_viewport().get_visible_rect().size.x / float(win.size.x)
	return DRAG_THRESHOLD * ratio


## The click behaviour, unchanged — runs on a release that did not become a drag.
func _click_slot(meta: Dictionary) -> void:
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
		# One-click play: a card with an obvious legal move goes there directly.
		# Only when there is no obvious move does the click fall through to a
		# manual select (drag still lets the player place a card anywhere).
		if _auto_play(meta):
			return
		_begin_selection(meta)
	else:
		_handle_target(meta)


# ══════════════════════════════════════════════════════════════════════════════
#  One-click auto-play
# ══════════════════════════════════════════════════════════════════════════════

## Sends the clicked card (and its movable run) to the most obvious legal spot:
## a foundation first, then a tableau column, then a free cell. Returns whether
## it moved. Klondike / Spider / FreeCell only — Pyramid and TriPeaks handle
## their own single clicks.
func _auto_play(meta: Dictionary) -> bool:
	var gs := RunState.gs
	var type: String = gs.get("type", "")
	if not ["klondike", "spider", "freecell"].has(type):
		return false

	var from := {}
	match String(meta.get("kind", "")):
		"tableau":
			var pile: Array = gs["tableau"][meta["col"]]
			var idx := int(meta.get("index", pile.size() - 1))
			if idx < 0 or idx >= pile.size() or not pile[idx]["face_up"]:
				return false
			if type == "klondike" and not _is_valid_run(pile, idx):
				return false
			if type == "spider" and pile.size() - idx > Rules.spider_sequence_length(pile):
				return false
			if type == "freecell" and pile.size() - idx > Rules.freecell_max_movable(gs):
				return false
			from = {"kind": "tableau", "col": meta["col"], "index": idx}
		"waste":
			if gs["waste"].is_empty():
				return false
			from = {"kind": "waste"}
		"freecell":
			if gs["freecells"][meta["col"]] == null:
				return false
			from = {"kind": "freecell", "col": meta["col"]}
		_:
			return false

	for target in _auto_targets(gs, from):
		if _try_move(from, target):
			AudioManager.card_moved()
			_after_move()
			return true
	return false


## Candidate destinations for an auto-play, in priority order.
func _auto_targets(gs: Dictionary, from: Dictionary) -> Array:
	var type: String = gs["type"]
	var cards := _take_cards(gs, from, true)
	if cards.is_empty():
		return []

	var out := []
	# 1. A foundation, if a single card fits (the classic one-click destination).
	if cards.size() == 1 and type in ["klondike", "freecell"]:
		var can := Rules.klondike_can_foundation(cards[0], gs["foundations"]) if type == "klondike" \
			else Rules.freecell_can_foundation(cards[0], gs["foundations"])
		if can:
			out.append({"kind": "foundation", "col": int(cards[0]["suit"])})

	# 2. Tableau columns — non-empty first; an empty column only if it uncovers
	#    something (moving a whole column onto an empty one gains nothing).
	var src_col := int(from.get("col", -1))
	var whole_column: bool = from.get("kind") == "tableau" and int(from.get("index", 0)) == 0
	var empties := []
	for c in gs["tableau"].size():
		if from.get("kind") == "tableau" and c == src_col:
			continue
		var pile: Array = gs["tableau"][c]
		var ok := false
		match type:
			"klondike": ok = Rules.klondike_can_tableau(cards, pile)
			"spider": ok = Rules.spider_can_drop(cards, pile)
			"freecell": ok = Rules.freecell_can_tableau(cards[0], pile)
		if not ok:
			continue
		if pile.is_empty():
			if not whole_column:
				empties.append({"kind": "tableau", "col": c})
		else:
			out.append({"kind": "tableau", "col": c})
	out.append_array(empties)

	# 3. A free cell as a last resort (FreeCell only, single card).
	if type == "freecell" and cards.size() == 1:
		for i in gs["freecells"].size():
			if gs["freecells"][i] == null:
				out.append({"kind": "freecell", "col": i})
				break
	return out


# ══════════════════════════════════════════════════════════════════════════════
#  Drag and drop
# ══════════════════════════════════════════════════════════════════════════════

## A source is draggable only when a plain move makes sense: one of the three
## tableau games, no armed item or stash, and a legal movable run under the grab.
## The checks mirror _begin_selection so drag and click accept the same moves.
func _is_draggable(meta: Dictionary) -> bool:
	if not _item_mode.is_empty():
		return false
	if RunState.toolbox_uses > 0 and RunState.toolbox_card == null:
		return false
	var gs := RunState.gs
	var type: String = gs.get("type", "")
	if not ["klondike", "spider", "freecell"].has(type):
		return false

	match String(meta.get("kind", "")):
		"tableau":
			var pile: Array = gs["tableau"][meta["col"]]
			var idx := int(meta.get("index", pile.size() - 1))
			if idx < 0 or idx >= pile.size() or not pile[idx]["face_up"]:
				return false
			if type == "klondike" and not _is_valid_run(pile, idx):
				return false
			if type == "spider" and pile.size() - idx > Rules.spider_sequence_length(pile):
				return false
			if type == "freecell" and pile.size() - idx > Rules.freecell_max_movable(gs):
				return false
			return true
		"waste":
			return not gs["waste"].is_empty()
		"freecell":
			return gs["freecells"][meta["col"]] != null
	return false


func _begin_drag() -> void:
	var meta: Dictionary = _press["meta"]
	var gs := RunState.gs
	_drag_source = meta
	_drag_cards = _cards_for_drag(gs, meta)
	if _drag_cards.is_empty():
		_press = {}
		return

	_selection = {}
	_dragging = true
	var source_view: Control = _press["view"]
	_grab_offset = _press["start"] - source_view.global_position

	# Dim the cards being carried so the board shows where they came from.
	for child in _board.get_children():
		if child is Control and _belongs_to_drag(child.get_meta("slot", {})):
			(child as Control).modulate.a = 0.3

	# A floating stack of the dragged cards that follows the cursor.
	_ghost = Control.new()
	_ghost.top_level = true
	_ghost.z_index = 100
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ghost)
	for i in _drag_cards.size():
		var card_view := CARD_VIEW.instantiate()
		_ghost.add_child(card_view)
		card_view.position = Vector2(0, i * _card_size.y * _fan_up)
		card_view.custom_minimum_size = _card_size
		card_view.size = _card_size
		card_view.setup(_drag_cards[i])
		card_view.face_up = true
		card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.global_position = source_view.global_position
	AudioManager.card_taken()


## The run that would be picked up from a slot, without removing it yet.
func _cards_for_drag(gs: Dictionary, meta: Dictionary) -> Array:
	match String(meta.get("kind", "")):
		"tableau":
			var pile: Array = gs["tableau"][meta["col"]]
			return pile.slice(int(meta.get("index", pile.size() - 1)))
		"waste":
			return [gs["waste"][gs["waste"].size() - 1]] if not gs["waste"].is_empty() else []
		"freecell":
			var c = gs["freecells"][meta["col"]]
			return [c] if c != null else []
	return []


## Whether a board slot is part of the run currently being dragged.
func _belongs_to_drag(meta: Dictionary) -> bool:
	if meta.get("kind") != _drag_source.get("kind"):
		return false
	if meta.get("col", -1) != _drag_source.get("col", -1):
		return false
	if _drag_source.get("kind") == "tableau":
		return int(meta.get("index", -1)) >= int(_drag_source.get("index", 0))
	return true


## `drop_point` is in canvas coords; convert to board-local for the hit test.
func _end_drag(drop_point: Vector2) -> void:
	var target := _target_at(drop_point - _board.global_position)
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_dragging = false

	if target.is_empty() or _same_slot(target, _drag_source):
		_rebuild()  # snap back
		return

	if _try_move(_drag_source, target):
		AudioManager.card_moved()
		_after_move()
	else:
		_rebuild()  # rejected: snap back
	_drag_source = {}
	_drag_cards = []


func _same_slot(a: Dictionary, b: Dictionary) -> bool:
	return a.get("kind") == b.get("kind") and a.get("col", -1) == b.get("col", -1)


## The drop target under a board-local point: the topmost card or empty slot
## there, reduced to the pile it belongs to. Dragged source cards are skipped so
## dropping onto a column always finds the resting cards beneath the ghost.
func _target_at(local_pos: Vector2) -> Dictionary:
	var children := _board.get_children()
	for i in range(children.size() - 1, -1, -1):
		var child = children[i]
		if not (child is Control):
			continue
		var meta: Dictionary = child.get_meta("slot", {})
		if meta.is_empty() or _belongs_to_drag(meta):
			continue
		if (child as Control).get_rect().has_point(local_pos):
			return {"kind": meta.get("kind", ""), "col": meta.get("col", -1),
				"index": meta.get("index", -1)}
	return {}


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
	# Klondike scores +5 for each card it flips face-up (klAutoReveal). Spider
	# flips its newly-exposed cards too but awards nothing for it, matching the
	# web build's silent reveal.
	match gs["type"]:
		"klondike":
			for revealed in Rules.klondike_auto_reveal(gs):
				RunState.gs = gs
				RunState.award_card_points(revealed, Rules.PTS_REVEAL)
		"spider":
			Rules.klondike_auto_reveal(gs)
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


## Each variant scores a move differently, exactly as the web build did:
##   Klondike  waste→tableau earns 5 card-points per card; →foundation earns up
##             to the 20-point cap. Tableau→tableau earns nothing.
##   FreeCell  →foundation is a flat +5 ('card to foundation'); nothing else.
##   Spider    no per-move points at all — only the +100 suit-complete bonus,
##             which _try_move awards separately.
func _score_move(gs: Dictionary, from: Dictionary, to: Dictionary, cards: Array) -> void:
	RunState.gs = gs
	match gs.get("type", ""):
		"klondike":
			if to.get("kind") == "foundation":
				RunState.award_card_points(cards[0], Rules.PTS_FOUNDATION)
			elif from.get("kind") == "waste" and to.get("kind") == "tableau":
				for c in cards:
					RunState.award_card_points(c, Rules.PTS_WASTE_TO_TABLEAU)
		"freecell":
			if to.get("kind") == "foundation":
				RunState.add_score(Rules.PTS_FREECELL_FOUNDATION, "card to foundation")


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


## TriPeaks scores an ascending streak: each card taken from the peaks scores the
## running streak length and lengthens it, with a +15 bonus for a peak (a top
## card, index < 3). A click on a card that cannot be taken breaks the streak.
## Ported from the src==='pycard' branch of handleClick. Note a stock draw does
## NOT reset the streak in the web build, so _draw_stock leaves it untouched.
func _tripeaks_play(meta: Dictionary) -> void:
	var gs := Cards.clone_state(RunState.gs)
	if meta.get("kind") != "pyramid":
		return
	var idx := int(meta["index"])
	var waste_top = null
	if not gs["waste"].is_empty():
		waste_top = gs["waste"][gs["waste"].size() - 1]
	var card = gs["pyramid"][idx] if Rules.tripeaks_free(gs["pyramid"], idx) else null
	if card == null or not Rules.tripeaks_can_play(card, waste_top):
		# A failed play resets the streak.
		RunState.tp_streak = 0
		_rebuild()
		return
	RunState.push_undo()
	gs["pyramid"][idx] = null
	card["face_up"] = true
	gs["waste"].append(card)
	Rules.tripeaks_update_face_up(gs["pyramid"])
	RunState.gs = gs
	RunState.tp_streak += 1
	RunState.add_score(RunState.tp_streak, "streak x%d" % RunState.tp_streak)
	if idx < 3:
		RunState.add_score(Rules.PTS_TRIPEAKS_PEAK, "top card bonus")
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
		# A King clears alone for a flat +5, logged by its source as the web did.
		var reason := "waste pair" if meta.get("kind") == "waste" else "king removed"
		RunState.add_score(Rules.PTS_PYRAMID_KING, reason)
		_selection = {}
		AudioManager.card_moved()
		_after_move()
		return

	# One-click: a free pyramid card that pairs with the waste top clears at once.
	if _selection.is_empty() and meta.get("kind") == "pyramid" and not gs["waste"].is_empty():
		var waste_top = gs["waste"][gs["waste"].size() - 1]
		if int(picked["rank"]) + int(waste_top["rank"]) == 13:
			RunState.push_undo()
			_pyramid_remove(gs, meta)
			_pyramid_remove(gs, {"kind": "waste"})
			RunState.gs = gs
			RunState.add_score(Rules.PTS_PYRAMID_PAIR, "pair matched")
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
		# Any pair summing to 13 scores a flat +10, regardless of source.
		RunState.add_score(Rules.PTS_PYRAMID_PAIR, "pair matched")
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
		_show_win_overlay()


## The floor-clear celebration, ported from winOverlayHTML. It pauses on the
## cleared board and waits for the player; the floor-clear bonus and the routing
## to the next floor, an interlude, or victory all happen when they descend —
## RunState.next_floor does both, exactly as the web build's nextFloor did.
func _show_win_overlay() -> void:
	AudioManager.card_moved()
	var last := RunState.floor_index >= GameData.TOTAL_FLOORS - 1
	var root := _overlay_root(0.85)
	var panel := _framed_panel()
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.custom_minimum_size = Vector2(420, 0)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_child(box)
	panel.add_child(margin)

	var title := Label.new()
	title.text = "🚪 ESCAPED!" if last else "✅ FLOOR CLEARED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.font_at("display", 700))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(title)

	var message := Label.new()
	message.text = ("You burst into the streets! You are FREE!" if last
		else "Staircase found. Descending…")
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", UITheme.TEXT)
	box.add_child(message)

	var descend := Button.new()
	descend.text = "[ ESCAPE ]" if last else "[ DESCEND ]"
	descend.pressed.connect(func():
		# next_floor changes the screen, which frees this scene and its overlay.
		RunState.next_floor())
	box.add_child(descend)


# ══════════════════════════════════════════════════════════════════════════════
#  Overlays (pause, score history)
# ══════════════════════════════════════════════════════════════════════════════

func _clear_overlays() -> void:
	for child in _overlays.get_children():
		child.queue_free()


## A full-screen dimmer that swallows board input while an overlay is up.
func _overlay_root(dim: float) -> Control:
	_clear_overlays()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, dim)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)
	_overlays.add_child(root)
	return root


func _framed_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.occult_panel())
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	return panel


func _show_pause_overlay() -> void:
	var root := _overlay_root(0.9)
	var panel := _framed_panel()
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	box.custom_minimum_size = Vector2(360, 0)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_child(box)
	panel.add_child(margin)

	var title := Label.new()
	title.text = "⏸ PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.font_at("display", 700))
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(title)

	var resume := Button.new()
	resume.text = "▶ Continue"
	resume.pressed.connect(func():
		RunState.start_timer()
		_clear_overlays())
	box.add_child(resume)


## The floor's scoring ledger, opened by clicking the score. Ported from
## scoreHistOverlayHTML — only this floor's events, most recent first, with a
## running floor total.
func _show_score_history() -> void:
	var root := _overlay_root(0.75)
	# Clicking the dim area outside the panel closes it. The background rect (the
	# root's first child) is what actually receives the click, so listen there.
	var bg := root.get_child(0) as Control
	bg.gui_input.connect(func(e):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_clear_overlays())

	var panel := _framed_panel()
	root.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(440, 0)
	# Stop clicks inside the panel from bubbling up to the close-on-outside handler.
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.add_child(box)

	var title := Label.new()
	title.text = "★ Score History — Floor %d" % (GameData.TOTAL_FLOORS - RunState.floor_index)
	title.add_theme_font_override("font", UITheme.font_at("display", 700))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 2)
	scroll.add_child(rows)

	var floor_total := 0
	var count := 0
	for e in RunState.score_log:
		if int(e.get("floor", -1)) != RunState.floor_index:
			continue
		count += 1
		var amount := int(e.get("amount", 0))
		floor_total += amount
		rows.add_child(_score_row(str(e.get("reason", "score")),
			"%s%d pts" % ["+" if amount >= 0 else "", amount],
			UITheme.GOLD if amount >= 0 else UITheme.DANGER))

	if count == 0:
		var none := Label.new()
		none.text = "No scoring events this floor yet."
		none.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		rows.add_child(none)
	else:
		var sep := HSeparator.new()
		box.add_child(sep)
		box.add_child(_score_row("Floor total",
			"%s%d pts" % ["+" if floor_total >= 0 else "", floor_total], UITheme.TEXT))

	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(_clear_overlays)
	box.add_child(close)


func _score_row(label_text: String, value_text: String, value_color: Color) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", UITheme.TEXT)
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = value_text
	value_label.add_theme_color_override("font_color", value_color)
	row.add_child(value_label)
	return row
