extends Control

## Plays every conversation in the game: the intro, John Dee's three interludes,
## and the victory exchange. Ported from renderPatronDialogue and the four
## near-identical render functions the web build had for each one.
##
## A conversation is a run of *beats*, optionally followed by *topics* the player
## picks from. A beat is a Dictionary from Narrative:
##
##   speaker      "scene" (narration), "dee", or "you"
##   text         the line
##   img / imgs   illustration(s)
##   choices      player lines; picking one advances
##   next_label   overrides the continue button's text
##
## Which conversation plays is decided by RunState.screen, so the router does not
## need to know anything about narrative structure.

@onready var _portrait: TextureRect = $Split/Left/Portrait
@onready var _portrait_label: Label = $Split/Left/PortraitLabel
@onready var _scene_image: TextureRect = $Split/Right/SceneImage
@onready var _scene_row: HBoxContainer = $Split/Right/SceneRow
@onready var _text: RichTextLabel = $Split/Right/Text
@onready var _choices: VBoxContainer = $Split/Right/Choices
@onready var _next_button: Button = $Split/Right/Buttons/Next
@onready var _skip_button: Button = $Split/Right/Buttons/Skip

var _beats: Array = []
var _topics: Array = []
var _index := 0

## Which topic list this conversation draws on, for marking topics as seen.
var _seen_key := ""
## Topic currently being read, or {} while in the intro run.
var _active_topic: Dictionary = {}
var _victory_choice := -1


func _ready() -> void:
	_next_button.pressed.connect(_advance)
	_skip_button.pressed.connect(_finish)
	_portrait.texture = load(AssetPaths.PATRONS["johndee"])
	_portrait_label.text = "JOHN DEE"
	_configure()
	_render()


func _configure() -> void:
	match RunState.screen:
		"patron-dialogue":
			_beats = Narrative.DEE_DIALOGUE
		"dee-checkin-dialogue":
			_beats = Narrative.DEE_CHECKIN_INTRO
			_topics = Narrative.DEE_CHECKIN_TOPICS
			_seen_key = "seen_dee_topics"
		"dee-dialogue3":
			_beats = Narrative.DEE_DIALOGUE3_INTRO
			_topics = Narrative.DEE_DIALOGUE3_TOPICS
			_seen_key = "seen_dee3_topics"
		"dee-final-dialogue":
			_beats = Narrative.DEE_FINAL
		"victory-dialogue":
			_beats = []
			for line in Narrative.VICTORY_LINES:
				_beats.append({"speaker": "dee", "text": line})
		_:
			_beats = []


func _render() -> void:
	_clear_choices()
	_scene_image.visible = false
	_scene_row.visible = false

	# Past the beats: either offer topics, or finish.
	if _index >= _beats.size():
		if RunState.screen == "victory-dialogue" and _victory_choice < 0:
			_show_victory_choices()
			return
		if not _topics.is_empty() and _active_topic.is_empty():
			_show_topic_menu()
			return
		_finish()
		return

	var beat: Dictionary = _beats[_index]
	_apply_images(beat)

	var text := String(beat.get("text", ""))
	var speaker := String(beat.get("speaker", "scene"))
	_text.clear()
	if speaker == "you":
		_text.push_color(UITheme.GOLD)
		_text.append_text(text if text != "" else "")
		_text.pop()
	else:
		_text.append_text(text)

	_portrait.visible = speaker == "dee" or beat.has("scene")

	# A beat can offer the player lines instead of a continue button.
	var choices: Array = beat.get("choices", [])
	if not choices.is_empty():
		_next_button.visible = false
		for line in choices:
			_add_choice(String(line), _advance)
	else:
		_next_button.visible = true
		_next_button.text = String(beat.get("next_label", "Continue"))

	_skip_button.visible = _beats.size() > 3


func _apply_images(beat: Dictionary) -> void:
	if beat.has("imgs"):
		# Several stills shown together — the "eyes so dead" arrangement.
		for child in _scene_row.get_children():
			child.queue_free()
		for path in beat["imgs"]:
			var rect := TextureRect.new()
			rect.texture = load(String(path))
			rect.custom_minimum_size = Vector2(140, 140)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_scene_row.add_child(rect)
		_scene_row.visible = true
		return

	if beat.has("img"):
		_scene_image.texture = load(String(beat["img"]))
		_scene_image.visible = true
		# `no_crop` means show the whole image rather than filling the frame.
		_scene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED \
			if beat.get("no_crop", false) else TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if beat.has("flicker_img"):
			_flicker(String(beat["flicker_img"]))


## The screen "flickers" to another image briefly, as the CSS animation did.
func _flicker(path: String) -> void:
	var original := _scene_image.texture
	var other := load(path) as Texture2D
	if other == null:
		return
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_callback(func(): _scene_image.texture = other)
	tween.tween_interval(0.10)
	tween.tween_callback(func():
		if is_instance_valid(_scene_image):
			_scene_image.texture = original)


func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()


func _add_choice(label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(action)
	_choices.add_child(button)


func _show_topic_menu() -> void:
	_scene_image.visible = false
	_next_button.visible = false
	_text.clear()
	_text.append_text("What would you like to ask?")

	var remaining := 0
	for topic in _topics:
		var seen := SaveManager.has_seen(_seen_key, String(topic["id"]))
		if not seen:
			remaining += 1
		var label := String(topic["question"])
		if seen:
			label = "✓ " + label
		_add_choice(label, _open_topic.bind(topic))

	_add_choice("That's all for now.", _finish)


func _open_topic(topic: Dictionary) -> void:
	SaveManager.mark_seen(_seen_key, String(topic["id"]))
	_active_topic = topic
	_beats = topic["beats"]
	_index = 0
	_render()


func _show_victory_choices() -> void:
	_next_button.visible = false
	_text.clear()
	_text.append_text("")
	for i in Narrative.VICTORY_CHOICES.size():
		_add_choice(String(Narrative.VICTORY_CHOICES[i]), _choose_victory.bind(i))


func _choose_victory(index: int) -> void:
	_victory_choice = index
	_beats = [{"speaker": "dee", "text": String(Narrative.VICTORY_RESPONSES[index])}]
	_index = 0
	_render()


func _advance() -> void:
	_index += 1
	# Finishing a topic returns to the topic menu rather than ending the scene.
	if _index >= _beats.size() and not _active_topic.is_empty():
		_active_topic = {}
		_beats = []
		_index = 0
	_render()


func _finish() -> void:
	match RunState.screen:
		"patron-dialogue":
			RunState.set_screen("map")
		"dee-checkin-dialogue", "dee-dialogue3", "dee-final-dialogue":
			SaveManager.mark_dirty()
			RunState.proceed_to_shop()
		"victory-dialogue":
			RunState.set_screen("victory")
		_:
			RunState.set_screen("map")
