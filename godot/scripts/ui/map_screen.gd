extends Control

## Tower map. Ten floors, each offering a choice of two solitaire variants;
## the player descends from floor 10 to floor 1. Ported from renderMap and
## buildTowerPath.

@onready var _tower_host: Control = $Body/TowerHost
@onready var _floor_list: VBoxContainer = $Body/Side/Scroll/Floors
@onready var _floors_title: Label = $Body/Side/FloorsTitle
@onready var _scores_title: Label = $Body/Side/ScoresTitle
@onready var _scores: VBoxContainer = $Body/Side/Scores
@onready var _header: Label = $Header/Status
@onready var _credits: Label = $Header/Credits
@onready var _compendium_button: Button = $Header/Compendium
@onready var _intro_button: Button = $Header/WatchIntro


func _ready() -> void:
	# load() returns an untyped Resource, so cast to PackedScene before
	# instantiating — otherwise the result has no static type to infer from.
	var tower := (load(AssetPaths.TOWER_SCENE) as PackedScene).instantiate() as Control
	_tower_host.add_child(tower)
	tower.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for label in [_floors_title, _scores_title]:
		label.add_theme_font_override("font", UITheme.font_at("display", 700))
		label.add_theme_color_override("font_color", UITheme.GOLD)
	_header.add_theme_font_override("font", UITheme.font_at("display", 600))
	_credits.add_theme_color_override("font_color", UITheme.GOLD)

	_compendium_button.pressed.connect(func(): RunState.set_screen("compendium"))
	_intro_button.pressed.connect(func():
		RunState.intro_replay = true
		RunState.set_screen("patron-dialogue"))

	RunState.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var hearts := ""
	for i in RunState.lives:
		hearts += "♥"
	_header.text = "%s   ★ %d pts   ⏳ %d" % [hearts, RunState.score, RunState.gold]
	_credits.text = "⚡ %d banked" % int(SaveManager.profile.get("banked_credits", 0))

	for child in _floor_list.get_children():
		child.queue_free()

	# Listed top-down: floor 10 (index 0) first, matching the descent.
	for i in GameData.TOTAL_FLOORS:
		_floor_list.add_child(_build_floor_row(i))

	_refresh_scores()


## Local high scores fill the space the web build's online leaderboard occupied.
func _refresh_scores() -> void:
	for child in _scores.get_children():
		child.queue_free()

	if SaveManager.highscores.is_empty():
		var none := Label.new()
		none.text = "No runs recorded yet."
		none.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_scores.add_child(none)
		return

	for i in mini(8, SaveManager.highscores.size()):
		var e: Dictionary = SaveManager.highscores[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var rank := Label.new()
		rank.text = "%d." % (i + 1)
		rank.custom_minimum_size.x = 32
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


func _build_floor_row(index: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "Floor %d" % (GameData.TOTAL_FLOORS - index)
	label.custom_minimum_size.x = 90
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_color_override("font_color", UITheme.GOLD)
	row.add_child(label)

	var cleared := RunState.done.has(index)
	var current := index == RunState.floor_index

	if cleared:
		var done := Label.new()
		done.text = "✓ cleared"
		done.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		row.add_child(done)
		return row

	if not current:
		var locked := Label.new()
		locked.text = "—"
		locked.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		row.add_child(locked)
		return row

	# Only the current floor is playable, and only its two offered variants.
	var choice: Dictionary = RunState.choices[index] if index < RunState.choices.size() else {}
	var options := []
	if choice.has("left"):
		options.append(choice["left"])
	if choice.has("right") and choice["right"] != choice.get("left"):
		options.append(choice["right"])

	for type in options:
		var button := Button.new()
		button.text = "%s %s" % [GameData.ICONS.get(type, ""), GameData.NAMES.get(type, type)]
		button.pressed.connect(func(): RunState.start_game(type, index))
		row.add_child(button)

	return row
