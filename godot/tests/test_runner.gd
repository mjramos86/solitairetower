extends Node

## Headless test suite for the ported game logic.
##
## Run with:
##   godot --headless --path godot res://tests/test_runner.tscn
##
## Exits with code 0 when everything passes, 1 otherwise, so it can gate CI.
## Covers the rules of all five variants, the scoring model, and a save
## round-trip — the parts that have to be right before any UI is worth building.

var _passed := 0
var _failed := 0
var _current := ""


func _ready() -> void:
	print("\n══ Solitaire Tower of Doom — logic tests ══\n")

	test_deck()
	test_klondike()
	test_spider()
	test_tripeaks()
	test_pyramid()
	test_freecell()
	test_scoring()
	test_variant_scoring()
	await test_game_hud()
	await test_win_overlay()
	await test_board_centring_stable()
	test_tp_streak_undo()
	test_shop_and_choices()
	test_save_round_trip()
	test_full_run()
	test_hints()
	test_item_effects()
	test_narrative()
	test_every_scene_loads()
	test_unlockables()

	print("\n──────────────────────────────────────────")
	print("  passed: %d   failed: %d" % [_passed, _failed])
	print("──────────────────────────────────────────\n")
	get_tree().quit(1 if _failed > 0 else 0)


func suite(suite_name: String) -> void:
	_current = suite_name
	print("• %s" % suite_name)


func check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("    FAIL: %s" % description)


func check_eq(actual, expected, description: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		print("    FAIL: %s (got %s, expected %s)" % [description, actual, expected])


# ══════════════════════════════════════════════════════════════════════════════

func test_deck() -> void:
	suite("deck and shuffle")
	var deck := Cards.make_deck()
	check_eq(deck.size(), 52, "deck has 52 cards")

	var seen := {}
	for c in deck:
		seen[Cards.key(c)] = true
	check_eq(seen.size(), 52, "all 52 cards are distinct")

	var rng := Cards.new_rng(12345)
	var a := Cards.shuffle(deck, rng)
	check_eq(a.size(), 52, "shuffle preserves count")
	var keys := {}
	for c in a:
		keys[Cards.key(c)] = true
	check_eq(keys.size(), 52, "shuffle preserves the set")

	# Same seed must reproduce the same order, or saved runs could not replay.
	var b := Cards.shuffle(deck, Cards.new_rng(12345))
	var same := true
	for i in 52:
		if Cards.key(a[i]) != Cards.key(b[i]):
			same = false
	check(same, "same seed produces the same shuffle")

	check(Cards.is_red(Cards.Suit.HEARTS), "hearts are red")
	check(Cards.is_red(Cards.Suit.DIAMONDS), "diamonds are red")
	check(not Cards.is_red(Cards.Suit.SPADES), "spades are black")
	check(not Cards.is_red(Cards.Suit.CLUBS), "clubs are black")


func test_klondike() -> void:
	suite("klondike")
	var s := Rules.init_klondike(5, Cards.new_rng(7))
	var tableau: Array = s["tableau"]
	check_eq(tableau.size(), 7, "7 tableau columns")
	var total := 0
	for c in 7:
		check_eq(tableau[c].size(), c + 1, "column %d holds %d cards" % [c, c + 1])
		check(tableau[c][tableau[c].size() - 1]["face_up"], "column %d top is face up" % c)
		total += tableau[c].size()
	check_eq(total + s["stock"].size(), 52, "all 52 cards dealt")
	check_eq(s["draw_count"], 3, "medium floor draws 3")

	# Foundation: only an ace opens an empty pile, then strictly ascending.
	var founds := [[], [], [], []]
	check(Rules.klondike_can_foundation(Cards.make_card(0, 1), founds), "ace opens foundation")
	check(not Rules.klondike_can_foundation(Cards.make_card(0, 2), founds), "two cannot open foundation")
	founds[0].append(Cards.make_card(0, 1))
	check(Rules.klondike_can_foundation(Cards.make_card(0, 2), founds), "two follows ace")
	check(not Rules.klondike_can_foundation(Cards.make_card(0, 3), founds), "three cannot follow ace")

	# Tableau: descending, alternating colour; only a king opens an empty column.
	var empty: Array = []
	check(Rules.klondike_can_tableau([Cards.make_card(0, 13)], empty), "king opens empty column")
	check(not Rules.klondike_can_tableau([Cards.make_card(0, 12)], empty), "queen cannot open empty column")
	var black_seven := [Cards.make_card(Cards.Suit.SPADES, 7, true)]
	check(Rules.klondike_can_tableau([Cards.make_card(Cards.Suit.HEARTS, 6)], black_seven),
		"red six onto black seven")
	check(not Rules.klondike_can_tableau([Cards.make_card(Cards.Suit.CLUBS, 6)], black_seven),
		"black six rejected on black seven")
	check(not Rules.klondike_can_tableau([Cards.make_card(Cards.Suit.HEARTS, 5)], black_seven),
		"wrong rank rejected")

	# Draw moves draw_count cards and flips them face up.
	var before: int = s["stock"].size()
	var drawn := Rules.klondike_draw(s)
	check_eq(drawn["waste"].size(), 3, "draw of 3 fills waste")
	check_eq(drawn["stock"].size(), before - 3, "stock shrinks by 3")
	check(drawn["waste"][0]["face_up"], "drawn cards are face up")
	check_eq(s["waste"].size(), 0, "draw does not mutate the original state")

	# Win detection.
	var won := {"type": "klondike", "foundations": [[], [], [], []]}
	for suit in 4:
		for r in range(1, 14):
			won["foundations"][suit].append(Cards.make_card(suit, r))
	check(Rules.klondike_won(won), "full foundations win")
	won["foundations"][3].pop_back()
	check(not Rules.klondike_won(won), "incomplete foundations do not win")

	# Easy floors must deal a solvable board.
	var easy := Rules.init_klondike(0, Cards.new_rng(99))
	check(Rules.klondike_greedy_solvable(easy), "easy deal is greedy-solvable")
	check_eq(easy["draw_count"], 1, "easy floor draws 1")


func test_spider() -> void:
	suite("spider")
	var s := Rules.init_spider(0, Cards.new_rng(3))
	check_eq(s["tableau"].size(), 10, "10 columns")
	check_eq(s["suits"], 1, "easy floor is one suit")
	var dealt := 0
	for col in s["tableau"]:
		dealt += col.size()
	check_eq(dealt, 54, "54 cards dealt to tableau")
	check_eq(s["stock_groups"].size(), 5, "5 stock rows remain")

	var hard := Rules.init_spider(9, Cards.new_rng(3))
	check_eq(hard["suits"], 4, "hard floor is four suits")

	# A descending same-suit run counts; a colour break stops it.
	var run := [
		Cards.make_card(0, 9, true), Cards.make_card(0, 8, true), Cards.make_card(0, 7, true),
	]
	check_eq(Rules.spider_sequence_length(run), 3, "three-card run measured")
	run[1] = Cards.make_card(1, 8, true)
	check_eq(Rules.spider_sequence_length(run), 1, "mixed suits break the run")

	# Drops ignore suit; only rank matters.
	check(Rules.spider_can_drop([Cards.make_card(1, 6)], [Cards.make_card(0, 7, true)]),
		"any suit drops on the next rank up")
	check(not Rules.spider_can_drop([Cards.make_card(1, 6)], [Cards.make_card(0, 9, true)]),
		"wrong rank rejected")
	check(Rules.spider_can_drop([Cards.make_card(1, 6)], []), "any card drops on empty column")

	# A complete K..A of one suit is detected; a mixed one is not.
	var complete := []
	for r in range(13, 0, -1):
		complete.append(Cards.make_card(2, r, true))
	check_eq(Rules.spider_check_complete(complete), 2, "K..A of one suit completes")
	complete[5] = Cards.make_card(3, complete[5]["rank"], true)
	check_eq(Rules.spider_check_complete(complete), -1, "mixed suit does not complete")

	check(Rules.spider_won({"foundations": [0, 0, 0, 0, 0, 0, 0, 0]}), "8 foundations win")
	check(not Rules.spider_won({"foundations": [0]}), "1 foundation does not win")


func test_tripeaks() -> void:
	suite("tripeaks")
	var s := Rules.init_tripeaks(0, Cards.new_rng(11))
	check_eq(s["pyramid"].size(), 28, "28 pyramid slots")
	check_eq(s["waste"].size(), 1, "one card starts in waste")
	check_eq(s["stock"].size(), 23, "23 cards left in stock")

	# The bottom row is unblocked at deal; the peaks are not.
	var free_at_start := 0
	for i in 28:
		if Rules.tripeaks_free(s["pyramid"], i):
			free_at_start += 1
	check_eq(free_at_start, 10, "bottom row of 10 is free at deal")
	check(not Rules.tripeaks_free(s["pyramid"], 0), "peak is blocked at deal")

	# Rank adjacency, including the A-K wrap in both directions.
	var seven := Cards.make_card(0, 7)
	check(Rules.tripeaks_can_play(Cards.make_card(1, 8), seven), "8 plays on 7")
	check(Rules.tripeaks_can_play(Cards.make_card(1, 6), seven), "6 plays on 7")
	check(not Rules.tripeaks_can_play(Cards.make_card(1, 9), seven), "9 does not play on 7")
	check(Rules.tripeaks_can_play(Cards.make_card(1, 1), Cards.make_card(0, 13)), "ace wraps onto king")
	check(Rules.tripeaks_can_play(Cards.make_card(1, 13), Cards.make_card(0, 1)), "king wraps onto ace")

	# Removing both blockers frees the slot above.
	var p: Array = s["pyramid"].duplicate(true)
	p[18] = null
	p[19] = null
	check(Rules.tripeaks_free(p, 9), "clearing both blockers frees the slot")

	var cleared := {"pyramid": []}
	for i in 28:
		cleared["pyramid"].append(null)
	check(Rules.tripeaks_won(cleared), "empty pyramid wins")


func test_pyramid() -> void:
	suite("pyramid")
	var s := Rules.init_pyramid(0, Cards.new_rng(5))
	check_eq(s["pyramid"].size(), 28, "28 pyramid slots")
	check_eq(Rules.pyramid_index(0, 0), 0, "row 0 starts at 0")
	check_eq(Rules.pyramid_index(6, 0), 21, "row 6 starts at 21")
	check_eq(Rules.pyramid_index(6, 6), 27, "last slot is 27")

	# Pairs must total 13; a king clears alone.
	check(Rules.pyramid_pairs(Cards.make_card(0, 6), Cards.make_card(1, 7)), "6 + 7 = 13")
	check(Rules.pyramid_pairs(Cards.make_card(0, 1), Cards.make_card(1, 12)), "A + Q = 13")
	check(not Rules.pyramid_pairs(Cards.make_card(0, 5), Cards.make_card(1, 5)), "5 + 5 rejected")
	check(Rules.pyramid_pairs(Cards.make_card(0, 13), null), "king clears alone")
	check(not Rules.pyramid_pairs(Cards.make_card(0, 12), null), "queen does not clear alone")

	# Bottom row is never blocked; upper rows are blocked by the row below.
	check(not Rules.pyramid_blocked(s["pyramid"], 6, 0), "bottom row is free")
	check(Rules.pyramid_blocked(s["pyramid"], 5, 0), "row 5 blocked at deal")

	# Recycling is capped by difficulty.
	var hard := Rules.init_pyramid(9, Cards.new_rng(5))
	check_eq(hard["max_cycles"], 1, "hard floor allows one recycle")
	var drawn := Rules.pyramid_draw(hard)
	check_eq(drawn["waste"].size(), hard["waste"].size() + 1, "draw adds to waste")


func test_freecell() -> void:
	suite("freecell")
	var s := Rules.init_freecell(0, false, Cards.new_rng(2))
	check_eq(s["tableau"].size(), 8, "8 columns")
	check_eq(s["freecells"].size(), 4, "4 free cells by default")
	var dealt := 0
	for col in s["tableau"]:
		dealt += col.size()
		for c in col:
			check(c["face_up"], "freecell cards are all face up")
	check_eq(dealt, 52, "all 52 cards on the tableau")

	var extra := Rules.init_freecell(0, true, Cards.new_rng(2))
	check_eq(extra["freecells"].size(), 5, "skeleton key adds a fifth cell")

	# Descending, alternating colour; anything opens an empty column.
	var red_eight := [Cards.make_card(Cards.Suit.HEARTS, 8, true)]
	check(Rules.freecell_can_tableau(Cards.make_card(Cards.Suit.SPADES, 7), red_eight),
		"black seven onto red eight")
	check(not Rules.freecell_can_tableau(Cards.make_card(Cards.Suit.DIAMONDS, 7), red_eight),
		"red seven rejected on red eight")
	check(Rules.freecell_can_tableau(Cards.make_card(0, 5), []), "any card opens an empty column")

	# Supermove capacity = (free cells + 1) × 2^(empty columns).
	check_eq(Rules.freecell_max_movable(s), 5, "4 cells, 0 empty columns moves 5")
	var roomy := Cards.clone_state(s)
	roomy["tableau"][0] = []
	check_eq(Rules.freecell_max_movable(roomy), 10, "one empty column doubles capacity")
	# Occupying a cell drops capacity to (3+1) x 2^1 = 8.
	roomy["freecells"][0] = Cards.make_card(0, 1)
	check_eq(Rules.freecell_max_movable(roomy), 8, "occupied cell reduces capacity")


func test_scoring() -> void:
	suite("scoring")
	RunState.new_run()
	RunState.gs = {"type": "klondike", "card_points": {}}

	var card := Cards.make_card(Cards.Suit.SPADES, 5)

	# 20 points is the per-card ceiling however it is accumulated.
	check_eq(RunState.award_card_points(card, 5), 5, "waste-to-tableau awards 5")
	check_eq(RunState.score, 5, "score reflects the award")
	check_eq(RunState.award_card_points(card, 20), 15, "foundation awards only the remainder")
	check_eq(RunState.score, 20, "card total caps at 20")
	check_eq(RunState.award_card_points(card, 20), 0, "a maxed card earns nothing more")

	# A different card has its own budget.
	var other := Cards.make_card(Cards.Suit.HEARTS, 9)
	check_eq(RunState.award_card_points(other, 20), 20, "second card gets a full 20")
	check_eq(RunState.total_card_points(), 40, "ledger totals both cards")

	# Score floors at zero and the ledger records every event.
	RunState.add_score(-1000, "penalty")
	check_eq(RunState.score, 0, "score never goes below zero")
	check(RunState.score_log.size() >= 4, "score log records events")

	# Floor-clear bonus scales with depth: 100 × (10 - floor).
	RunState.score = 0
	RunState.floor_index = 0
	RunState.gtype = "klondike"
	RunState.done = []
	RunState.next_floor()
	check_eq(RunState.score, 1000, "clearing floor 0 awards 1000")

	check_eq(GameData.MAX_CARD_POINTS, 1040, "perfect card score is 52 x 20")


## Each variant scores a move the way the web build did — not with the uniform
## 20-point-per-card model, which only Klondike uses. Drives the real game-screen
## scoring methods so a regression in _score_move / _tripeaks_play / _pyramid_click
## is caught, not just the constants.
func test_variant_scoring() -> void:
	suite("per-variant scoring")

	var packed := load("res://scenes/screens/game_screen.tscn") as PackedScene
	var screen := packed.instantiate()
	add_child(screen)  # resolves @onready nodes; the zero-size board no-ops _rebuild

	# ── Klondike: waste→tableau is 5, →foundation fills to the 20 cap. ──
	RunState.new_run()
	RunState.gtype = "klondike"
	RunState.gs = {"type": "klondike", "card_points": {}}
	RunState.score = 0
	var kc := Cards.make_card(Cards.Suit.SPADES, 5)
	screen._score_move(RunState.gs, {"kind": "waste"}, {"kind": "tableau", "col": 0}, [kc])
	check_eq(RunState.score, 5, "klondike waste→tableau scores 5")
	screen._score_move(RunState.gs, {"kind": "tableau", "col": 0}, {"kind": "foundation", "col": 0}, [kc])
	check_eq(RunState.score, 20, "klondike →foundation tops the same card up to 20")

	# Tableau→tableau earns nothing.
	RunState.score = 0
	RunState.gs = {"type": "klondike", "card_points": {}}
	screen._score_move(RunState.gs, {"kind": "tableau", "col": 1}, {"kind": "tableau", "col": 2},
		[Cards.make_card(Cards.Suit.HEARTS, 9)])
	check_eq(RunState.score, 0, "klondike tableau→tableau scores nothing")

	# ── FreeCell: a flat 5 to a foundation, never touching the card ledger. ──
	RunState.gtype = "freecell"
	RunState.gs = {"type": "freecell", "card_points": {}}
	RunState.score = 0
	screen._score_move(RunState.gs, {"kind": "tableau", "col": 0}, {"kind": "foundation", "col": 0},
		[Cards.make_card(Cards.Suit.CLUBS, 1)])
	check_eq(RunState.score, 5, "freecell →foundation scores a flat 5")
	check_eq(RunState.total_card_points(), 0, "freecell does not use the 20-point ledger")

	# ── Spider: only the +100 suit bonus; a plain move scores nothing. ──
	RunState.gtype = "spider"
	RunState.gs = {"type": "spider", "card_points": {}}
	RunState.score = 0
	screen._score_move(RunState.gs, {"kind": "tableau", "col": 0}, {"kind": "tableau", "col": 1},
		[Cards.make_card(Cards.Suit.SPADES, 10)])
	check_eq(RunState.score, 0, "spider tableau move scores nothing on its own")

	# ── TriPeaks: streak length per card, +15 for a peak; a failed play resets. ──
	RunState.gtype = "tripeaks"
	RunState.score = 0
	RunState.tp_streak = 0
	var pyr := []
	for i in 28:
		pyr.append(null)
	pyr[0] = Cards.make_card(Cards.Suit.HEARTS, 6)   # a peak (index < 3)
	pyr[27] = Cards.make_card(Cards.Suit.SPADES, 2)  # keeps the board unwon
	RunState.gs = {"type": "tripeaks", "pyramid": pyr,
		"waste": [Cards.make_card(Cards.Suit.CLUBS, 5)], "card_points": {}}
	screen._tripeaks_play({"kind": "pyramid", "index": 0})
	check_eq(RunState.tp_streak, 1, "first tripeaks play sets streak to 1")
	check_eq(RunState.score, 16, "peak play scores streak(1) + 15 bonus")

	# A failed play (an unplayable free card) resets the streak.
	screen._tripeaks_play({"kind": "pyramid", "index": 27})  # rank 2 vs waste top rank 6
	check_eq(RunState.tp_streak, 0, "a failed tripeaks play resets the streak")

	# ── Pyramid: any pair summing to 13 is +10; a King clears alone for +5. ──
	RunState.gtype = "pyramid"
	RunState.score = 0
	screen._selection = {}
	var ppyr := []
	for i in 28:
		ppyr.append(Cards.make_card(Cards.Suit.SPADES, 4))  # filler, never clicked
	ppyr[21] = Cards.make_card(Cards.Suit.HEARTS, 6)
	ppyr[22] = Cards.make_card(Cards.Suit.CLUBS, 7)
	ppyr[23] = Cards.make_card(Cards.Suit.DIAMONDS, 13)
	RunState.gs = {"type": "pyramid", "pyramid": ppyr, "waste": [], "card_points": {}}
	screen._pyramid_click({"kind": "pyramid", "index": 21})  # selects the 6
	screen._pyramid_click({"kind": "pyramid", "index": 22})  # 6 + 7 = 13
	check_eq(RunState.score, 10, "pyramid pair scores a flat 10")

	RunState.score = 0
	screen._selection = {}
	screen._pyramid_click({"kind": "pyramid", "index": 23})  # a King clears alone
	check_eq(RunState.score, 5, "pyramid king scores a flat 5")

	remove_child(screen)
	screen.queue_free()
	RunState.new_run()


## The in-game screen carries every element the web build showed during play:
## the moves counter, gold, the per-variant rules strip, and the shuffle / pause
## controls, plus the pause and score-history overlays.
func test_game_hud() -> void:
	suite("in-game HUD elements")
	RunState.new_run()
	RunState.gtype = "klondike"
	RunState.start_game("klondike", 4)
	RunState.gold = 320
	RunState.add_score(20, "card points")

	var packed := load("res://scenes/screens/game_screen.tscn") as PackedScene
	var screen := packed.instantiate()
	add_child(screen)

	# Every required readout and control is wired into the Win95 chrome.
	check(screen.get_node_or_null("Rows/Toolbar/ToolRow/Moves") != null, "moves counter present")
	check(screen.get_node_or_null("Rows/Toolbar/ToolRow/Gold") != null, "gold display present")
	check(screen.get_node_or_null("Rows/Toolbar/ToolRow/Hearts") != null, "hearts present")
	check(screen.get_node_or_null("Rows/Rules") != null, "rules strip present")
	check(screen._score_pane is Button, "score is a clickable status pane")
	check(screen.get_node_or_null("Rows/Toolbar/ToolRow/Shuffle") != null, "shuffle button present")
	check(screen.get_node_or_null("Rows/Toolbar/ToolRow/Pause") != null, "pause button present")
	check(screen.get_node_or_null("Rows/Toolbar/ToolRow/Abandon") != null, "abandon button present")
	check(screen.get_node_or_null("Rows/TitleBar/TitleRow/TitleText") != null, "title bar present")
	check(screen.get_node_or_null("Overlays") is CanvasLayer, "overlay layer present")

	check(GameData.RULES.has("klondike"), "rules data exists for klondike")
	check(not screen._rules_label.text.is_empty(), "rules strip is populated")
	check("320" in screen._gold_label.text, "gold shows the current amount")

	# The score-history overlay builds its rows and clears cleanly.
	var overlays: CanvasLayer = screen.get_node("Overlays")
	screen._show_score_history()
	check_eq(overlays.get_child_count(), 1, "score history opens one overlay")
	screen._clear_overlays()
	await get_tree().process_frame
	check_eq(overlays.get_child_count(), 0, "clearing removes the overlay")

	# The pause overlay stops the clock; resuming is available on it.
	screen._on_pause()
	check_eq(overlays.get_child_count(), 1, "pause opens one overlay")
	screen._clear_overlays()
	await get_tree().process_frame

	remove_child(screen)
	screen.queue_free()
	RunState.new_run()


## Clearing a floor raises the floor-clear overlay and holds there; the
## floor-clear bonus and the routing onward happen only when the player descends,
## matching the web build's winOverlay → nextFloor flow.
func test_win_overlay() -> void:
	suite("floor-clear overlay")
	SaveManager.erase_all()
	RunState.new_run()
	RunState.start_game("klondike", 0)

	# A solved Klondike board: every foundation complete A→K.
	var won := {"type": "klondike", "tableau": [[], [], [], [], [], [], []],
		"stock": [], "waste": [], "foundations": [[], [], [], []], "card_points": {}}
	for suit in 4:
		for rank in range(1, 14):
			won["foundations"][suit].append(Cards.make_card(suit, rank))
	RunState.gs = won
	check(Rules.is_won(won), "board is solved")

	var packed := load("res://scenes/screens/game_screen.tscn") as PackedScene
	var screen := packed.instantiate()
	add_child(screen)
	var overlays: CanvasLayer = screen.get_node("Overlays")

	# Winning raises exactly one overlay and does not advance on its own.
	screen._check_win()
	check(RunState.win_overlay, "win sets the overlay flag")
	check_eq(overlays.get_child_count(), 1, "win raises exactly one overlay")
	check(not RunState.done.has(0), "the floor is not cleared until the player descends")

	# Descending clears the floor and routes onward (to the shop from floor 0).
	var button := _first_button(overlays)
	check(button != null, "overlay carries a descend button")
	if button != null:
		button.pressed.emit()
	check(RunState.done.has(0), "descending marks the floor cleared")
	check_eq(RunState.screen, "shop", "descending from floor 0 routes to the shop")

	remove_child(screen)
	screen.queue_free()
	RunState.new_run()
	SaveManager.erase_all()


func _first_button(node: Node) -> Button:
	for c in node.get_children():
		if c is Button:
			return c
		var found := _first_button(c)
		if found != null:
			return found
	return null


## Clearing a card in TriPeaks or Pyramid leaves no placeholder behind, so the
## board must be centred on its fixed footprint, not the bounding box of whatever
## cards are left. Otherwise every removal re-centres the shrinking cluster and
## the surviving cards visibly jump on each click. This lays out a real board and
## checks a card that is NOT touched stays exactly where it was after its
## neighbours are cleared.
func test_board_centring_stable() -> void:
	suite("board centring is stable")
	RunState.new_run()
	RunState.start_game("tripeaks", 0)

	get_window().size = Vector2i(1280, 720)
	var packed := load("res://scenes/screens/game_screen.tscn") as PackedScene
	var screen := packed.instantiate()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	for _i in 6:
		await get_tree().process_frame

	var board: Control = screen.get_node("Board")
	check(board.size.x > 1.0, "board has a real size to lay out in")

	# The footprint used for centring is the same full board before and after.
	var full_width: float = screen._content_width(RunState.gs)

	# A base-row card (index 27) that we never remove — record where it sits.
	var before = _card_pos_for(board, 27)
	check(before != null, "found the untouched base-row card before clearing")

	# Clear the three peaks and several other cards, then re-lay-out.
	var gs := Cards.clone_state(RunState.gs)
	for i in [0, 1, 2, 3, 4, 5, 9, 10, 11]:
		gs["pyramid"][i] = null
	RunState.gs = gs
	screen._rebuild()

	check_eq(screen._content_width(RunState.gs), full_width,
		"the centring footprint is unchanged when cards are cleared")

	var after = _card_pos_for(board, 27)
	check(after != null, "the untouched base-row card is still on the board")
	if before != null and after != null:
		check(before.distance_to(after) < 0.5,
			"an untouched card does not move when its neighbours are cleared")

	remove_child(screen)
	screen.queue_free()
	RunState.new_run()


## Position of the spawned pyramid/tripeaks card at the given index, or null.
func _card_pos_for(board: Control, index: int):
	for c in board.get_children():
		if not (c is Control):
			continue
		var m: Dictionary = c.get_meta("slot", {})
		if m.get("kind") == "pyramid" and int(m.get("index", -1)) == index:
			return (c as Control).position
	return null


## The TriPeaks streak survives undo, so rewinding a play restores the streak the
## board had before it — matching the web build's undo snapshot.
func test_tp_streak_undo() -> void:
	suite("tripeaks streak undo")
	RunState.new_run()
	RunState.gs = {"type": "tripeaks", "card_points": {}}
	RunState.tp_streak = 3
	RunState.push_undo()
	RunState.tp_streak = 4
	check(RunState.undo_move(), "undo succeeds")
	check_eq(RunState.tp_streak, 3, "undo restores the streak to its pre-move value")
	RunState.new_run()


func test_shop_and_choices() -> void:
	suite("shop and progression")
	var items := GameData.generate_shop_items([], Cards.new_rng(4))
	check_eq(items.size(), 3, "shop offers 3 items")
	var ids := {}
	for it in items:
		ids[it["id"]] = true
	check_eq(ids.size(), 3, "shop items are distinct")

	# Owned items are never offered again.
	var owned := []
	for it in GameData.SHOP_ITEMS:
		owned.append(it["id"])
	check_eq(GameData.generate_shop_items(owned, Cards.new_rng(4)).size(), 0,
		"nothing offered when everything is owned")

	for item in GameData.SHOP_ITEMS:
		check(item.has("effect") and item["effect"] != "", "item %s has an effect" % item["id"])
		check(int(item["price"]) > 0, "item %s has a price" % item["id"])
		check(int(item["tier"]) >= 0 and int(item["tier"]) <= 3, "item %s tier in range" % item["id"])

	var choices := GameData.generate_choices(Cards.new_rng(8))
	check_eq(choices.size(), 10, "10 floors of choices")
	check_eq(choices[0]["left"], "klondike", "floor 10 always offers klondike")
	check_eq(choices[9]["left"], "freecell", "final floor is freecell")
	for i in 9:
		check(choices[i]["left"] != choices[i]["right"], "floor %d offers two different games" % i)

	# Difficulty bands.
	check_eq(Rules.difficulty(0), "easy", "floor 0 is easy")
	check_eq(Rules.difficulty(5), "medium", "floor 5 is medium")
	check_eq(Rules.difficulty(9), "hard", "floor 9 is hard")

	# Gold breakdown: a perfect floor earns every bonus.
	var perfect := GameData.floor_gold_breakdown(60000, 1000, 0, true)
	var total := 0
	for row in perfect:
		if row["earned"]:
			total += int(row["amount"])
	check_eq(total, 105, "perfect floor earns 50+20+15+10+10")

	var sloppy := GameData.floor_gold_breakdown(400000, 0, 3, false)
	var sloppy_total := 0
	for row in sloppy:
		if row["earned"]:
			sloppy_total += int(row["amount"])
	check_eq(sloppy_total, 50, "slow floor with undos earns only the base")


func test_save_round_trip() -> void:
	suite("local save")
	SaveManager.erase_all()
	check_eq(int(SaveManager.profile["banked_credits"]), 0, "fresh profile starts empty")
	check(not SaveManager.has_run(), "no run in a fresh save")

	# Profile persists.
	SaveManager.add_banked_credits(250)
	SaveManager.set_cardback("dee")
	SaveManager.mark_seen("seen_dee_topics", "tower")
	SaveManager.reveal_patron("marie")
	check(SaveManager.save_game(), "save writes successfully")

	SaveManager.load_game()
	check_eq(int(SaveManager.profile["banked_credits"]), 250, "credits survive a reload")
	check_eq(SaveManager.profile["cardback"], "dee", "card back survives a reload")
	check(SaveManager.has_seen("seen_dee_topics", "tower"), "seen topics survive")
	check(SaveManager.is_patron_revealed("marie"), "patron reveal survives")

	check(not SaveManager.spend_banked_credits(9999), "cannot overspend")
	check(SaveManager.spend_banked_credits(100), "can spend what we have")
	check_eq(int(SaveManager.profile["banked_credits"]), 150, "spending deducts")

	# A run round-trips through the save file, board included.
	RunState.new_run()
	RunState.lives = 2
	RunState.floor_index = 4
	RunState.score = 777
	RunState.gold = 42
	RunState.gtype = "spider"
	RunState.gs = Rules.init_spider(4, Cards.new_rng(1))
	RunState.inventory = [GameData.item_by_id("coffee")]
	var snapshot := RunState.to_snapshot()
	SaveManager.store_run(snapshot)
	SaveManager.save_game()

	SaveManager.load_game()
	check(SaveManager.has_run(), "saved run is detected")
	RunState.from_snapshot(SaveManager.run)
	check_eq(RunState.lives, 2, "lives restored")
	check_eq(RunState.floor_index, 4, "floor restored")
	check_eq(RunState.score, 777, "score restored")
	check_eq(RunState.gold, 42, "gold restored")
	check_eq(RunState.gtype, "spider", "game type restored")
	check_eq(RunState.inventory.size(), 1, "inventory restored")
	check_eq(RunState.gs["tableau"].size(), 10, "board restored with all columns")
	check_eq(RunState.gs["type"], "spider", "board type restored")

	# Local high scores replace the online leaderboard.
	SaveManager.highscores = []
	SaveManager.record_score("Ada", 5000, 300.0, true)
	SaveManager.record_score("Grace", 9000, 400.0, true)
	SaveManager.record_score("Alan", 9000, 200.0, false)
	check_eq(SaveManager.highscores.size(), 3, "three scores recorded")
	check_eq(SaveManager.highscores[0]["name"], "Alan", "higher score with faster time ranks first")
	check_eq(SaveManager.highscores[1]["name"], "Grace", "tie broken by time")
	check_eq(SaveManager.highscores[2]["name"], "Ada", "lowest score ranks last")

	# The table is capped.
	for i in 30:
		SaveManager.record_score("Filler%d" % i, i, 100.0, false)
	check_eq(SaveManager.highscores.size(), SaveManager.MAX_HIGHSCORES, "table is capped")

	# An empty name does not produce a blank row.
	SaveManager.highscores = []
	SaveManager.record_score("   ", 10, 10.0, false)
	check_eq(SaveManager.highscores[0]["name"], "Anonymous", "blank names become Anonymous")

	# A corrupt file is recovered from rather than crashing.
	var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{ this is not valid json")
	f.close()
	SaveManager.load_game()
	check_eq(int(SaveManager.profile["banked_credits"]), 0, "corrupt save falls back to defaults")
	check(FileAccess.file_exists("user://savegame.corrupt.json"), "corrupt save is kept aside")

	SaveManager.erase_all()


## Drives a complete 10-floor run through the real progression code, clearing
## each floor by force. Catches breakage in the floor/shop/victory chain that
## unit tests on individual rules would miss.
func test_full_run() -> void:
	suite("full run progression")
	SaveManager.erase_all()
	RunState.new_run()

	check_eq(RunState.lives, 3, "run starts with 3 lives")
	check_eq(RunState.floor_index, 0, "run starts on floor 0")
	check_eq(RunState.choices.size(), 10, "run has 10 floors of choices")

	var reached_victory := [false]
	RunState.game_won.connect(func(): reached_victory[0] = true)

	for f in GameData.TOTAL_FLOORS:
		var choice: Dictionary = RunState.choices[f]
		var type: String = choice["left"]
		RunState.start_game(type, f)
		check_eq(RunState.screen, "game", "floor %d enters the game screen" % f)
		check(not RunState.gs.is_empty(), "floor %d deals a board" % f)
		check_eq(RunState.gs["type"], type, "floor %d board matches chosen type" % f)

		check_eq(RunState.undos_remaining(), GameData.UNDOS_PER_FLOOR,
			"floor %d starts with a full undo budget" % f)
		RunState.push_undo()
		check(RunState.undo_move(), "undo works on floor %d" % f)
		check_eq(RunState.undos_remaining(), GameData.UNDOS_PER_FLOOR - 1,
			"undo consumes budget on floor %d" % f)

		RunState.next_floor()

	check(reached_victory[0], "clearing 10 floors reaches victory")
	check_eq(RunState.done.size(), GameData.TOTAL_FLOORS, "all 10 floors marked done")
	# Floor bonuses are 100 x (10-floor), summing to 100 x (10+9+...+1).
	check_eq(RunState.score, 5500, "floor bonuses total 5500")

	# Losing all three lives ends the run.
	RunState.new_run()
	RunState.start_game("klondike", 0)
	check(RunState.abandon_floor(), "first abandon costs a life")
	check_eq(RunState.lives, 2, "two lives left")
	check(RunState.abandon_floor(), "second abandon costs a life")
	check(not RunState.abandon_floor(), "third abandon ends the run")
	check_eq(RunState.screen, "gameover", "run ends on the gameover screen")

	# A no-life-abandon item is consumed instead of a life.
	RunState.new_run()
	RunState.start_game("klondike", 0)
	RunState.inventory = [GameData.item_by_id("extinguisher")]
	check(not RunState.abandon_floor(), "item absorbs the abandon")
	check_eq(RunState.lives, 3, "no life lost while the item is held")
	check_eq(RunState.inventory.size(), 0, "item is consumed")

	# The shop awards credits and restocks.
	RunState.new_run()
	RunState.start_game("klondike", 0)
	RunState.next_floor()
	check_eq(RunState.screen, "shop", "clearing a floor opens the shop")
	check(RunState.shop_gold_earned > 0, "shop awards credits")
	check_eq(RunState.gold, RunState.shop_gold_earned, "credits are banked")
	check_eq(RunState.shop_items.size(), 3, "shop restocks 3 items")
	check_eq(RunState.floor_index, 1, "floor advances past the shop")

	SaveManager.erase_all()


func test_hints() -> void:
	suite("hint finders")

	# Klondike: an exposed ace must be reported as a foundation move.
	var kl := Rules.init_klondike(5, Cards.new_rng(21))
	kl["waste"] = [Cards.make_card(Cards.Suit.SPADES, 1, true)]
	var found := Hints.klondike(kl, false)
	check_eq(found.size(), 1, "single-hint mode returns at most one hint")
	check_eq(found[0]["src"], "waste", "waste ace is found")
	check_eq(found[0]["tsrc"], "found", "waste ace targets a foundation")
	check(Hints.klondike(kl, true).size() >= 1, "all-hints mode returns at least as many")

	# Spider: a 6 onto a 7 in another column.
	var sp := Rules.init_spider(0, Cards.new_rng(22))
	sp["tableau"][0] = [Cards.make_card(0, 7, true)]
	sp["tableau"][1] = [Cards.make_card(0, 6, true)]
	var sp_hints := Hints.spider(sp, false)
	check_eq(sp_hints.size(), 1, "spider finds the 6-onto-7 move")
	check_eq(sp_hints[0]["col"], 1, "hint source is the 6's column")
	check_eq(sp_hints[0]["tcol"], 0, "hint target is the 7's column")

	# TriPeaks: only free cards adjacent in rank to the waste top.
	var tp := Rules.init_tripeaks(0, Cards.new_rng(23))
	tp["waste"] = [Cards.make_card(0, 7, true)]
	for i in 28:
		tp["pyramid"][i] = null
	tp["pyramid"][27] = Cards.make_card(1, 8, true)
	check_eq(Hints.tripeaks(tp, true).size(), 1, "tripeaks finds the adjacent card")
	tp["pyramid"][27] = Cards.make_card(1, 4, true)
	check_eq(Hints.tripeaks(tp, true).size(), 0, "tripeaks ignores non-adjacent ranks")

	# Pyramid: a king is always playable alone.
	var py := Rules.init_pyramid(0, Cards.new_rng(24))
	for i in 28:
		py["pyramid"][i] = null
	py["pyramid"][27] = Cards.make_card(0, 13, true)
	py["waste"] = []
	check_eq(Hints.pyramid(py, true).size(), 1, "pyramid finds the lone king")

	# FreeCell: an ace on a tableau top goes to a foundation.
	var fc := Rules.init_freecell(0, false, Cards.new_rng(25))
	fc["tableau"][0] = [Cards.make_card(Cards.Suit.HEARTS, 1, true)]
	var fc_hints := Hints.freecell(fc, false)
	check_eq(fc_hints.size(), 1, "freecell finds the ace")
	check_eq(fc_hints[0]["tsrc"], "found", "freecell prefers the foundation")

	# The dispatcher routes by board type.
	check(Hints.find(kl, false).size() > 0, "find() dispatches klondike")
	check_eq(Hints.find({}, false).size(), 0, "find() on an empty board returns nothing")


func test_item_effects() -> void:
	suite("item effects")
	SaveManager.erase_all()

	# ── Knotted Cord: +5 undos ──
	RunState.new_run()
	RunState.start_game("klondike", 5)
	var before := RunState.undos_remaining()
	var r := ItemEffects.activate(GameData.item_by_id("rubber-band"), 0)
	check(r["consumed"], "knotted cord is consumed")
	check_eq(RunState.undos_remaining(), before + 5, "knotted cord adds 5 undos")

	# ── Mortlake Brew: a free draw, and refused where it makes no sense ──
	RunState.start_game("klondike", 5)
	var stock_before: int = RunState.gs["stock"].size()
	r = ItemEffects.activate(GameData.item_by_id("coffee"), 0)
	check(r["consumed"], "brew is consumed in klondike")
	check_eq(RunState.gs["stock"].size(), stock_before - 3, "brew draws from stock")
	RunState.start_game("spider", 5)
	r = ItemEffects.activate(GameData.item_by_id("coffee"), 0)
	check(not r["consumed"], "brew is refused in spider")
	check(String(r["message"]) != "", "refusal explains itself")

	# ── Sealing Wax: one more recycle ──
	RunState.start_game("klondike", 9)
	var draws: int = RunState.gs["draws_left"]
	r = ItemEffects.activate(GameData.item_by_id("tape"), 0)
	check(r["consumed"], "sealing wax is consumed")
	check_eq(int(RunState.gs["draws_left"]), draws + 1, "sealing wax adds a recycle")

	# ── Sealed Letter: waste back to stock, refused when the waste is empty ──
	RunState.start_game("klondike", 5)
	r = ItemEffects.activate(GameData.item_by_id("envelope"), 0)
	check(not r["consumed"], "sealed letter refused on an empty waste")
	RunState.gs = Rules.klondike_draw(RunState.gs)
	var wasted: int = RunState.gs["waste"].size()
	var left_in_stock: int = RunState.gs["stock"].size()
	r = ItemEffects.activate(GameData.item_by_id("envelope"), 0)
	check(r["consumed"], "sealed letter is consumed")
	check_eq(RunState.gs["waste"].size(), 0, "waste is emptied")
	# The web build assigned stock = waste, deleting whatever was left in the
	# stock. All 52 cards must still be accounted for after a recycle.
	check_eq(RunState.gs["stock"].size(), left_in_stock + wasted,
		"recycled waste is added to the stock, not swapped for it")
	var accounted: int = RunState.gs["stock"].size() + RunState.gs["waste"].size()
	for col in RunState.gs["tableau"]:
		accounted += col.size()
	for f in RunState.gs["foundations"]:
		accounted += f.size()
	check_eq(accounted, 52, "no cards are lost by the recycle")

	# ── Obsidian Mirror: reveals face-down cards and reports what to re-hide ──
	RunState.start_game("klondike", 5)
	var hidden_before := 0
	for col in RunState.gs["tableau"]:
		for c in col:
			if not c["face_up"]:
				hidden_before += 1
	check(hidden_before > 0, "klondike deals face-down cards")
	r = ItemEffects.activate(GameData.item_by_id("magnifier"), 0)
	check(r["consumed"], "mirror is consumed")
	var still_hidden := 0
	for col in RunState.gs["tableau"]:
		for c in col:
			if not c["face_up"]:
				still_hidden += 1
	check_eq(still_hidden, 0, "everything is revealed")
	check_eq((r["timed"]["hidden"] as Array).size(), hidden_before, "records what to re-hide")

	# ── Wax Seal Press: sends an ace up, and reports when there is none ──
	RunState.start_game("klondike", 5)
	RunState.gs["tableau"][0] = [Cards.make_card(Cards.Suit.CLUBS, 1, true)]
	r = ItemEffects.activate(GameData.item_by_id("stapler"), 0)
	check(r["consumed"], "seal press is consumed when an ace exists")
	check_eq(RunState.gs["foundations"][Cards.Suit.CLUBS].size(), 1, "ace reaches its foundation")
	for c in 7:
		RunState.gs["tableau"][c] = [Cards.make_card(0, 9, true)]
	RunState.gs["waste"] = []
	r = ItemEffects.activate(GameData.item_by_id("stapler"), 0)
	check(not r["consumed"], "seal press is not consumed without an ace")

	# ── Philosopher's Sponge: rewinds up to 10 moves ──
	RunState.start_game("klondike", 5)
	for i in 12:
		RunState.push_undo()
		RunState.gs = Rules.klondike_draw(RunState.gs)
	var deep: int = RunState.undo_stack.size()
	r = ItemEffects.activate(GameData.item_by_id("eraser"), 0)
	check(r["consumed"], "sponge is consumed")
	check_eq(RunState.undo_stack.size(), deep - 10, "sponge pops 10 states")
	RunState.undo_stack = []
	r = ItemEffects.activate(GameData.item_by_id("eraser"), 0)
	check(not r["consumed"], "sponge refuses with nothing to undo")

	# ── Skeleton Key: a fifth cell, FreeCell only ──
	RunState.start_game("klondike", 5)
	r = ItemEffects.activate(GameData.item_by_id("spare-key"), 0)
	check(not r["consumed"], "skeleton key refused outside freecell")
	RunState.start_game("freecell", 5)
	check_eq(RunState.gs["freecells"].size(), 4, "freecell starts with 4 cells")
	r = ItemEffects.activate(GameData.item_by_id("spare-key"), 0)
	check(r["consumed"], "skeleton key is consumed in freecell")
	check_eq(RunState.gs["freecells"].size(), 5, "a fifth cell appears")
	r = ItemEffects.activate(GameData.item_by_id("spare-key"), 0)
	check(not r["consumed"], "a sixth cell is refused")

	# ── Alchemist's Cabinet ──
	RunState.start_game("spider", 5)
	RunState.toolbox_uses = 0
	RunState.toolbox_card = null
	r = ItemEffects.activate(GameData.item_by_id("toolbox"), 0)
	check(r["consumed"], "cabinet is consumed")
	check_eq(RunState.toolbox_uses, ItemEffects.TOOLBOX_USES, "cabinet grants 8 uses")
	r = ItemEffects.activate(GameData.item_by_id("toolbox"), 0)
	check(not r["consumed"], "a second cabinet is refused while one is active")

	# ── Scrying Glass / Astrolabe ──
	RunState.start_game("klondike", 5)
	RunState.gs["waste"] = [Cards.make_card(Cards.Suit.SPADES, 1, true)]
	r = ItemEffects.activate(GameData.item_by_id("sticky-note"), 0)
	check(r["consumed"], "scrying glass is consumed when a move exists")
	check_eq(String(r["timed"]["kind"]), "hints", "scrying glass returns hints")
	check_eq((r["timed"]["hints"] as Array).size(), 1, "scrying glass returns exactly one")
	r = ItemEffects.activate(GameData.item_by_id("calculator"), 0)
	check((r["timed"]["hints"] as Array).size() >= 1, "astrolabe returns all hints")

	# ── Quill of Ravens: peek at three ──
	RunState.start_game("klondike", 5)
	r = ItemEffects.activate(GameData.item_by_id("pencil"), 0)
	check(r["consumed"], "quill is consumed")
	check_eq((r["timed"]["cards"] as Array).size(), 3, "quill shows three cards")

	# ── Athame: arms a mode, then removes the clicked card ──
	RunState.start_game("klondike", 5)
	r = ItemEffects.activate(GameData.item_by_id("scissors"), 0)
	check(not r["consumed"], "athame is not consumed on arming")
	check_eq(String(r["mode"]["effect"]), "remove-card", "athame arms remove-card")
	var col0: int = RunState.gs["tableau"][0].size()
	var res := ItemEffects.resolve_mode(r["mode"], {"kind": "tableau", "col": 0, "index": 0})
	check(res["consumed"], "athame is consumed on a valid target")
	check_eq(RunState.gs["tableau"][0].size(), col0 - 1, "the card is gone")
	# A face-down target is rejected and the item survives.
	r = ItemEffects.activate(GameData.item_by_id("scissors"), 0)
	res = ItemEffects.resolve_mode(r["mode"], {"kind": "tableau", "col": 6, "index": 0})
	check(not res["consumed"], "athame refuses a face-down card")

	# ── Brass Compass: flips a face-down card ──
	RunState.start_game("klondike", 5)
	r = ItemEffects.activate(GameData.item_by_id("paperclip"), 0)
	check_eq(String(r["mode"]["effect"]), "flip-card", "compass arms flip-card")
	check(not RunState.gs["tableau"][6][0]["face_up"], "target starts face-down")
	res = ItemEffects.resolve_mode(r["mode"], {"kind": "tableau", "col": 6, "index": 0})
	check(res["consumed"], "compass is consumed")
	check(RunState.gs["tableau"][6][0]["face_up"], "the card is now face-up")
	r = ItemEffects.activate(GameData.item_by_id("paperclip"), 0)
	res = ItemEffects.resolve_mode(r["mode"], {"kind": "tableau", "col": 6, "index": 0})
	check(not res["consumed"], "compass refuses an already face-up card")

	# ── Angelic Besom: sweeps a top card to an empty column ──
	RunState.start_game("spider", 5)
	r = ItemEffects.activate(GameData.item_by_id("broom"), 0)
	check(not r["consumed"], "besom refused with no empty column")
	RunState.gs["tableau"][3] = []
	r = ItemEffects.activate(GameData.item_by_id("broom"), 0)
	check_eq(String(r["mode"]["effect"]), "broom", "besom arms once a column is empty")
	var src_len: int = RunState.gs["tableau"][0].size()
	res = ItemEffects.resolve_mode(r["mode"], {"kind": "tableau", "col": 0})
	check(res["consumed"], "besom is consumed")
	check_eq(RunState.gs["tableau"][0].size(), src_len - 1, "source pile shrinks")
	check_eq(RunState.gs["tableau"][3].size(), 1, "the card lands in the empty column")

	# ── Hermetic Casket: pull a buried waste card to the top ──
	RunState.start_game("klondike", 5)
	r = ItemEffects.activate(GameData.item_by_id("briefcase"), 0)
	check(not r["consumed"], "casket refused on a short waste")
	for i in 3:
		RunState.gs = Rules.klondike_draw(RunState.gs)
	r = ItemEffects.activate(GameData.item_by_id("briefcase"), 0)
	check(not r["picker"].is_empty(), "casket opens a picker")
	var buried: Dictionary = RunState.gs["waste"][0]
	res = ItemEffects.resolve_picker(r["picker"], buried)
	check(res["consumed"], "casket is consumed on choosing")
	var new_top: Dictionary = RunState.gs["waste"][RunState.gs["waste"].size() - 1]
	check_eq(Cards.key(new_top), Cards.key(buried), "the chosen card is now on top")

	# ── Enochian Key: pull any card out of the stock ──
	RunState.start_game("klondike", 5)
	r = ItemEffects.activate(GameData.item_by_id("master-key"), 0)
	check(not r["picker"].is_empty(), "enochian key opens a picker")
	var wanted: Dictionary = RunState.gs["stock"][5]
	var stock_size: int = RunState.gs["stock"].size()
	res = ItemEffects.resolve_picker(r["picker"], wanted)
	check(res["consumed"], "enochian key is consumed")
	check_eq(RunState.gs["stock"].size(), stock_size - 1, "stock shrinks by one")
	check_eq(Cards.key(RunState.gs["waste"][RunState.gs["waste"].size() - 1]), Cards.key(wanted),
		"the chosen card is on the waste")

	# ── Queen's Patronage: auto-clears the floor via the win overlay ──
	# Like a real win, it raises the floor-clear overlay and holds; the clear and
	# the routing happen when the player descends (web skip-floor calls handleWin).
	RunState.new_run()
	RunState.start_game("klondike", 0)
	r = ItemEffects.activate(GameData.item_by_id("exec-chair"), 0)
	check(r["consumed"], "patronage is consumed")
	check(bool(r.get("win", false)), "patronage raises the floor-clear overlay")
	check(RunState.win_overlay, "patronage sets the win-overlay flag")
	check(not RunState.done.has(0), "the floor clears only when the player descends")
	RunState.next_floor()  # simulate the descend button
	check(RunState.done.has(0), "descending clears the floor")
	check_eq(RunState.screen, "shop", "patronage routes to the shop after descending")

	# ── Vial of Quicksilver: retreat with no life lost ──
	RunState.new_run()
	RunState.start_game("klondike", 0)
	RunState.inventory = [GameData.item_by_id("extinguisher")]
	ItemEffects.activate(GameData.item_by_id("extinguisher"), 0)
	check_eq(RunState.lives, 3, "quicksilver costs no life")
	check_eq(RunState.inventory.size(), 0, "quicksilver is consumed")
	check_eq(RunState.screen, "map", "quicksilver returns to the map")

	# Every item in the shop is reachable by the dispatcher.
	RunState.new_run()
	RunState.start_game("klondike", 5)
	for item in GameData.SHOP_ITEMS:
		var out := ItemEffects.activate(item, 0)
		check(out.has("consumed") and out.has("message"), "%s returns a result" % item["id"])
		if item["effect"] in ["skip-floor", "no-life-abandon"]:
			RunState.new_run()
			RunState.start_game("klondike", 5)

	SaveManager.erase_all()


func test_narrative() -> void:
	suite("narrative and compendium")
	SaveManager.erase_all()

	# Content survived extraction intact.
	check_eq(Narrative.PATRONS.size(), 6, "six patrons")
	check_eq(Narrative.LORE.size(), 1, "one lore entry")
	check_eq(Narrative.DEE_DIALOGUE.size(), 59, "intro has 59 beats")
	check_eq(Narrative.DEE_FINAL.size(), 7, "final interlude has 7 beats")
	check_eq(Narrative.DEE_CHECKIN_TOPICS.size(), 3, "checkin offers 3 topics")
	check_eq(Narrative.DEE_DIALOGUE3_TOPICS.size(), 3, "third transmission offers 3 topics")
	check_eq(Narrative.VICTORY_CHOICES.size(), Narrative.VICTORY_RESPONSES.size(),
		"every victory choice has a response")

	# Every entry has the fields the compendium reads.
	for p in Narrative.PATRONS:
		check(p.has("id") and String(p["id"]) != "", "patron has an id")
		check(p.has("name"), "patron %s has a name" % p.get("id", "?"))
		check(p.has("year"), "patron %s has a year" % p.get("id", "?"))

	# Image references point at files that exist.
	var checked := 0
	for entry in Narrative.PATRONS + Narrative.LORE:
		if entry.has("img"):
			check(ResourceLoader.exists(str(entry["img"])),
				"compendium image exists: %s" % entry["img"])
			checked += 1
	check(checked >= 3, "at least three compendium portraits are wired")

	for beat in Narrative.DEE_DIALOGUE:
		if beat.has("img"):
			check(ResourceLoader.exists(str(beat["img"])),
				"intro image exists: %s" % beat["img"])
		if beat.has("imgs"):
			for path in beat["imgs"]:
				check(ResourceLoader.exists(str(path)), "intro image exists: %s" % path)

	# HTML did not survive into the text.
	var html := 0
	for beat in Narrative.DEE_DIALOGUE:
		if str(beat.get("text", "")).contains("<"):
			html += 1
	check_eq(html, 0, "no HTML tags left in dialogue text")

	# Topics carry their beats.
	for topic in Narrative.DEE_CHECKIN_TOPICS:
		check(topic.has("question"), "topic has a question")
		check((topic.get("beats", []) as Array).size() > 0, "topic has beats")

	# ── Interlude routing ──
	# Dee interrupts after floors 3, 6 and 9 (indices 2, 5, 8), once per profile.
	# Match the screen names exactly: "dee-dialogue3" does not end in
	# "dialogue", and a suffix test silently skipped it.
	const DIALOGUE_SCREENS := ["dee-checkin-dialogue", "dee-dialogue3",
		"dee-final-dialogue", "victory-dialogue", "patron-dialogue"]
	RunState.new_run()
	var seen := {}
	for f in GameData.TOTAL_FLOORS:
		RunState.start_game("klondike", f)
		RunState.next_floor()
		if DIALOGUE_SCREENS.has(RunState.screen):
			seen[f] = RunState.screen
			# Dismissing the interlude continues to the shop.
			RunState.proceed_to_shop()
	check(seen.has(2), "an interlude fires after floor index 2")
	check(seen.has(5), "an interlude fires after floor index 5")
	check(seen.has(8), "an interlude fires after floor index 8")
	check_eq(String(seen.get(2, "")), "dee-checkin-dialogue", "floor 2 is the check-in")
	check_eq(String(seen.get(5, "")), "dee-dialogue3", "floor 5 is the third transmission")
	check_eq(String(seen.get(8, "")), "dee-final-dialogue", "floor 8 is the final word")

	# Second run: already seen, so no interludes and the shop follows directly.
	RunState.new_run()
	var repeats := 0
	for f in GameData.TOTAL_FLOORS - 1:
		RunState.start_game("klondike", f)
		RunState.next_floor()
		if DIALOGUE_SCREENS.has(RunState.screen):
			repeats += 1
			RunState.proceed_to_shop()
	check_eq(repeats, 0, "interludes do not repeat once seen")

	# ── Compendium economy ──
	SaveManager.erase_all()
	check(not SaveManager.has_seen("unlocked_connections", "johndee"),
		"connections start locked")
	SaveManager.add_banked_credits(400)
	check(not SaveManager.spend_banked_credits(500), "cannot buy a connection under-funded")
	SaveManager.add_banked_credits(200)
	check(SaveManager.spend_banked_credits(500), "can buy once funded")
	SaveManager.mark_seen("unlocked_connections", "johndee")
	check(SaveManager.has_seen("unlocked_connections", "johndee"), "connection unlock persists")
	check_eq(int(SaveManager.profile["banked_credits"]), 100, "credits are deducted")

	SaveManager.save_game()
	SaveManager.load_game()
	check(SaveManager.has_seen("unlocked_connections", "johndee"),
		"connection survives a reload")

	# The revealed patron shows her true name. (The reveal *chain* — John Dee's
	# connection revealing Mary — is covered in full by test_unlockables; here
	# the save already has that connection unlocked, so she is revealed.)
	var marie := {}
	for p in Narrative.PATRONS:
		if String(p["id"]) == "marie":
			marie = p
	check(marie.has("true_name"), "the other queen has a true name")
	check(SaveManager.is_patron_revealed("marie"),
		"Mary is revealed once John Dee's connection is unlocked")

	SaveManager.erase_all()


## Loads and instantiates every scene in the project.
##
## This exists because a parse error in map_screen.gd shipped undetected: the
## headless boot only ever reaches the title screen, so no other UI script was
## compiled, and the logic tests never touch scenes. Adding a child runs _ready
## synchronously, so this catches both parse errors and crashes on entry.
func test_every_scene_loads() -> void:
	suite("every scene loads")

	# Screens that read RunState.screen to decide what to show need it set first.
	var scenes := [
		["res://scenes/app.tscn", ""],
		["res://scenes/card_view.tscn", ""],
		["res://scenes/tower_menu.tscn", ""],
		["res://scenes/screens/title_screen.tscn", "title"],
		["res://scenes/screens/map_screen.tscn", "map"],
		["res://scenes/screens/game_screen.tscn", "game"],
		["res://scenes/screens/shop_screen.tscn", "shop"],
		["res://scenes/screens/end_screen.tscn", "gameover"],
		["res://scenes/screens/compendium_screen.tscn", "compendium"],
		["res://scenes/screens/cardback_screen.tscn", "cardback-select"],
		["res://scenes/screens/dialogue_screen.tscn", "patron-dialogue"],
	]

	# Give the screens a plausible run to render, so _ready does real work
	# rather than bailing out early.
	RunState.new_run()
	RunState.start_game("klondike", 0)
	RunState.shop_items = GameData.generate_shop_items([])
	RunState.shop_gold_breakdown = GameData.floor_gold_breakdown(60000, 500, 0, true)

	for entry in scenes:
		var path: String = entry[0]
		var screen: String = entry[1]

		check(ResourceLoader.exists(path), "scene exists: %s" % path)
		var packed := ResourceLoader.load(path) as PackedScene
		check(packed != null, "scene loads as PackedScene: %s" % path)
		if packed == null:
			continue

		if screen != "":
			RunState.screen = screen

		var instance := packed.instantiate()
		check(instance != null, "scene instantiates: %s" % path)
		if instance == null:
			continue

		# add_child runs _ready synchronously; a script error surfaces here.
		add_child(instance)
		check(instance.is_inside_tree(), "scene enters the tree: %s" % path)
		# A parse error leaves the node with no script rather than failing to
		# instantiate, which is exactly how map_screen.gd shipped broken.
		if screen != "" or path.ends_with("app.tscn"):
			check(instance.get_script() != null,
				"script compiled and attached: %s" % path)
		remove_child(instance)
		instance.queue_free()

	# Every screen the router can reach must have a scene registered.
	var app_script := load("res://scripts/ui/app.gd")
	check(app_script != null, "app.gd loads")

	SaveManager.erase_all()


## Verifies the unlock chain matches the web build exactly:
##   John Dee's connection (gated behind his third transmission, costs Time
##   Energy) reveals Mary, and Mary's reveal is the only thing that unlocks the
##   Mary's Cipher card back. In-development patrons cannot be bought.
func test_unlockables() -> void:
	suite("unlockables")
	SaveManager.erase_all()

	# Mirrors cardback_screen._is_unlocked and the web cardbackUnlocked.
	var cardback_unlocked := func(id: String) -> bool:
		for cb in GameData.CARDBACKS:
			if cb["id"] == id:
				if bool(cb.get("unlocked", false)):
					return true
				if cb.has("requires_reveal"):
					return SaveManager.is_patron_revealed(String(cb["requires_reveal"]))
				return false
		return false

	# The three free backs are always available; Mary's starts locked.
	check(cardback_unlocked.call("classic"), "classic back is always unlocked")
	check(cardback_unlocked.call("cult"), "cult back is always unlocked")
	check(cardback_unlocked.call("dee"), "dee back is always unlocked")
	check(not cardback_unlocked.call("marie"), "Mary's Cipher starts locked")
	check(not SaveManager.is_patron_revealed("marie"), "Mary starts unrevealed")

	# John Dee's connection is unavailable until his third transmission.
	check(not bool(SaveManager.profile.get("dee_dialogue3_done", false)),
		"third transmission not seen yet")

	# Reveal is derived from John Dee's connection, so before it is uncovered
	# Mary is not revealed even though the flag is checked directly.
	check(not SaveManager.has_seen("unlocked_connections", "johndee"),
		"John Dee's connection starts locked")

	# Not enough Time Energy: the connection cannot be uncovered.
	SaveManager.profile["dee_dialogue3_done"] = true
	SaveManager.add_banked_credits(400)
	check(not SaveManager.spend_banked_credits(500), "cannot afford the 500 connection")
	check(not SaveManager.is_patron_revealed("marie"), "Mary still hidden after a failed buy")

	# Uncover John Dee's connection: this is the sole trigger for Mary's reveal.
	SaveManager.add_banked_credits(200)  # now 600
	check(SaveManager.spend_banked_credits(500), "can afford the connection now")
	SaveManager.mark_seen("unlocked_connections", "johndee")

	check(SaveManager.is_patron_revealed("marie"),
		"uncovering John Dee's connection reveals Mary")
	check(cardback_unlocked.call("marie"),
		"Mary's reveal unlocks the Mary's Cipher card back")
	check_eq(int(SaveManager.profile["banked_credits"]), 100, "connection cost was deducted")

	# The link survives a save/reload, since it is derived from the stored
	# connection rather than a separate reveal flag.
	SaveManager.save_game()
	SaveManager.load_game()
	check(SaveManager.has_seen("unlocked_connections", "johndee"), "connection persists")
	check(SaveManager.is_patron_revealed("marie"), "Mary stays revealed after reload")
	check(cardback_unlocked.call("marie"), "Mary's Cipher stays unlocked after reload")

	# In-development patrons carry a cost in the data but cannot be bought — the
	# only reveal path is the connection above.
	var marie := {}
	for entry in Narrative.PATRONS:
		if String(entry["id"]) == "marie":
			marie = entry
	check(bool(marie.get("in_development", false)), "Mary is flagged in development")
	check(marie.has("patron_unlock_cost"), "Mary carries a patron unlock cost in the data")

	# A fresh save with no John Dee connection keeps Mary locked regardless of
	# how much Time Energy is banked — there is no direct purchase.
	SaveManager.erase_all()
	SaveManager.add_banked_credits(5000)
	check(not SaveManager.is_patron_revealed("marie"),
		"Time Energy alone cannot reveal an in-development patron")
	check(not cardback_unlocked.call("marie"), "Mary's Cipher stays locked without the connection")

	SaveManager.erase_all()
