extends Control

## Title screen. Offers Continue when a local save holds an unfinished run —
## the web build gated this behind a cloud account; here it is simply the save
## file, so it works offline and for every player.

@onready var _continue_button: Button = $Center/Panel/Buttons/Continue
@onready var _new_button: Button = $Center/Panel/Buttons/NewRun
@onready var _scores_button: Button = $Center/Panel/Buttons/Scores
@onready var _keyart: TextureRect = $Keyart
@onready var _title: Label = $Center/Panel/Title
@onready var _subtitle: Label = $Center/Panel/Subtitle


func _ready() -> void:
	_keyart.texture = load(AssetPaths.UI["title_keyart"])

	_title.add_theme_font_override("font", UITheme.font_at("title", 900))
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", UITheme.GOLD)
	_title.text = "The Solitaire Tower of Doom"

	_subtitle.add_theme_font_override("font", UITheme.font_at("display", 600))
	_subtitle.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_subtitle.text = "A roguelike solitaire descent through 10 floors of card chaos."

	_continue_button.visible = SaveManager.has_run()
	_continue_button.pressed.connect(_on_continue)
	_new_button.pressed.connect(_on_new_run)
	_scores_button.pressed.connect(_on_scores)


func _on_continue() -> void:
	RunState.from_snapshot(SaveManager.run)
	# Resume on the map rather than mid-hand: the board is restored, but the
	# undo history is not, and dropping the player straight into a game they
	# cannot undo out of is worse than a beat on the map.
	RunState.set_screen("map")


func _on_new_run() -> void:
	RunState.new_run()
	RunState.set_screen("map")


func _on_scores() -> void:
	var lines := PackedStringArray()
	if SaveManager.highscores.is_empty():
		lines.append("No runs recorded yet.")
	else:
		for i in SaveManager.highscores.size():
			var e: Dictionary = SaveManager.highscores[i]
			lines.append("%2d. %-16s %6d pts  %s" % [
				i + 1, e["name"], int(e["score"]), _format_time(float(e["time"]))])
	var dialog := AcceptDialog.new()
	dialog.title = "Local High Scores"
	dialog.dialog_text = "\n".join(lines)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
