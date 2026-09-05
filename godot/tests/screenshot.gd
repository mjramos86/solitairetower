extends Node
# Renders each screen to a PNG under user:// for a visual pass. Not part of the
# test suite; run manually under Xvfb. Stages a plausible run so every screen
# has real content to show.

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame

	# A mid-run state: a few floors cleared, gold, inventory, some unlocks.
	RunState.new_run()
	SaveManager.add_banked_credits(1500)
	SaveManager.highscores = [
		{"name":"Ada","score":9200,"time":410.0,"all_floors":true},
		{"name":"Grace","score":7100,"time":520.0,"all_floors":true},
		{"name":"Alan","score":5400,"time":300.0,"all_floors":false},
	]
	RunState.gold = 320
	RunState.inventory = [
		GameData.item_by_id("sticky-note"),
		GameData.item_by_id("magnifier"),
	]

	await _shoot_game("klondike", "game_klondike")
	await _shoot_game("spider", "game_spider")
	await _shoot_game("freecell", "game_freecell")
	await _shoot_game("tripeaks", "game_tripeaks")
	await _shoot_game("pyramid", "game_pyramid")

	# Shop, after clearing a floor so the breakdown is populated.
	RunState.new_run()
	RunState.start_game("klondike", 0)
	RunState.next_floor()
	await _shoot_screen("shop", "shop")

	# Map.
	await _shoot_screen("map", "map")

	# Compendium, with credits to show the purchase buttons and enough of John
	# Dee's story reached to show the timeline links and Recorded Transmissions.
	SaveManager.add_banked_credits(1500)
	SaveManager.profile["dee_dialogue3_done"] = true
	SaveManager.profile["dee_final_done"] = true
	SaveManager.mark_seen("seen_dee_topics", String(Narrative.DEE_CHECKIN_TOPICS[0]["id"]))
	SaveManager.mark_seen("unlocked_connections", "johndee")
	await _shoot_screen("compendium", "compendium")

	# Dialogue: plain-mode single choice, then a call-mode multi-choice.
	await _shoot_dialogue(12, "dialogue_plain_choice")
	await _shoot_dialogue(16, "dialogue_call_choice")

	# The "Queen's official punster" beat: its text is a single-element array in
	# the data, and must render as plain text (not a bracketed array literal).
	var punster := -1
	for i in Narrative.DEE_DIALOGUE.size():
		var t = Narrative.DEE_DIALOGUE[i].get("text", "")
		if t is Array and t.size() > 0 and String(t[0]).contains("punster"):
			punster = i
			break
	if punster >= 0:
		await _shoot_dialogue(punster, "dialogue_punster")

	# Waste fan with three drawn face-up cards, to check the dividers.
	RunState.new_run()
	RunState.start_game("klondike", 4)
	var gs: Dictionary = RunState.gs
	for k in 3:
		if not (gs["stock"] as Array).is_empty():
			var c: Dictionary = (gs["stock"] as Array).pop_back()
			c["face_up"] = true
			(gs["waste"] as Array).append(c)
	await _capture("waste_fan")

	# Win overlay, to confirm it is centred on the screen.
	RunState.start_game("klondike", 4)
	await _shoot_win_overlay("win_overlay")

	# Title and end screens.
	await _shoot_screen("title", "title")
	RunState.done = [0,1,2,3,4,5,6,7,8,9]
	RunState.score = 4200
	await _shoot_screen("gameover", "gameover")

	print("SCREENSHOTS DONE")
	get_tree().quit()


func _shoot_win_overlay(name: String) -> void:
	if _host and is_instance_valid(_host):
		_host.queue_free()
		await get_tree().process_frame
	_host = load("res://scenes/screens/game_screen.tscn").instantiate()
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	for i in 4:
		await get_tree().process_frame
	_host._show_win_overlay()
	for i in 4:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://ss_%s.png" % name)
	print("shot ss_%s.png" % name)


func _shoot_dialogue(beat_index: int, name: String) -> void:
	RunState.screen = "patron-dialogue"
	if _host and is_instance_valid(_host):
		_host.queue_free()
		await get_tree().process_frame
	_host = load("res://scenes/screens/dialogue_screen.tscn").instantiate()
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	_host._index = beat_index
	_host._render()
	for i in 4:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://ss_%s.png" % name)
	print("shot ss_%s.png" % name)


func _shoot_game(type: String, name: String) -> void:
	RunState.start_game(type, 4)
	await _capture(name)


func _shoot_screen(screen: String, name: String) -> void:
	RunState.screen = screen
	var scene: PackedScene = load(App_scene_for(screen))
	await _render_scene(scene, name)


func App_scene_for(screen: String) -> String:
	return {
		"title": "res://scenes/screens/title_screen.tscn",
		"map": "res://scenes/screens/map_screen.tscn",
		"game": "res://scenes/screens/game_screen.tscn",
		"shop": "res://scenes/screens/shop_screen.tscn",
		"gameover": "res://scenes/screens/end_screen.tscn",
		"compendium": "res://scenes/screens/compendium_screen.tscn",
	}[screen]


var _host: Control


func _capture(name: String) -> void:
	# Game screen: mount it fresh each time.
	await _render_scene(load("res://scenes/screens/game_screen.tscn"), name)


func _render_scene(scene: PackedScene, name: String) -> void:
	if _host and is_instance_valid(_host):
		_host.queue_free()
		await get_tree().process_frame
	_host = scene.instantiate()
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	# Let layout settle and any _ready tweens run a frame.
	for i in 4:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://ss_%s.png" % name)
	print("shot ss_%s.png" % name)
