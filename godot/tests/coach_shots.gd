extends Control

## Renders the patron coach in all five variants, idle and speaking, so the
## framing can be judged before the feature is committed. Every bubble below is
## produced by driving the REAL refusal path on a real board — no line is pushed
## into the widget by hand — so what the PNG shows is what a player would get.
##
## Run under Xvfb:
##   xvfb-run -a godot --path godot res://tests/coach_shots.tscn

var _host: Control


func _ready() -> void:
	# Photographs only: stage whatever makes a good picture, but never let it
	# reach the save file of whoever is running this.
	SaveManager.persist = false
	get_window().size = Vector2i(1600, 900)
	# app.gd puts the Windows-95 theme on the App root, which this harness never
	# instantiates — without it every button here would render unstyled and the
	# captures would not show what a player sees.
	theme = UITheme.build()
	await get_tree().process_frame
	RunState.new_run()
	RunState.gold = 320
	RunState.inventory = [GameData.item_by_id("sticky-note"), GameData.item_by_id("magnifier")]
	# Every variant counts as already met, so the briefing only appears where a
	# shot below asks for it rather than opening itself over the idle captures.
	for type in ["klondike", "spider", "freecell", "tripeaks", "pyramid"]:
		SaveManager.mark_seen("seen_variant_briefings", type)

	# ...except this one, which is the arrival on a variant for the first time.
	await _first_visit("tripeaks", "coach_first_visit")

	await _idle("klondike", "coach_klondike_idle")
	await _klondike_foundation("coach_klondike_bubble")

	await _idle("spider", "coach_spider_idle")
	await _spider_blocked_deal("coach_spider_bubble")

	await _idle("freecell", "coach_freecell_idle")
	await _freecell_too_many("coach_freecell_bubble")

	await _idle("tripeaks", "coach_tripeaks_idle")
	await _tripeaks_covered("coach_tripeaks_bubble")

	await _idle("pyramid", "coach_pyramid_idle")
	await _pyramid_bad_pair("coach_pyramid_bubble")

	# The How to play briefing, which is what the corner button opens.
	for type in ["klondike", "spider", "freecell", "tripeaks", "pyramid"]:
		await _briefing(type, "coach_brief_%s" % type)

	# Muted: the portrait dims, the switch stays held down, and the same refused
	# deal that spoke above now says nothing.
	await _muted("coach_muted")

	# Every other language the picker offers, on the two widest pieces of text:
	# a refusal and a briefing. Translations run longer than the English they
	# came from, so this is where the bubble and the panel are checked for fit.
	for code in ["fr", "es", "pt"]:
		Locale.set_language(code)
		await _spider_blocked_deal("coach_spider_bubble_%s" % code)
		await _briefing("spider", "coach_brief_spider_%s" % code)
		await _briefing("freecell", "coach_brief_freecell_%s" % code)
	Locale.set_language("en")

	print("COACH SHOTS DONE")
	get_tree().quit()


# ── Scenarios ─────────────────────────────────────────────────────────────────

## Spider refuses to deal while any column is empty — the report that started
## this: four empty columns, one group left in the stock, and a dead click.
func _spider_blocked_deal(name: String) -> void:
	RunState.start_game("spider", 8)
	var gs: Dictionary = RunState.gs
	for c in range(6, 10):
		(gs["tableau"][c] as Array).clear()
	await _mount("spider")
	_host._draw_stock()
	await _settle(name)


## A tableau card that is not an Ace, dropped on its empty foundation.
func _klondike_foundation(name: String) -> void:
	RunState.start_game("klondike", 4)
	var gs: Dictionary = RunState.gs
	await _mount("klondike")
	for c in 7:
		var pile: Array = gs["tableau"][c]
		if pile.is_empty():
			continue
		var top: Dictionary = pile[pile.size() - 1]
		if int(top["rank"]) == Cards.RANK_ACE:
			continue
		_host._selection = {"kind": "tableau", "col": c, "index": pile.size() - 1}
		_host._handle_target({"kind": "foundation", "col": int(top["suit"])})
		break
	await _settle(name)


## A FreeCell column grabbed from the bottom: more cards than the free cells and
## empty columns can carry, so the bubble quotes the live capacity.
func _freecell_too_many(name: String) -> void:
	RunState.start_game("freecell", 4)
	var gs: Dictionary = RunState.gs
	await _mount("freecell")
	var cap := Rules.freecell_max_movable(gs)
	for c in (gs["tableau"] as Array).size():
		var pile: Array = gs["tableau"][c]
		if pile.size() > cap:
			_host._click_slot({"kind": "tableau", "col": c, "index": 0})
			break
	await _settle(name)


## A TriPeaks peak, still pinned by the two cards resting on it.
func _tripeaks_covered(name: String) -> void:
	RunState.start_game("tripeaks", 4)
	await _mount("tripeaks")
	_host._tripeaks_play({"kind": "pyramid", "index": 0})
	await _settle(name)


## Two free Pyramid cards that do not add to thirteen.
func _pyramid_bad_pair(name: String) -> void:
	RunState.start_game("pyramid", 4)
	var gs: Dictionary = RunState.gs
	await _mount("pyramid")
	var row: Array = []            # the uncovered bottom row
	for i in range(21, 28):
		var card = gs["pyramid"][i]
		if card != null and int(card["rank"]) != Cards.RANK_KING and not _pairs_waste(gs, card):
			row.append(i)
	for a in row:
		for b in row:
			if a == b:
				continue
			if int(gs["pyramid"][a]["rank"]) + int(gs["pyramid"][b]["rank"]) == 13:
				continue
			_host._pyramid_click({"kind": "pyramid", "index": a})
			_host._pyramid_click({"kind": "pyramid", "index": b})
			await _settle(name)
			return
	await _settle(name)


## Whether a card would be cleared on the spot by one of the two draw spots.
func _pairs_waste(gs: Dictionary, card: Dictionary) -> bool:
	var w: Array = gs["waste"]
	for wi in [w.size() - 1, w.size() - 2]:
		if wi >= 0 and int(card["rank"]) + int(w[wi]["rank"]) == 13:
			return true
	return false


## Arriving on a variant this profile has never played: the briefing opens by
## itself, with nothing clicked.
func _first_visit(type: String, name: String) -> void:
	SaveManager.profile["seen_variant_briefings"] = []
	RunState.start_game(type, 4)
	await _mount(type)
	await _settle(name)
	for t in ["klondike", "spider", "freecell", "tripeaks", "pyramid"]:
		SaveManager.mark_seen("seen_variant_briefings", t)


## The corner's How to play button, pressed.
func _briefing(type: String, name: String) -> void:
	RunState.start_game(type, 4)
	await _mount(type)
	_host._patron_coach._on_help_pressed()
	await _settle(name)


## The mute switch on, then a refusal that would otherwise have spoken.
func _muted(name: String) -> void:
	RunState.start_game("spider", 8)
	var gs: Dictionary = RunState.gs
	for c in range(6, 10):
		(gs["tableau"][c] as Array).clear()
	await _mount("spider")
	_host._patron_coach._mute_button.button_pressed = true
	_host._draw_stock()
	await _settle(name)
	# Leave the profile as it was found, so later shots are not silenced too.
	_host._patron_coach._mute_button.button_pressed = false


# ── Plumbing ──────────────────────────────────────────────────────────────────

func _idle(type: String, name: String) -> void:
	RunState.start_game(type, 4)
	await _mount(type)
	await _settle(name)


func _mount(_type: String) -> void:
	if _host and is_instance_valid(_host):
		_host.queue_free()
		await get_tree().process_frame
	_host = load("res://scenes/screens/game_screen.tscn").instantiate()
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	for i in 6:
		await get_tree().process_frame


## Waits out the bubble's pop-in (a real-time tween) before capturing.
func _settle(name: String) -> void:
	await get_tree().create_timer(0.45).timeout
	for i in 2:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://ss_%s.png" % name)
	print("shot ss_%s.png" % name)
