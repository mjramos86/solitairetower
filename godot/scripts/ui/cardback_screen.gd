extends Control

## Card back chooser. Ported from renderCardbackSelect in index.html.
##
## A grid of the four card backs. Unlocked ones are pickable and the current
## choice is ticked; locked ones show a padlock and their unlock hint. `marie`
## is gated behind revealing Mary in the compendium, which now persists locally
## for every player rather than only signed-in accounts.
##
## The chosen back is written to the profile immediately, so the next dealt board
## (card_view reads the profile on ready) shows it.

const CARD_W := 220.0
const CARD_H := CARD_W / UITheme.CARD_ASPECT

@onready var _grid: HBoxContainer = $Layout/Grid
@onready var _title: Label = $Layout/Title
@onready var _subtitle: Label = $Layout/Subtitle
@onready var _back_button: Button = $Layout/Back


func _ready() -> void:
	_title.text = "Choose Your Cardback"
	_title.add_theme_font_override("font", UITheme.font_at("display", 700))
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", UITheme.GOLD)

	_subtitle.text = "Locked designs are revealed by uncovering a Time Patron's connection to Solitaire in the Compendium."
	_subtitle.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_back_button.text = "← Back to Tower"
	_back_button.pressed.connect(func(): RunState.set_screen(RunState.cardback_return))

	_refresh()


## An entry is available if flagged unlocked, or its required patron is revealed.
func _is_unlocked(entry: Dictionary) -> bool:
	if bool(entry.get("unlocked", false)):
		return true
	if entry.has("requires_reveal"):
		return SaveManager.is_patron_revealed(String(entry["requires_reveal"]))
	return false


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var current := String(SaveManager.profile.get("cardback", GameData.CARDBACKS[0]["id"]))
	for entry in GameData.CARDBACKS:
		_grid.add_child(_build_card(entry, current))


func _build_card(entry: Dictionary, current: String) -> Control:
	var id := String(entry["id"])
	var unlocked := _is_unlocked(entry)
	var is_current := id == current

	var panel := PanelContainer.new()
	var style := UITheme.occult_panel()
	if is_current:
		style.border_color = UITheme.GOLD
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var art := Control.new()
	art.custom_minimum_size = Vector2(CARD_W, CARD_H)
	art.clip_contents = true
	col.add_child(art)

	if unlocked:
		var tex := TextureRect.new()
		tex.texture = load(AssetPaths.CARDBACKS.get(id, AssetPaths.CARDBACKS[AssetPaths.DEFAULT_CARDBACK]))
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(tex)
	else:
		var bg := ColorRect.new()
		bg.color = UITheme.BG_DEEP
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(bg)
		var lock := Label.new()
		lock.text = "🔒"
		lock.add_theme_font_size_override("font_size", 48)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(lock)

	var name_label := Label.new()
	name_label.text = String(entry["name"]) + (" ✓" if is_current else "")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_override("font", UITheme.font_at("display", 600))
	name_label.add_theme_color_override("font_color",
		UITheme.GOLD if is_current else (UITheme.TEXT if unlocked else UITheme.TEXT_DIM))
	col.add_child(name_label)

	if unlocked:
		# Whole card is a click target. A Button would fight the layout, so use
		# an input hook on the panel instead.
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(func(event): _on_card_input(event, id))
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		var hint := Label.new()
		hint.text = "Locked"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		col.add_child(hint)

	return panel


func _on_card_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_choose(id)


func _choose(id: String) -> void:
	SaveManager.set_cardback(id)
	SaveManager.save_game()
	AudioManager.card_taken()
	_refresh()
