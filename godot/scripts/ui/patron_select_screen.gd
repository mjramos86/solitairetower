extends Control

## Time Patron picker, shown once at the start of a run (after the intro, before
## the map), ported from renderPatronSelect in index.html.
##
## Each patron shapes the whole descent — above all the shop they stock — so the
## card states only what the player needs to choose: portrait, name, occupation,
## and a one-line flavour that hints at the playstyle. Unlocked patrons are
## pickable; in-development ones show their name and a tag; unrevealed ones stay
## a padlocked "???".

const CARD_W := 260.0
const PORTRAIT := 176.0

@onready var _grid: HBoxContainer = $Layout/Grid
@onready var _title: Label = $Layout/Title
@onready var _subtitle: Label = $Layout/Subtitle
@onready var _confirm: Label = $Layout/Confirm


func _ready() -> void:
	_title.text = "Choose Your Time Patron"
	_title.add_theme_font_override("font", UITheme.font_at("display", 700))
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", UITheme.GOLD)

	_subtitle.text = "An ally for this descent, lending their nature to the wares you'll find along the way."
	_subtitle.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_confirm.text = "Select John Dee to begin your descent."
	_confirm.add_theme_font_override("font", UITheme.font("pixel"))
	_confirm.add_theme_font_size_override("font_size", 14)
	_confirm.add_theme_color_override("font_color", UITheme.TEXT_DIM)

	for patron in Narrative.PATRONS:
		_grid.add_child(_build_card(patron))


func _build_card(patron: Dictionary) -> Control:
	var unlocked := bool(patron.get("unlocked", false))
	var revealed := bool(patron.get("revealed", false))

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.occult_panel())
	panel.custom_minimum_size = Vector2(CARD_W, 0)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)

	# Portrait (or a padlock for a patron not yet revealed).
	var art := Control.new()
	art.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.clip_contents = true
	col.add_child(art)
	if revealed:
		var tex := TextureRect.new()
		tex.texture = load(String(patron["img"]))
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
		lock.add_theme_font_size_override("font_size", 52)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(lock)

	# Name.
	var name_lbl := Label.new()
	name_lbl.text = _patron_name(patron) if revealed else "???"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_override("font", UITheme.font_at("display", 600))
	name_lbl.add_theme_font_size_override("font_size", 21)
	name_lbl.add_theme_color_override("font_color", UITheme.GOLD if unlocked else UITheme.TEXT)
	col.add_child(name_lbl)

	if not revealed:
		return panel  # unrevealed patrons show only the padlocked "???"

	# Occupation.
	var occ := String(patron.get("occupation", ""))
	if occ != "":
		var occ_lbl := Label.new()
		occ_lbl.text = occ
		occ_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		occ_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		occ_lbl.custom_minimum_size = Vector2(CARD_W - 28, 0)
		occ_lbl.add_theme_font_override("font", UITheme.font("pixel"))
		occ_lbl.add_theme_font_size_override("font_size", 13)
		occ_lbl.add_theme_color_override("font_color", Color("a98b4f"))  # readable muted gold
		col.add_child(occ_lbl)

	# Strategy flavour.
	var tagline := String(patron.get("tagline", ""))
	if tagline != "":
		var flavour := Label.new()
		flavour.text = tagline
		flavour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flavour.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		flavour.custom_minimum_size = Vector2(CARD_W - 28, 0)
		flavour.add_theme_font_override("font", UITheme.font("body"))
		flavour.add_theme_font_size_override("font_size", 16)
		flavour.add_theme_color_override("font_color", UITheme.TEXT)
		col.add_child(flavour)

	if unlocked:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(event): _on_card_input(event, String(patron["id"])))
	else:
		# Revealed but not yet playable.
		var tag := Label.new()
		tag.text = "In development"
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_font_override("font", UITheme.font("pixel"))
		tag.add_theme_font_size_override("font_size", 12)
		tag.add_theme_color_override("font_color", UITheme.GOLD)
		col.add_child(tag)

	return panel


## Patrons keep their alias until revealed in the compendium.
func _patron_name(patron: Dictionary) -> String:
	if bool(patron.get("revealed", false)) and patron.has("true_name") \
			and SaveManager.is_patron_revealed(String(patron["id"])):
		return String(patron["true_name"])
	return String(patron["name"])


func _on_card_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_choose(id)


func _choose(id: String) -> void:
	RunState.patron = id
	AudioManager.card_taken()
	RunState.set_screen("map")
