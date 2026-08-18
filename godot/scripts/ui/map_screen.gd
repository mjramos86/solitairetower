extends Control

## Tower map. The centre is the tower with its floor nodes (tower_map.gd); this
## script fills the left info panel and the right high-score list, matching the
## layout of renderMap in index.html: a descent from floor 10 down to floor 1.

@onready var _title: Label = $Head/Title
@onready var _sub: Label = $Head/Sub
@onready var _side: VBoxContainer = $Body/SidePanel/Side
@onready var _tower = $Body/Tower
@onready var _scores_title: Label = $Body/ScoresPad/ScoresPanel/ScoresTitle
@onready var _scores: VBoxContainer = $Body/ScoresPad/ScoresPanel/ScoresScroll/Scores


func _ready() -> void:
	_title.add_theme_font_override("font", UITheme.font_at("title", 900))
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", UITheme.GOLD)
	_sub.add_theme_font_override("font", UITheme.font_at("display", 500))
	_sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_scores_title.add_theme_font_override("font", UITheme.font_at("display", 700))
	_scores_title.add_theme_color_override("font_color", UITheme.GOLD)

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
		hearts += "♥"
	if hearts == "":
		hearts = "—"
	_add_section("Lives", _text_value(hearts, UITheme.DANGER, 22))

	_add_section("Time Credits", _text_value("⏳ %d" % RunState.gold, UITheme.GOLD))
	_add_section("Time Energy",
		_text_value("⚡ %d" % int(SaveManager.profile.get("banked_credits", 0)), UITheme.GOLD))

	_add_section("Inventory", _inventory_slots())

	_add_section("Lore", _panel_button("📖 Compendium",
		func(): RunState.set_screen("compendium")))
	_add_section("Customize", _panel_button("🂠 Cardback", func():
		RunState.cardback_return = "map"
		RunState.set_screen("cardback-select")))
	_side.add_child(_panel_button("▶ Watch Intro", func():
		RunState.intro_replay = true
		RunState.set_screen("patron-dialogue")))


func _add_section(label_text: String, content: Control) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	box.add_child(label)
	box.add_child(content)
	_side.add_child(box)


func _text_value(text: String, color: Color, font_size := 18) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _patron_badge() -> Control:
	var portrait := TextureRect.new()
	portrait.texture = load(AssetPaths.PATRONS["johndee"])
	portrait.custom_minimum_size = Vector2(72, 72)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return portrait


func _inventory_slots() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	for i in GameData.INVENTORY_SLOTS:
		var label := Label.new()
		if i < RunState.inventory.size():
			var item: Dictionary = RunState.inventory[i]
			label.text = "%s %s" % [item["icon"], item["name"]]
		else:
			label.text = "[ empty ]"
			label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		box.add_child(label)
	return box


func _panel_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	return button


# ══════════════════════════════════════════════════════════════════════════════
#  High scores
# ══════════════════════════════════════════════════════════════════════════════

func _refresh_scores() -> void:
	for child in _scores.get_children():
		child.queue_free()

	if SaveManager.highscores.is_empty():
		var none := Label.new()
		none.text = "No runs recorded yet."
		none.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_scores.add_child(none)
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
		row.add_child(who)
		var pts := Label.new()
		pts.text = "%d" % int(e.get("score", 0))
		pts.add_theme_color_override("font_color", UITheme.GOLD)
		row.add_child(pts)
		_scores.add_child(row)
