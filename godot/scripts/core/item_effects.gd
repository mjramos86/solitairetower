class_name ItemEffects
extends RefCounted

## The 19 shop item effects, ported from executeItemEffect and
## handleItemModeClick in index.html.
##
## `activate` returns a result Dictionary rather than touching UI directly, so
## the whole item system is testable headlessly:
##
##   consumed  bool    remove the item from the inventory
##   message   String  toast to show, or "" for none
##   mode      Dict    a click-targeting mode the board should arm, or {}
##   picker    Dict    a card picker the board should open, or {}
##   timed     Dict    a temporary board state to revert after `seconds`
##
## Effects that need a second click (Athame, Brass Compass, Angelic Besom)
## return a `mode`; the board calls `resolve_mode` when the player clicks.
## Effects that need a choice (Hermetic Casket, Enochian Key) return a `picker`;
## the board calls `resolve_picker`.
##
## Mary Stuart's nine items add three ideas the original nineteen never needed:
##   - a RANK picker (`"ranks": true`), for the Nomenclator Disc and the
##     Fotheringhay Block, whose "cards" are one stand-in per rank;
##   - a TWO-click mode (Laundress's Cloak): the first click comes back
##     unconsumed with the mode re-armed and the first card recorded in it;
##   - FLOOR FLAGS kept in the game state itself — see CARRIED_FLAGS.

const HINT_SECONDS := 5.0
const HINT_ALL_SECONDS := 8.0
const REVEAL_SECONDS := 8.0
const PEEK_SECONDS := 6.0

## Floor-long enchantments, stored as keys on the game state so they save and
## load with the board. They outlast an undo and a re-deal of the same floor:
## the item that set them is already spent, and an undo snapshot taken before
## the item was used would otherwise quietly take the effect back. They do not
## outlast the floor — a new floor deals a fresh state without them.
##
## `purged_ranks` and `lone_ranks` (Fotheringhay Block) are deliberately NOT
## carried: they describe cards that are gone, and an undo that brings those
## cards back must take the flags back with them.
const CARRIED_FLAGS := ["marked_ranks", "ledger", "queens_wild"]

const BONUS_UNDOS := 5
const BIG_UNDO_STEPS := 10
const TOOLBOX_USES := 8


static func _result(consumed: bool = false, message: String = "") -> Dictionary:
	return {"consumed": consumed, "message": message, "mode": {}, "picker": {}, "timed": {}}


## Whether an effect can do anything in the given variant, at the variant level
## (not the live board). Kept beside `activate` so the inventory tooltip's
## "usable here?" line stays in step with the guards below. Effects with no
## variant guard — instant utilities and click-any-card tools — work anywhere.
static func usable_in(effect: String, type: String) -> bool:
	match effect:
		"free-draw":
			return ["klondike", "tripeaks", "pyramid"].has(type)
		"extra-cycle", "free-cycle":
			return ["klondike", "pyramid"].has(type)
		"reveal-all":
			# Acts on the tableau's face-down cards — Klondike and Spider only.
			return ["klondike", "spider"].has(type)
		"flip-card":
			# Brass Compass reveals a hidden card: a face-down tableau card in
			# Klondike/Spider, or a covered pyramid card in TriPeaks.
			return ["klondike", "spider", "tripeaks"].has(type)
		"ace-to-found":
			return ["klondike", "freecell"].has(type)
		"extra-freecell":
			return type == "freecell"
		"broom":
			return ["klondike", "spider", "freecell"].has(type)
		"choose-from-stock":
			return ["klondike", "tripeaks"].has(type)
		"retrieve-waste":
			return ["klondike", "tripeaks", "pyramid"].has(type)
		"peek":
			return ["klondike", "spider", "tripeaks", "pyramid"].has(type)
		"draw-bottom", "read-stock":
			# The three variants with a single draw pile. Spider's stock is dealt
			# in rows of ten and has no bottom card to speak of.
			return ["klondike", "tripeaks", "pyramid"].has(type)
		"queens-to-hand":
			# Only where a Queen has somewhere to be held: Klondike's waste and
			# FreeCell's free cells.
			return ["klondike", "freecell"].has(type)
		"purge-rank":
			# Klondike, FreeCell and Spider need every rank to finish — a purged
			# rank would leave the floor unwinnable. Pyramid and TriPeaks only ask
			# for the board to be cleared.
			return ["pyramid", "tripeaks"].has(type)
	# hint, hint-all, extra-undos, big-undo, remove-card, toolbox,
	# no-life-abandon, skip-floor, mark-rank, swap-cards, free-reshuffle,
	# queens-wild — usable in every variant.
	return true


## Copies the floor-long flags from one game state onto another. Used wherever
## RunState swaps the whole board out (undo, the Hourglass rewind, a re-deal).
static func carry_floor_flags(from: Dictionary, to: Dictionary) -> void:
	for key in CARRIED_FLAGS:
		if from.has(key):
			to[key] = from[key].duplicate() if from[key] is Array else from[key]


## Runs an item. Mutates RunState where the effect is immediate.
static func activate(item: Dictionary, inv_index: int) -> Dictionary:
	var type: String = RunState.gtype
	var gs: Dictionary = RunState.gs
	if gs.is_empty():
		return _result(false, "No game in progress.")

	match String(item["effect"]):
		"hint":
			var found := Hints.find(gs, false)
			if found.is_empty():
				return _result(false, "No valid moves found!")
			var r := _result(true)
			r["timed"] = {"kind": "hints", "hints": found, "seconds": HINT_SECONDS}
			return r

		"hint-all":
			var found := Hints.find(gs, true)
			if found.is_empty():
				return _result(false, "No valid moves found!")
			var r := _result(true)
			r["timed"] = {"kind": "hints", "hints": found, "seconds": HINT_ALL_SECONDS}
			return r

		"extra-undos":
			RunState.bonus_undos += BONUS_UNDOS
			return _result(true, "+%d undos added!" % BONUS_UNDOS)

		"free-draw":
			if not ["klondike", "tripeaks", "pyramid"].has(type):
				return _result(false, "Not useful in this game!")
			RunState.push_undo()
			match type:
				"klondike": RunState.gs = Rules.klondike_draw(gs)
				"tripeaks": RunState.gs = Rules.tripeaks_draw(gs)
				"pyramid": RunState.gs = Rules.pyramid_draw(gs)
			return _result(true, "Free draw.")

		"peek":
			var stock: Array = gs.get("stock", [])
			if stock.is_empty():
				return _result(false, "Stock is empty!")
			# Top of stock is the end of the array for Klondike/Pyramid (pop_back)
			# and the front for TriPeaks (pop_front).
			var top3 := []
			if type == "tripeaks":
				for i in mini(3, stock.size()):
					top3.append(stock[i])
			else:
				for i in range(stock.size() - 1, maxi(-1, stock.size() - 4), -1):
					top3.append(stock[i])
			var r := _result(true)
			r["timed"] = {"kind": "peek", "cards": top3, "seconds": PEEK_SECONDS}
			return r

		"extra-cycle":
			var s := Cards.clone_state(gs)
			match type:
				"klondike":
					s["draws_left"] = mini(int(s["draws_left"]) + 1, 999)
				"pyramid":
					s["max_cycles"] = int(s["max_cycles"]) + 1
				_:
					return _result(false, "Not useful in this game!")
			RunState.push_undo()
			RunState.gs = s
			return _result(true, "Free recycle added!")

		"free-cycle":
			if not ["klondike", "pyramid"].has(type):
				return _result(false, "Not useful in this game!")
			if gs["waste"].is_empty():
				return _result(false, "Waste is empty!")
			RunState.push_undo()
			var s := Cards.clone_state(gs)
			var recycled := []
			var waste: Array = s["waste"]
			for i in range(waste.size() - 1, -1, -1):
				var card: Dictionary = waste[i].duplicate()
				card["face_up"] = false
				recycled.append(card)
			# BUG FIX vs the web build, which assigned s.stock = reversed waste,
			# discarding whatever was still in the stock. Using this item on a
			# non-empty stock therefore deleted those cards outright and could
			# make a board unwinnable. The recycled waste goes underneath the
			# remaining stock instead, so all 52 cards survive and the existing
			# stock is still drawn first.
			var remaining: Array = s["stock"]
			recycled.append_array(remaining)
			s["stock"] = recycled
			s["waste"] = []
			RunState.gs = s
			return _result(true, "Waste recycled!")

		"reveal-all":
			var s := Cards.clone_state(gs)
			if not s.has("tableau"):
				return _result(false, "Nothing hidden in this game!")
			# Remember which cards were genuinely face-down so only those are
			# hidden again when the timer expires.
			var hidden := []
			for c in s["tableau"].size():
				for i in s["tableau"][c].size():
					if not s["tableau"][c][i]["face_up"]:
						s["tableau"][c][i]["face_up"] = true
						hidden.append([c, i])
			if hidden.is_empty():
				return _result(false, "Nothing is face-down!")
			RunState.gs = s
			var r := _result(true)
			r["timed"] = {"kind": "reveal", "hidden": hidden, "seconds": REVEAL_SECONDS}
			return r

		"ace-to-found":
			return _ace_to_foundation(type, gs)

		"big-undo":
			if RunState.undo_stack.is_empty():
				return _result(false, "Nothing to undo!")
			var steps := 0
			var now: Dictionary = RunState.gs
			while steps < BIG_UNDO_STEPS and not RunState.undo_stack.is_empty():
				var prev: Dictionary = RunState.undo_stack.pop_back()
				RunState.gs = prev["gs"]
				carry_floor_flags(now, RunState.gs)
				RunState.moves = int(prev["moves"])
				RunState.score = int(prev["score"])
				RunState.tp_streak = int(prev.get("tp_streak", 0))
				steps += 1
			RunState.win_overlay = false
			return _result(true, "Rewound %d moves!" % steps)

		"extra-freecell":
			if type != "freecell":
				return _result(false, "Only works in FreeCell!")
			if gs["freecells"].size() >= 5:
				return _result(false, "Already have 5 free cells!")
			var s := Cards.clone_state(gs)
			s["freecells"].append(null)
			RunState.gs = s
			RunState.extra_freecell = true
			return _result(true, "5th free cell unlocked!")

		"toolbox":
			if RunState.toolbox_uses > 0 or RunState.toolbox_card != null:
				return _result(false, "Toolbox already active!")
			RunState.toolbox_uses = TOOLBOX_USES
			return _result(true, "Toolbox stash ready — click a card to store it.")

		"remove-card":
			var r := _result(false)
			r["mode"] = {"effect": "remove-card", "inv_index": inv_index, "icon": "🗡️",
				"banner": "ATHAME: click any face-up card to remove it from play"}
			return r

		"flip-card":
			var r := _result(false)
			r["mode"] = {"effect": "flip-card", "inv_index": inv_index, "icon": "🧭",
				"banner": "BRASS COMPASS: click any face-down card to flip it"}
			return r

		"broom":
			if not gs.has("tableau"):
				return _result(false, "Not useful in this game!")
			var has_empty := false
			for pile in gs["tableau"]:
				if pile.is_empty():
					has_empty = true
			if not has_empty:
				return _result(false, "No empty column to sweep to!")
			var r := _result(false)
			r["mode"] = {"effect": "broom", "inv_index": inv_index, "icon": "🧹",
				"banner": "ANGELIC BESOM: click a pile's top card to sweep it to an empty column"}
			return r

		"retrieve-waste":
			var waste: Array = gs.get("waste", [])
			if waste.size() <= 1:
				return _result(false, "Nothing useful in waste!")
			# Everything except the card already on top, most recent first.
			var options := []
			for i in range(waste.size() - 2, -1, -1):
				options.append(waste[i])
			var r := _result(false)
			r["picker"] = {"effect": "retrieve-waste", "inv_index": inv_index,
				"title": "HERMETIC CASKET — pick a card from the waste", "cards": options}
			return r

		"choose-from-stock":
			if not ["klondike", "tripeaks"].has(type):
				return _result(false, "Not useful in this game!")
			var stock: Array = gs.get("stock", [])
			if stock.is_empty():
				return _result(false, "Stock is empty!")
			var r := _result(false)
			r["picker"] = {"effect": "choose-from-stock", "inv_index": inv_index,
				"title": "ENOCHIAN KEY — pick any card from the stock", "cards": stock.duplicate()}
			return r

		"no-life-abandon":
			# Handled by RunState.abandon_floor, which looks for this item and
			# consumes it rather than spending a life.
			RunState.abandon_floor()
			return _result(false, "Retreated without penalty.")

		"skip-floor":
			# The Executive Chair auto-clears the floor: it raises the floor-clear
			# overlay just like a real win (web skip-floor calls handleWin), and the
			# floor-clear bonus and routing happen when the player descends.
			RunState.win_overlay = true
			var r := _result(true, "Floor skipped!")
			r["win"] = true
			return r

		# ── Mary Stuart ──────────────────────────────────────────────────────

		"mark-rank":
			var r := _result(false)
			r["picker"] = {"effect": "mark-rank", "inv_index": inv_index, "ranks": true,
				"title": "NOMENCLATOR DISC — name a rank to mark", "cards": _rank_cards()}
			return r

		"draw-bottom":
			return _draw_bottom(type, gs)

		"read-stock":
			if not usable_in("read-stock", type):
				return _result(false, "Not useful in this game!")
			if bool(gs.get("ledger", false)):
				return _result(false, "The Ledger is already open!")
			if (gs.get("stock", []) as Array).is_empty():
				return _result(false, "Stock is empty!")
			var s := Cards.clone_state(gs)
			s["ledger"] = true
			RunState.gs = s
			return _result(true, "The stock lies open, in order.")

		"swap-cards":
			var r := _result(false)
			r["mode"] = {"effect": "swap-cards", "inv_index": inv_index, "icon": "🧥",
				"banner": "LAUNDRESS'S CLOAK: click the first face-up card to swap"}
			return r

		"queens-to-hand":
			return _queens_to_hand(type, gs)

		"purge-rank":
			if not usable_in("purge-rank", type):
				return _result(false, "Not useful in this game!")
			var r := _result(false)
			r["picker"] = {"effect": "purge-rank", "inv_index": inv_index, "ranks": true,
				"title": "FOTHERINGHAY BLOCK — name the rank to send to the block",
				"cards": _rank_cards()}
			return r

		"free-reshuffle":
			# The Lochleven Deed: the same floor, a fresh deal, and no life spent.
			RunState.new_shuffle(true)
			return _result(true, "The floor is dealt anew.")

		"queens-wild":
			if Rules.queens_wild(gs):
				return _result(false, "The Queens are already free!")
			var s := Cards.clone_state(gs)
			s["queens_wild"] = true
			RunState.gs = s
			return _result(true, "Every Queen answers to no rule.")

	return _result(false, "That item does nothing here.")


## One stand-in card per rank, Ace to King, for the rank pickers.
static func _rank_cards() -> Array:
	var out := []
	for rank in range(1, 14):
		out.append({"suit": 0, "rank": rank, "face_up": true})
	return out


## The Chartley Ale Cask: one card from the BOTTOM of the stock onto the waste.
## Klondike and Pyramid draw from the end of the stock array, TriPeaks from the
## front, so the bottom is the opposite end in each.
static func _draw_bottom(type: String, gs: Dictionary) -> Dictionary:
	if not usable_in("draw-bottom", type):
		return _result(false, "Not useful in this game!")
	if (gs.get("stock", []) as Array).is_empty():
		return _result(false, "Stock is empty!")
	RunState.push_undo()
	var s := Cards.clone_state(gs)
	var stock: Array = s["stock"]
	var card: Dictionary = stock.pop_back() if type == "tripeaks" else stock.pop_front()
	card["face_up"] = true
	s["waste"].append(card)
	RunState.gs = s
	return _result(true, "Drawn from the bottom of the stock.")


## The Black Pearls: every Queen not already on a foundation is dug out —
## buried in the tableau, face-down, in the stock or the waste — and put where it
## can be played. In Klondike that is the top of the waste, all of them, the
## last one playable at once and the rest as each is used. In FreeCell it is the
## free cells, most deeply buried Queen first, as many as there are empty cells.
static func _queens_to_hand(type: String, gs: Dictionary) -> Dictionary:
	if not usable_in("queens-to-hand", type):
		return _result(false, "Not useful in this game!")
	var s := Cards.clone_state(gs)

	# Every Queen the item can reach, with how deep it lies so FreeCell can take
	# the hardest ones first. Depth is the number of cards resting on it.
	var found := []
	for c in s["tableau"].size():
		var pile: Array = s["tableau"][c]
		for i in pile.size():
			if int(pile[i]["rank"]) == Rules.RANK_QUEEN:
				found.append({"where": "tableau", "col": c, "card": pile[i],
					"depth": pile.size() - 1 - i})
	if type == "klondike":
		for card in s["stock"]:
			if int(card["rank"]) == Rules.RANK_QUEEN:
				found.append({"where": "stock", "card": card, "depth": 99})
		# Queens already stacked on top of the waste are in hand: leave them be,
		# or a second string of Pearls would "gather" nothing and still be spent.
		var waste: Array = s["waste"]
		var in_hand := 0
		while in_hand < waste.size() \
				and int(waste[waste.size() - 1 - in_hand]["rank"]) == Rules.RANK_QUEEN:
			in_hand += 1
		for i in waste.size() - in_hand:
			if int(waste[i]["rank"]) == Rules.RANK_QUEEN:
				found.append({"where": "waste", "card": waste[i], "depth": 99})

	if found.is_empty():
		return _result(false, "No Queen left to gather!")
	if type == "freecell":
		var empty := 0
		for c in s["freecells"]:
			if c == null:
				empty += 1
		if empty == 0:
			return _result(false, "No free cell to hold them!")
		found.sort_custom(func(a, b): return int(a["depth"]) > int(b["depth"]))
		found = found.slice(0, empty)

	RunState.push_undo()
	var gathered := []
	for f in found:
		var card: Dictionary = f["card"]
		if String(f["where"]) == "tableau":
			(s["tableau"][int(f["col"])] as Array).erase(card)
		else:
			(s[f["where"]] as Array).erase(card)
		card["face_up"] = true
		gathered.append(card)

	if type == "klondike":
		for card in gathered:
			s["waste"].append(card)
	else:
		var cell := 0
		for card in gathered:
			while s["freecells"][cell] != null:
				cell += 1
			s["freecells"][cell] = card

	RunState.gs = s
	if type == "klondike":
		# Taking a Queen out from under a pile can leave a face-down top.
		for revealed in Rules.klondike_auto_reveal(s):
			RunState.award_card_points(revealed, Rules.PTS_REVEAL)
	if gathered.size() == 1:
		return _result(true, "A Queen comes to hand.")
	return _result(true, "%d Queens come to hand." % gathered.size())


## Digs the first Ace out of anywhere on the board and sends it to its
## foundation — buried in a tableau pile, sitting in the waste or a free cell, or
## still face-down in the stock. Only Klondike and FreeCell have suit
## foundations, so the item does nothing in the other variants.
static func _ace_to_foundation(type: String, gs: Dictionary) -> Dictionary:
	if not ["klondike", "freecell"].has(type):
		return _result(false, "Not useful in this game!")

	var s := Cards.clone_state(gs)
	var foundations: Array = s["foundations"]

	# Every card the item is allowed to reach, tableau (all depths) first, then
	# the holding areas, then the face-down stock in Klondike.
	var zones := []
	for c in s["tableau"].size():
		var pile: Array = s["tableau"][c]
		for i in pile.size():
			zones.append({"where": "tableau", "col": c, "index": i, "card": pile[i]})
	if type == "klondike":
		for i in s["waste"].size():
			zones.append({"where": "waste", "index": i, "card": s["waste"][i]})
		for i in s["stock"].size():
			zones.append({"where": "stock", "index": i, "card": s["stock"][i]})
	else:
		for c in s["freecells"].size():
			if s["freecells"][c] != null:
				zones.append({"where": "freecell", "col": c, "card": s["freecells"][c]})

	for z in zones:
		var card: Dictionary = z["card"]
		if int(card["rank"]) != Cards.RANK_ACE:
			continue
		var placeable := (Rules.klondike_can_foundation(card, foundations) if type == "klondike"
			else Rules.freecell_can_foundation(card, foundations))
		if not placeable:
			continue

		# Pull it out of wherever it sat, exposing the card beneath a tableau slot.
		match String(z["where"]):
			"tableau":
				var pile: Array = s["tableau"][z["col"]]
				pile.remove_at(int(z["index"]))
				if not pile.is_empty():
					pile[pile.size() - 1]["face_up"] = true
			"waste":
				s["waste"].remove_at(int(z["index"]))
			"stock":
				s["stock"].remove_at(int(z["index"]))
			"freecell":
				s["freecells"][z["col"]] = null

		var ace: Dictionary = card.duplicate()
		ace["face_up"] = true
		foundations[int(card["suit"])].append(ace)
		RunState.push_undo()
		RunState.gs = s
		if type == "klondike":
			# klondike_auto_reveal flips and scores any newly exposed tops.
			for revealed in Rules.klondike_auto_reveal(s):
				RunState.award_card_points(revealed, Rules.PTS_REVEAL)
			RunState.add_score(15, "ace to foundation")
			RunState.award_progress_gold()
		else:
			RunState.add_score(5, "ace to foundation")
		return _result(true, "Ace sent to its foundation.")

	return _result(false, "No Ace available!")


# ══════════════════════════════════════════════════════════════════════════════
#  Second-click resolution
# ══════════════════════════════════════════════════════════════════════════════

## Applies an armed click-targeting mode to the clicked slot.
## `slot` uses the board's meta format: {"kind", "col", "index"}.
static func resolve_mode(mode: Dictionary, slot: Dictionary) -> Dictionary:
	var gs: Dictionary = RunState.gs
	var kind: String = slot.get("kind", "")

	match String(mode["effect"]):
		"remove-card":
			var card = _card_at(gs, slot)
			if card == null:
				return _result(false, "Nothing there to remove.")
			if not bool(card.get("face_up", false)):
				return _result(false, "Can only remove face-up cards!")
			RunState.push_undo()
			RunState.gs = _remove_card_at(gs, slot)
			RunState.moves += 1
			return _result(true, "Card removed from play.")

		"flip-card":
			# TriPeaks: reveal a covered (face-down) card in the pyramid.
			if kind == "pyramid" and String(gs.get("type", "")) == "tripeaks":
				var peak: Array = gs["pyramid"]
				var pidx := int(slot.get("index", -1))
				if pidx < 0 or pidx >= peak.size() or peak[pidx] == null:
					return _result(false, "Nothing there to flip.")
				if peak[pidx]["face_up"]:
					return _result(false, "Card is already face-up!")
				RunState.push_undo()
				var ps := Cards.clone_state(gs)
				ps["pyramid"][pidx]["face_up"] = true
				RunState.gs = ps
				return _result(true, "Card flipped.")
			if kind != "tableau":
				return _result(false, "Click a face-down card!")
			var pile: Array = gs["tableau"][slot["col"]]
			var idx := int(slot.get("index", -1))
			if idx < 0 or idx >= pile.size():
				return _result(false, "Nothing there to flip.")
			if pile[idx]["face_up"]:
				return _result(false, "Card is already face-up!")
			RunState.push_undo()
			var s := Cards.clone_state(gs)
			s["tableau"][slot["col"]][idx]["face_up"] = true
			RunState.gs = s
			return _result(true, "Card flipped.")

		"broom":
			if kind != "tableau":
				return _result(false, "Click the top card of a pile!")
			var col := int(slot["col"])
			var pile: Array = gs["tableau"][col]
			if pile.is_empty():
				return _result(false, "No card to sweep here!")
			var top: Dictionary = pile[pile.size() - 1]
			if not top["face_up"]:
				return _result(false, "Card must be face-up!")
			var target := -1
			for i in gs["tableau"].size():
				if i != col and gs["tableau"][i].is_empty():
					target = i
					break
			if target < 0:
				return _result(false, "No empty column found!")
			RunState.push_undo()
			var s := Cards.clone_state(gs)
			var moved: Dictionary = s["tableau"][col].pop_back()
			s["tableau"][target].append(moved)
			if not s["tableau"][col].is_empty():
				s["tableau"][col][s["tableau"][col].size() - 1]["face_up"] = true
			RunState.gs = s
			RunState.moves += 1
			return _result(true, "Swept to the empty column.")

		"swap-cards":
			return _swap_click(mode, slot)

	return _result(false, "")


## The Laundress's Cloak takes two clicks. The first is checked and recorded in a
## re-armed copy of the mode (returned unconsumed, so the board keeps the item);
## the second makes the swap.
static func _swap_click(mode: Dictionary, slot: Dictionary) -> Dictionary:
	var gs: Dictionary = RunState.gs
	if not _swappable(slot):
		return _result(false, "Click a face-up card on the board!")
	var card = _card_at(gs, slot)
	if card == null or not bool(card.get("face_up", false)):
		return _result(false, "Can only swap face-up cards!")

	if not mode.has("first"):
		var r := _result(false)
		var next := mode.duplicate()
		next["first"] = slot.duplicate()
		next["banner"] = "LAUNDRESS'S CLOAK: now click the card to trade places with it"
		r["mode"] = next
		return r

	var first: Dictionary = mode["first"]
	if _same_slot(first, slot):
		return _result(false, "Pick a different card!")
	if _card_at(gs, first) == null:
		return _result(false, "Nothing there to swap.")

	RunState.push_undo()
	var s := Cards.clone_state(gs)
	var a: Dictionary = _card_at(s, first)
	var b: Dictionary = _card_at(s, slot)
	_put_card_at(s, first, b)
	_put_card_at(s, slot, a)
	RunState.gs = s
	RunState.moves += 1
	return _result(true, "The two cards trade places.")


## Board cards the Cloak can reach. Foundations and the stock are not "on the
## board": a foundation is built in order and the stock is face-down.
static func _swappable(slot: Dictionary) -> bool:
	return ["tableau", "waste", "freecell", "pyramid"].has(String(slot.get("kind", "")))


static func _same_slot(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("kind", "")) == String(b.get("kind", "")) \
		and int(a.get("col", -1)) == int(b.get("col", -1)) \
		and int(a.get("index", -1)) == int(b.get("index", -1)) \
		and int(a.get("windex", -1)) == int(b.get("windex", -1))


## Writes `card` into the slot `_card_at` reads from.
static func _put_card_at(s: Dictionary, slot: Dictionary, card: Dictionary) -> void:
	match String(slot.get("kind", "")):
		"tableau":
			var pile: Array = s["tableau"][slot["col"]]
			pile[int(slot.get("index", pile.size() - 1))] = card
		"waste":
			var w: Array = s["waste"]
			w[_waste_index(w, slot)] = card
		"freecell":
			s["freecells"][slot["col"]] = card
		"pyramid":
			s["pyramid"][int(slot["index"])] = card


## Which waste card a slot means: Pyramid's two draw spots name theirs with
## `windex`; everywhere else only the top of the waste is in play.
static func _waste_index(waste: Array, slot: Dictionary) -> int:
	var wi := int(slot.get("windex", waste.size() - 1))
	return clampi(wi, 0, waste.size() - 1)


## Applies a picker choice.
static func resolve_picker(picker: Dictionary, card: Dictionary) -> Dictionary:
	var s := Cards.clone_state(RunState.gs)

	match String(picker["effect"]):
		"retrieve-waste":
			var idx := _find_card(s["waste"], card)
			if idx < 0:
				return _result(false, "That card is no longer in the waste.")
			RunState.push_undo()
			var moved: Dictionary = s["waste"][idx]
			s["waste"].remove_at(idx)
			moved["face_up"] = true
			s["waste"].append(moved)
			RunState.gs = s
			return _result(true, "Card brought to the top.")

		"choose-from-stock":
			var idx := _find_card(s["stock"], card)
			if idx < 0:
				return _result(false, "That card is no longer in the stock.")
			RunState.push_undo()
			var moved: Dictionary = s["stock"][idx]
			s["stock"].remove_at(idx)
			moved["face_up"] = true
			s["waste"].append(moved)
			RunState.gs = s
			return _result(true, "Card pulled from the stock.")

		"mark-rank":
			var rank := int(card["rank"])
			var marked: Array = s.get("marked_ranks", [])
			if marked.has(rank):
				return _result(false, "That rank is already marked.")
			marked.append(rank)
			s["marked_ranks"] = marked
			RunState.gs = s
			return _result(true, "Every %s is marked." % Cards.RANK_NAMES[rank])

		"purge-rank":
			return _purge_rank(s, int(card["rank"]))

	return _result(false, "")


## The Fotheringhay Block: all four cards of a rank leave the floor — the
## board, the stock and the waste — for good.
##
## Pyramid and TriPeaks are the only variants it is sold for (see usable_in),
## and each needs one adjustment so the purge cannot strand the floor:
##   Pyramid   the purged rank's partner (13 − rank) has nothing left to pair
##             with, so it is added to `lone_ranks` and clears alone, like a King.
##   TriPeaks  the purged rank drops out of the rank ring (tripeaks_can_play), so
##             the ranks either side of it become neighbours.
static func _purge_rank(s: Dictionary, rank: int) -> Dictionary:
	var removed := 0
	var pyramid: Array = s.get("pyramid", [])
	for i in pyramid.size():
		if pyramid[i] != null and int(pyramid[i]["rank"]) == rank:
			pyramid[i] = null
			removed += 1
	for z in ["stock", "waste"]:
		var pile: Array = s.get(z, [])
		for i in range(pile.size() - 1, -1, -1):
			if int(pile[i]["rank"]) == rank:
				pile.remove_at(i)
				removed += 1
	if removed == 0:
		return _result(false, "No card of that rank is left.")

	RunState.push_undo()
	var purged: Array = s.get("purged_ranks", [])
	if not purged.has(rank):
		purged.append(rank)
	s["purged_ranks"] = purged
	if String(s.get("type", "")) == "pyramid":
		var partner := 13 - rank
		if partner >= 1:
			var lone: Array = s.get("lone_ranks", [])
			if not lone.has(partner):
				lone.append(partner)
			s["lone_ranks"] = lone
	else:
		Rules.tripeaks_update_face_up(pyramid)
	RunState.gs = s
	return _result(true, "Every %s goes to the block." % Cards.RANK_NAMES[rank])


static func _find_card(pile: Array, card: Dictionary) -> int:
	for i in pile.size():
		if int(pile[i]["suit"]) == int(card["suit"]) and int(pile[i]["rank"]) == int(card["rank"]):
			return i
	return -1


static func _card_at(gs: Dictionary, slot: Dictionary):
	match String(slot.get("kind", "")):
		"tableau":
			var pile: Array = gs["tableau"][slot["col"]]
			var idx := int(slot.get("index", pile.size() - 1))
			if idx < 0 or idx >= pile.size():
				return null
			return pile[idx]
		"waste":
			if gs["waste"].is_empty():
				return null
			return gs["waste"][_waste_index(gs["waste"], slot)]
		"freecell":
			return gs["freecells"][slot["col"]]
		"pyramid":
			return gs["pyramid"][int(slot["index"])]
	return null


static func _remove_card_at(gs: Dictionary, slot: Dictionary) -> Dictionary:
	var s := Cards.clone_state(gs)
	match String(slot.get("kind", "")):
		"tableau":
			var pile: Array = s["tableau"][slot["col"]]
			pile.remove_at(int(slot.get("index", pile.size() - 1)))
			if not pile.is_empty():
				pile[pile.size() - 1]["face_up"] = true
		"waste":
			s["waste"].pop_back()
		"freecell":
			s["freecells"][slot["col"]] = null
		"pyramid":
			s["pyramid"][int(slot["index"])] = null
			if s["type"] == "tripeaks":
				Rules.tripeaks_update_face_up(s["pyramid"])
	return s
