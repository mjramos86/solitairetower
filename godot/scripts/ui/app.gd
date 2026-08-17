extends Control

## Root screen router. Replaces the web build's render() dispatch, which rebuilt
## the whole DOM on every state change; here each screen is a scene that is
## instanced when entered and freed when left, and screens listen to RunState
## signals for updates rather than being redrawn wholesale.

const SCREENS := {
	"title": "res://scenes/screens/title_screen.tscn",
	"map": "res://scenes/screens/map_screen.tscn",
	"game": "res://scenes/screens/game_screen.tscn",
	"shop": "res://scenes/screens/shop_screen.tscn",
	"gameover": "res://scenes/screens/end_screen.tscn",
	"victory": "res://scenes/screens/end_screen.tscn",
	"compendium": "res://scenes/screens/compendium_screen.tscn",
	"cardback-select": "res://scenes/screens/cardback_screen.tscn",
	# One scene plays every conversation; it picks its script from the screen name.
	"patron-dialogue": "res://scenes/screens/dialogue_screen.tscn",
	"dee-checkin-dialogue": "res://scenes/screens/dialogue_screen.tscn",
	"dee-dialogue3": "res://scenes/screens/dialogue_screen.tscn",
	"dee-final-dialogue": "res://scenes/screens/dialogue_screen.tscn",
	"victory-dialogue": "res://scenes/screens/dialogue_screen.tscn",
}

var _current: Node
var _current_name := ""

@onready var _host: Control = $ScreenHost
@onready var _toast: Label = $ToastLayer/Toast


func _ready() -> void:
	theme = UITheme.build()
	RunState.screen_changed.connect(_on_screen_changed)
	RunState.toast.connect(show_toast)
	SaveManager.save_corrupted.connect(func(reason): show_toast("Save reset: %s" % reason))
	_toast.modulate.a = 0.0
	_show("title")


func _on_screen_changed(screen: String) -> void:
	_show(screen)


func _show(screen: String) -> void:
	if screen == _current_name and is_instance_valid(_current):
		return
	if not SCREENS.has(screen):
		push_warning("No scene registered for screen '%s'" % screen)
		return

	if is_instance_valid(_current):
		_current.queue_free()
	_current_name = screen

	var packed := load(SCREENS[screen]) as PackedScene
	if packed == null:
		push_error("Could not load screen scene: %s" % SCREENS[screen])
		return
	_current = packed.instantiate()
	_host.add_child(_current)
	if _current is Control:
		(_current as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_apply_music(screen)


func _apply_music(screen: String) -> void:
	match screen:
		"title":
			AudioManager.play_intro_music()
		"map", "shop", "compendium", "cardback-select":
			AudioManager.play_map_music()
		"game":
			AudioManager.play_game_music()
		"patron-dialogue", "dee-checkin-dialogue", "dee-dialogue3", \
		"dee-final-dialogue", "victory-dialogue":
			AudioManager.play_intro_music()
		_:
			pass


func show_toast(message: String) -> void:
	_toast.text = message
	var tween := create_tween()
	tween.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.8)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.4)


func _notification(what: int) -> void:
	# Save on quit so a run is never lost by closing the window.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if RunState.screen != "title":
			SaveManager.store_run(RunState.to_snapshot())
		SaveManager.save_game()
		get_tree().quit()
