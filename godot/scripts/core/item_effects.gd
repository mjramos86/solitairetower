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

const HINT_SECONDS := 5.0
const HINT_ALL_SECONDS := 8.0
const REVEAL_SECONDS := 8.0
const PEEK_SECONDS := 6.0

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
		"reveal-all", "flip-card":
			# Both act on face-down cards, which only Klondike and Spider deal.
			return ["klondike", "spider"].has(type)
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
	# hint, hint-all, extra-undos, big-undo, remove-card, toolbox,
	# no-life-abandon, skip-floor — usable in every variant.
	return true


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
			while steps < BIG_UNDO_STEPS and not RunState.undo_stack.is_empty():
				var prev: Dictionary = RunState.undo_stack.pop_back()
				RunState.gs = prev["gs"]
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

	return _result(false, "That item does nothing here.")


## Sends the first available Ace to its foundation. Klondike checks tableau tops
## then the waste; FreeCell checks tableau tops then the free cells.
static func _ace_to_foundation(type: String, gs: Dictionary) -> Dictionary:
	var s := Cards.clone_state(gs)

	if type == "klondike":
		for c in 7:
			var pile: Array = s["tableau"][c]
			if pile.is_empty():
				continue
			var top: Dictionary = pile[pile.size() - 1]
			if top["face_up"] and int(top["rank"]) == Cards.RANK_ACE \
					and Rules.klondike_can_foundation(top, s["foundations"]):
				pile.pop_back()
				s["foundations"][top["suit"]].append(top)
				RunState.push_undo()
				RunState.gs = s
				# klAutoReveal both flips and scores the exposed card, as in the web.
				for revealed in Rules.klondike_auto_reveal(s):
					RunState.award_card_points(revealed, Rules.PTS_REVEAL)
				RunState.add_score(15, "ace to foundation")
				return _result(true, "Ace sent to its foundation.")
		if not s["waste"].is_empty():
			var wtop: Dictionary = s["waste"][s["waste"].size() - 1]
			if int(wtop["rank"]) == Cards.RANK_ACE \
					and Rules.klondike_can_foundation(wtop, s["foundations"]):
				s["waste"].pop_back()
				s["foundations"][wtop["suit"]].append(wtop)
				RunState.push_undo()
				RunState.gs = s
				RunState.add_score(15, "ace to foundation")
				return _result(true, "Ace sent to its foundation.")

	elif type == "freecell":
		for c in 8:
			var pile: Array = s["tableau"][c]
			if pile.is_empty():
				continue
			var top: Dictionary = pile[pile.size() - 1]
			if int(top["rank"]) == Cards.RANK_ACE \
					and Rules.freecell_can_foundation(top, s["foundations"]):
				pile.pop_back()
				s["foundations"][top["suit"]].append(top)
				RunState.push_undo()
				RunState.gs = s
				RunState.add_score(5, "ace to foundation")
				return _result(true, "Ace sent to its foundation.")
		for c in s["freecells"].size():
			var card = s["freecells"][c]
			if card != null and int(card["rank"]) == Cards.RANK_ACE \
					and Rules.freecell_can_foundation(card, s["foundations"]):
				s["freecells"][c] = null
				s["foundations"][card["suit"]].append(card)
				RunState.push_undo()
				RunState.gs = s
				RunState.add_score(5, "ace to foundation")
				return _result(true, "Ace sent to its foundation.")
	else:
		return _result(false, "Not useful in this game!")

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
			if kind != "tableau":
				return _result(false, "Click a face-down tableau card!")
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

	return _result(false, "")


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

	return _result(false, "")


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
			return gs["waste"][gs["waste"].size() - 1]
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
