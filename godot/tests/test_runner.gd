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
	test_shop_and_choices()
	test_save_round_trip()
	test_full_run()

	print("\n──────────────────────────────────────────")
	print("  passed: %d   failed: %d" % [_passed, _failed])
	print("──────────────────────────────────────────\n")
	get_tree().quit(1 if _failed > 0 else 0)


func suite(name: String) -> void:
	_current = name
	print("• %s" % name)


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
	RunState.floor = 0
	RunState.gtype = "klondike"
	RunState.done = []
	RunState.next_floor()
	check_eq(RunState.score, 1000, "clearing floor 0 awards 1000")

	check_eq(GameData.MAX_CARD_POINTS, 1040, "perfect card score is 52 x 20")


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
	RunState.floor = 4
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
	check_eq(RunState.floor, 4, "floor restored")
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
	check_eq(RunState.floor, 0, "run starts on floor 0")
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
	check_eq(RunState.floor, 1, "floor advances past the shop")

	SaveManager.erase_all()
