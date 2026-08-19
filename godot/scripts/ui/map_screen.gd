extends Control

## Tower map. The centre is the tower with its floor nodes (tower_map.gd); this
## script fills the left info panel and the right high-score list, matching the
## layout of renderMap in index.html: a descent from floor 10 down to floor 1.
##
## The styling reproduces the web build's occult look: gold-bordered side
## sections with Cinzel small-caps labels, a Playfair title with a soft glow, and
## a gold-framed high-score panel with a header band.

@onready var _title: Label = $Head/Title
@onready var _sub: Label = $Head/Sub
@onready var _tagline: Label = $Head/Tagline
@onready var _side: VBoxContainer = $Body/SidePanel/Side
@onready var _tower = $Body/Tower
@onready var _scores_frame: PanelContainer = $Body/ScoresPad/ScoresFrame
@onready var _scores_title: Label = $Body/ScoresPad/ScoresFrame/ScoresPanel/ScoresTitle
@onready var _scores: VBoxContainer = $Body/ScoresPad/ScoresFrame/ScoresPanel/ScoresScroll/Scores

# --- occult palette bits reused from the web map CSS ---
const SECTION_BG := Color(0.039, 0.024, 0.086, 0.7)   # rgba(10,6,22,.7)
const SCORE_BG := Color(0.039, 0.024, 0.086, 0.85)
const HEART := Color("e74c3c")                         # --life


func _ready() -> void:
	# The title carries a soft gold glow, as .map-title does with its text-shadow.
	_title.add_theme_font_override("font", UITheme.font_at("title", 900))
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_color", UITheme.GOLD)
	_title.add_theme_color_override("font_outline_color", UITheme.GOLD_GLOW)
	_title.add_theme_constant_override("outline_size", 10)

	_sub.add_theme_font_override("font", UITheme.font_at("body", 500))
	_sub.add_theme_font_size_override("font_size", 20)
	_sub.add_theme_color_override("font_color", UITheme.TEXT)

	_tagline.add_theme_font_override("font", UITheme.font_at("display", 500))
	_tagline.add_theme_font_size_override("font_size", 16)
	_tagline.add_theme_color_override("font_color", UITheme.GOLD)

	_style_scores_panel()

	_tower.game_chosen.connect(func(type, floor_index): RunState.start_game(type, floor_index))

	RunState.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_build_side()
	_refresh_scores()


# ══════════════════════════════════════════════════════════════════════════════
#  Left info panel
# ══════════════════════════════════════════════════════════════════════════════

func _build_side() -> void:
	for child in _side.get_children():
		child.queue_free()

	_add_section("Time Patron", _patron_badge())

	var hearts := ""
	for i in RunState.lives:
		hearts += "♥ "
	if hearts == "":
		hearts = "—"
	_add_section("Lives", _text_value(hearts.strip_edges(), HEART, 26))

	_add_section("Time Credits", _text_value("⏳ %d" % RunState.gold, UITheme.GOLD, 20))
	_add_section("Time Energy",
		_text_value("⚡ %d" % int(SaveManager.profile.get("banked_credits", 0)), UITheme.GOLD, 20))

	_add_section("🎒 Inventory", _inventory_slots())

	_add_section("Lore", _panel_button("📖 Compendium",
		func(): RunState.set_screen("compendium")))
	_add_section("Customize", _panel_button("🂠 Cardback", func():
		RunState.cardback_return = "map"
		RunState.set_screen("cardback-select")))
	_side.add_child(_panel_button("▶ Watch Intro", func():
		RunState.intro_replay = true
		RunState.set_screen("patron-dialogue")))


## Each side entry is a gold-bordered card with a Cinzel small-caps label, like
## .map-side-section / .map-side-label.
func _add_section(label_text: String, content: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _section_box())

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(label)
	box.add_child(content)
	_side.add_child(panel)


func _section_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = SECTION_BG
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = UITheme.GOLD_DIM
	s.set_corner_radius_all(5)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


func _text_value(text: String, color: Color, font_size := 18) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Portrait over the patron's name, matching .patron-badge.
func _patron_badge() -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)

	var portrait := TextureRect.new()
	portrait.texture = load(AssetPaths.PATRONS.get(RunState.patron, AssetPaths.PATRONS["johndee"]))
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(portrait)

	var name := Label.new()
	name.text = _patron_name(RunState.patron)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_override("font", UITheme.font_at("display", 600))
	name.add_theme_font_size_override("font_size", 14)
	name.add_theme_color_override("font_color", UITheme.GOLD)
	box.add_child(name)
	return box


func _patron_name(id: String) -> String:
	for p in Narrative.PATRONS:
		if String(p.get("id", "")) == id:
			return String(p.get("name", id))
	return "John Dee"


func _inventory_slots() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	for i in GameData.INVENTORY_SLOTS:
		var label := Label.new()
		if i < RunState.inventory.size():
			var item: Dictionary = RunState.inventory[i]
			label.text = "%s %s" % [item["icon"], item["name"]]
			label.add_theme_color_override("font_color", UITheme.TEXT)
		else:
			label.text = "[ empty ]"
			label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		label.add_theme_font_override("font", UITheme.font("pixel"))
		label.add_theme_font_size_override("font_size", 15)
		box.add_child(label)
	return box


## Transparent, gold-outlined button in the pixel font, as .map-watch-intro-btn.
func _panel_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", UITheme.font("pixel"))
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(UITheme.GOLD, 0.85))
	button.add_theme_color_override("font_hover_color", UITheme.GOLD)
	button.add_theme_stylebox_override("normal", _ghost_button_box(0.35))
	button.add_theme_stylebox_override("hover", _ghost_button_box(0.8))
	button.add_theme_stylebox_override("pressed", _ghost_button_box(0.8))
	button.pressed.connect(action)
	return button


func _ghost_button_box(border_alpha: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(UITheme.GOLD, border_alpha)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


# ══════════════════════════════════════════════════════════════════════════════
#  High scores
# ══════════════════════════════════════════════════════════════════════════════

## Frames the score list like .map-lb-panel: a gold border, rounded, with a
## tinted header band under the title.
func _style_scores_panel() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = SCORE_BG
	frame.set_border_width_all(1)
	frame.border_color = UITheme.GOLD_DIM
	frame.set_corner_radius_all(6)
	frame.content_margin_bottom = 8
	_scores_frame.add_theme_stylebox_override("panel", frame)

	var band := StyleBoxFlat.new()
	band.bg_color = Color(UITheme.GOLD, 0.1)
	band.border_width_bottom = 1
	band.border_color = UITheme.GOLD_DIM
	band.content_margin_left = 14
	band.content_margin_right = 14
	band.content_margin_top = 8
	band.content_margin_bottom = 8
	_scores_title.add_theme_stylebox_override("normal", band)
	_scores_title.add_theme_font_override("font", UITheme.font_at("display", 700))
	_scores_title.add_theme_font_size_override("font_size", 16)
	_scores_title.add_theme_color_override("font_color", UITheme.GOLD)


func _refresh_scores() -> void:
	for child in _scores.get_children():
		child.queue_free()

	if SaveManager.highscores.is_empty():
		var none := Label.new()
		none.text = "No runs recorded yet."
		none.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		none.add_theme_constant_override("margin_left", 12)
		_scores.add_child(_pad_row(none))
		return

	for i in mini(16, SaveManager.highscores.size()):
		var e: Dictionary = SaveManager.highscores[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var rank := Label.new()
		rank.text = "%d." % (i + 1)
		rank.custom_minimum_size.x = 30
		rank.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		row.add_child(rank)
		var who := Label.new()
		who.text = str(e.get("name", "—"))
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		who.add_theme_color_override("font_color", UITheme.TEXT)
		row.add_child(who)
		var pts := Label.new()
		pts.text = "%d" % int(e.get("score", 0))
		pts.add_theme_color_override("font_color", UITheme.GOLD)
		row.add_child(pts)
		_scores.add_child(_pad_row(row))


## Adds horizontal padding so score rows sit inside the framed panel.
func _pad_row(inner: Control) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.add_child(inner)
	return margin
