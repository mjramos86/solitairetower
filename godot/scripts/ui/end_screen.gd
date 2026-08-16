extends Control

## Shared game-over / victory screen. Records the run into the local high score
## table, which replaces the Firestore leaderboard the web build submitted to.

@onready var _title: Label = $Center/Panel/Title
@onready var _summary: Label = $Center/Panel/Summary
@onready var _name_row: HBoxContainer = $Center/Panel/NameRow
@onready var _name_field: LineEdit = $Center/Panel/NameRow/NameField
@onready var _submit_button: Button = $Center/Panel/NameRow/Submit
@onready var _table: VBoxContainer = $Center/Panel/Table
@onready var _again_button: Button = $Center/Panel/Buttons/Again
@onready var _title_button: Button = $Center/Panel/Buttons/ToTitle

var _won := false
var _recorded := false


func _ready() -> void:
	_won = RunState.screen != "gameover"

	_title.add_theme_font_override("font", UITheme.font_at("title", 900))
	_title.add_theme_font_size_override("font_size", 48)
	_title.add_theme_color_override("font_color", UITheme.GOLD if _won else UITheme.DANGER)
	_title.text = "You Escaped the Tower" if _won else "The Tower Keeps You"

	var floors_cleared := RunState.done.size()
	_summary.text = "★ %d pts    ⏳ %d credits    %d/%d floors    %s" % [
		RunState.score, RunState.gold, floors_cleared,
		GameData.TOTAL_FLOORS, RunState.format_elapsed()]

	# Prefill with the last name used, so repeat runs need no retyping.
	_name_field.text = String(SaveManager.profile.get("last_name", ""))
	_name_field.placeholder_text = "Your name"
	_submit_button.pressed.connect(_on_submit)
	_again_button.pressed.connect(_on_again)
	_title_button.pressed.connect(_on_title)

	_refresh_table()


func _on_submit() -> void:
	if _recorded:
		return
	_recorded = true
	SaveManager.profile["last_name"] = _name_field.text
	var placement := SaveManager.record_score(
		_name_field.text, RunState.score, RunState.get_elapsed_seconds(),
		RunState.done.size() >= GameData.TOTAL_FLOORS)
	_name_row.visible = false
	if placement >= 0:
		RunState.toast.emit("Recorded at #%d" % (placement + 1))
	_refresh_table()


func _refresh_table() -> void:
	for child in _table.get_children():
		child.queue_free()

	var heading := Label.new()
	heading.text = "Local High Scores"
	heading.add_theme_font_override("font", UITheme.font_at("display", 700))
	heading.add_theme_color_override("font_color", UITheme.GOLD)
	_table.add_child(heading)

	if SaveManager.highscores.is_empty():
		var none := Label.new()
		none.text = "No runs recorded yet."
		none.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_table.add_child(none)
		return

	for i in mini(10, SaveManager.highscores.size()):
		var e: Dictionary = SaveManager.highscores[i]
		var row := HBoxContainer.new()
		var rank := Label.new()
		rank.text = "%2d." % (i + 1)
		rank.custom_minimum_size.x = 36
		row.add_child(rank)
		var who := Label.new()
		who.text = String(e["name"])
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(who)
		var pts := Label.new()
		pts.text = "%d pts" % int(e["score"])
		pts.add_theme_color_override("font_color", UITheme.GOLD)
		row.add_child(pts)
		_table.add_child(row)


func _on_again() -> void:
	RunState.new_run()
	RunState.set_screen("map")


func _on_title() -> void:
	RunState.new_run()
	RunState.set_screen("title")
