extends Control

## The four-slot save picker, reached from the title menu in one of two modes
## (RunState.slot_mode):
##   "load" — resume an existing save; empty slots are inert.
##   "new"  — start a fresh game; picking a slot asks for a player name (and
##            confirms first if the slot is already occupied).
##
## The chosen name is stored on the slot and shown here, on the tower map, and on
## the card table.

@onready var _title: Label = $Center/Col/Title
@onready var _slots: HBoxContainer = $Center/Col/Slots
@onready var _back: Button = $Center/Col/Back

const CARD_BG := Color(0.039, 0.024, 0.086, 0.7)


func _ready() -> void:
	_title.add_theme_font_override("font", UITheme.font_at("title", 900))
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", UITheme.GOLD)
	_title.text = "NEW GAME" if RunState.slot_mode == "new" else "LOAD GAME"

	_back.pressed.connect(func(): RunState.set_screen("title"))
	_build_slots()


func _build_slots() -> void:
	for child in _slots.get_children():
		child.queue_free()
	for i in SaveManager.MAX_SLOTS:
		_slots.add_child(_build_slot(SaveManager.slot_summary(i)))


func _build_slot(summary: Dictionary) -> Control:
	var index := int(summary["index"])
	var exists := bool(summary.get("exists", false))

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _card_box())
	panel.custom_minimum_size = Vector2(220, 260)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.add_child(box)
	panel.add_child(margin)

	var head := Label.new()
	head.text = "SLOT %d" % (index + 1)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_override("font", UITheme.font_at("display", 600))
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	box.add_child(head)

	if exists:
		_fill_used_slot(box, summary)
	else:
		_fill_empty_slot(box)

	box.add_child(_spacer())

	# Actions depend on the mode.
	if RunState.slot_mode == "new":
		var start := _button("New Game" if not exists else "Overwrite",
			func(): _start_new(index, exists))
		box.add_child(start)
		if exists:
			box.add_child(_button("Delete", func(): _confirm_delete(index), true))
	else:  # load
		if exists:
			box.add_child(_button("Continue" if bool(summary.get("has_run", false)) else "Play",
				func(): _load(index)))
			box.add_child(_button("Delete", func(): _confirm_delete(index), true))
		else:
			var disabled := _button("Empty", func(): pass)
			disabled.disabled = true
			box.add_child(disabled)

	return panel


func _fill_used_slot(box: VBoxContainer, summary: Dictionary) -> void:
	var name := Label.new()
	name.text = str(summary.get("name", ""))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_font_override("font", UITheme.font_at("title", 700))
	name.add_theme_font_size_override("font_size", 24)
	name.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(name)

	var progress := Label.new()
	if bool(summary.get("has_run", false)):
		progress.text = "Floor %d of %d" % [int(summary.get("floor", 10)), GameData.TOTAL_FLOORS]
	else:
		progress.text = "No run in progress"
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_color_override("font_color", UITheme.TEXT)
	box.add_child(progress)

	var energy := Label.new()
	energy.text = "⚡ %d   ✓ %d" % [int(summary.get("banked_credits", 0)), int(summary.get("runs_won", 0))]
	energy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy.add_theme_font_override("font", UITheme.font_at("display", 500))
	energy.add_theme_font_size_override("font_size", 14)
	energy.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(energy)


func _fill_empty_slot(box: VBoxContainer) -> void:
	var empty := Label.new()
	empty.text = "— Empty —"
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.add_theme_font_override("font", UITheme.font_at("display", 500))
	empty.add_theme_font_size_override("font_size", 18)
	empty.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	box.add_child(empty)


# ══════════════════════════════════════════════════════════════════════════════
#  Actions
# ══════════════════════════════════════════════════════════════════════════════

func _start_new(index: int, exists: bool) -> void:
	if exists:
		Modal.confirm(self, "Overwrite Slot",
			"Overwrite the save in slot %d? This cannot be undone." % (index + 1),
			func(): _ask_name(index),
			"Overwrite", "Cancel", true)
	else:
		_ask_name(index)


## Prompts for a player name, then creates the save and rolls into the intro.
func _ask_name(index: int) -> void:
	var field := LineEdit.new()
	field.placeholder_text = "Player %d" % (index + 1)
	field.max_length = SaveManager.MAX_NAME_LEN
	field.custom_minimum_size = Vector2(320, 0)
	field.add_theme_font_override("font", UITheme.font("body"))  # typed name → Inter
	field.add_theme_font_size_override("font_size", 22)

	var layer: CanvasLayer
	var begin := func():
		var chosen := field.text
		if is_instance_valid(layer):
			layer.queue_free()
		SaveManager.new_game(index, chosen)
		# A brand-new save opens with the story intro, which starts the run.
		RunState.intro_replay = false
		RunState.set_screen("patron-dialogue")

	layer = Modal.custom(self, "Name your player", field, [
		{"text": "Cancel"},
		{"text": "Begin", "action": begin, "primary": true},
	])
	# Enter in the field confirms too.
	field.text_submitted.connect(func(_t): begin.call())
	field.grab_focus()


func _load(index: int) -> void:
	var resumable := SaveManager.load_slot(index)
	if resumable:
		RunState.from_snapshot(SaveManager.run)
		# Resume on the map, not mid-hand: the board is restored but the undo
		# history is not, so land the player on a beat they can act from.
		RunState.set_screen("map")
	else:
		# A slot with no in-progress descent starts a fresh run on its profile,
		# skipping the intro the player has already seen.
		RunState.new_run()
		RunState.set_screen("map")


func _confirm_delete(index: int) -> void:
	Modal.confirm(self, "Delete Save",
		"Delete the save in slot %d permanently?" % (index + 1),
		func():
			SaveManager.delete_slot(index)
			# Leaving load mode with no saves left would strand the player; drop back
			# to the title if this was the last one.
			if RunState.slot_mode == "load" and not SaveManager.any_slot_exists():
				RunState.set_screen("title")
			else:
				_build_slots(),
		"Delete", "Cancel", true)


# ══════════════════════════════════════════════════════════════════════════════
#  Bits
# ══════════════════════════════════════════════════════════════════════════════

func _card_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_BG
	s.set_border_width_all(1)
	s.border_color = UITheme.GOLD_DIM
	s.set_corner_radius_all(6)
	return s


func _button(text: String, action: Callable, danger := false) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if danger:
		b.add_theme_color_override("font_color", UITheme.MAROON)
	b.pressed.connect(action)
	return b


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c
