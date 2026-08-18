class_name Rules
extends RefCounted

## Rules for all five solitaire variants, ported from index.html.
##
## Every function here is pure: it takes a state Dictionary and returns either a
## fact about it or a new state. Nothing touches UI, audio or global run state,
## which is what makes the whole ruleset testable headlessly.
##
## Scoring is deliberately *not* applied here. Moves report which scoring events
## they triggered and RunState awards the points, so the rules stay pure and the
## score ledger stays in one place.

const MAX_CARD_POINTS := 20

## Points awarded per event, from klondike.md (Klondike) and the per-variant
## handlers in index.html.
##
## Klondike is the only variant scored through the 20-point-per-card ledger
## (award_card_points); the others award flat amounts via add_score:
##   FreeCell   +5 for any card sent to a foundation
##   TriPeaks   the running streak length per peak card, +15 for a top card
##   Pyramid    +10 for any pair summing to 13, +5 for a King cleared alone
const PTS_WASTE_TO_TABLEAU := 5
const PTS_REVEAL := 5
const PTS_FOUNDATION := 20
const PTS_SUIT_COMPLETED := 100
const PTS_FREECELL_FOUNDATION := 5
const PTS_TRIPEAKS_PEAK := 15
const PTS_PYRAMID_PAIR := 10
const PTS_PYRAMID_KING := 5


## Difficulty band for a floor index (0 = floor 10, 9 = floor 1).
static func difficulty(floor_index: int) -> String:
	if floor_index <= 3:
		return "easy"
	if floor_index <= 6:
		return "medium"
	return "hard"


# ══════════════════════════════════════════════════════════════════════════════
#  KLONDIKE
# ══════════════════════════════════════════════════════════════════════════════

static func build_klondike_deal(deck: Array, floor_index: int) -> Dictionary:
	var diff := difficulty(floor_index)
	var tableau := []
	var idx := 0
	for c in 7:
		var pile := []
		for r in range(c + 1):
			var card: Dictionary = deck[idx].duplicate()
			card["face_up"] = (r == c)
			pile.append(card)
			idx += 1
		tableau.append(pile)
	var stock := []
	for i in range(idx, deck.size()):
		var card: Dictionary = deck[i].duplicate()
		card["face_up"] = false
		stock.append(card)
	return {
		"type": "klondike",
		"tableau": tableau,
		"stock": stock,
		"waste": [],
		"foundations": [[], [], [], []],
		"draw_count": 1 if diff == "easy" else 3,
		"draws_left": 3 if diff == "hard" else 999,
		"floor": floor_index,
		"card_points": {},
	}


## Easy floors guarantee a winnable deal by test-solving with a greedy player,
## retrying up to 25 shuffles. Ported from initKlondike.
static func init_klondike(floor_index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = Cards.new_rng()
	var easy := difficulty(floor_index) == "easy"
	var state := {}
	for attempt in 25:
		state = build_klondike_deal(Cards.shuffle(Cards.make_deck(), rng), floor_index)
		if not easy or klondike_greedy_solvable(state):
			return state
	return state


static func klondike_can_foundation(card: Dictionary, foundations: Array) -> bool:
	var f: Array = foundations[card["suit"]]
	if f.is_empty():
		return card["rank"] == Cards.RANK_ACE
	return f[f.size() - 1]["rank"] == card["rank"] - 1


static func klondike_can_tableau(cards: Array, target: Array) -> bool:
	if cards.is_empty():
		return false
	var moving: Dictionary = cards[0]
	if target.is_empty():
		return moving["rank"] == Cards.RANK_KING
	var top: Dictionary = target[target.size() - 1]
	if not top["face_up"]:
		return false
	return top["rank"] == moving["rank"] + 1 \
		and Cards.is_red(top["suit"]) != Cards.is_red(moving["suit"])


static func klondike_won(state: Dictionary) -> bool:
	for f in state["foundations"]:
		if f.size() != 13:
			return false
	return true


static func klondike_draw(state: Dictionary) -> Dictionary:
	var s := Cards.clone_state(state)
	if s["stock"].is_empty():
		if s["draws_left"] <= 0:
			return s
		var recycled := []
		var waste: Array = s["waste"]
		for i in range(waste.size() - 1, -1, -1):
			var card: Dictionary = waste[i].duplicate()
			card["face_up"] = false
			recycled.append(card)
		s["stock"] = recycled
		s["waste"] = []
		s["draws_left"] = int(s["draws_left"]) - 1
		return s
	for i in int(s["draw_count"]):
		if s["stock"].is_empty():
			break
		var card: Dictionary = s["stock"].pop_back()
		card["face_up"] = true
		s["waste"].append(card)
	return s


## Flips any face-down tableau top. Returns the cards revealed so the caller can
## award reveal points; pass silent=true during solvability testing.
static func klondike_auto_reveal(state: Dictionary) -> Array:
	var revealed := []
	for col in state["tableau"]:
		if col.size() > 0 and not col[col.size() - 1]["face_up"]:
			col[col.size() - 1]["face_up"] = true
			revealed.append(col[col.size() - 1])
	return revealed


## Greedy auto-player used to reject unwinnable easy deals. Plays every forced
## foundation move, then a tableau move, then a waste move, then draws.
##
## DEVIATION FROM THE WEB BUILD, deliberate. The original klGreedySolvable
## considered only tableau-to-tableau moves onto non-empty columns: it never
## played from the waste and never used an empty column. Measured against 200
## deals that solver succeeds 0% of the time, so initKlondike's "guarantee" that
## easy floors are winnable never held — it burned 25 shuffles (1.34 s of frozen
## UI per deal) and returned the last one regardless.
##
## Adding the two missing move types makes the check do what it was evidently
## written to do, and makes it fast because it now succeeds early instead of
## exhausting every attempt. To restore the original behaviour exactly, delete
## the waste-to-tableau block and the empty-column case below.
static func klondike_greedy_solvable(state: Dictionary) -> bool:
	var s := Cards.clone_state(state)
	for iter in 600:
		if klondike_won(s):
			return true
		var moved := false
		var again := true
		while again:
			again = false
			for c in 7:
				var pile: Array = s["tableau"][c]
				if pile.is_empty():
					continue
				var top: Dictionary = pile[pile.size() - 1]
				if top["face_up"] and klondike_can_foundation(top, s["foundations"]):
					pile.pop_back()
					s["foundations"][top["suit"]].append(top)
					klondike_auto_reveal(s)
					again = true
					moved = true
			if not s["waste"].is_empty():
				var wtop: Dictionary = s["waste"][s["waste"].size() - 1]
				if klondike_can_foundation(wtop, s["foundations"]):
					s["waste"].pop_back()
					s["foundations"][wtop["suit"]].append(wtop)
					again = true
					moved = true
		if moved:
			continue

		# Tableau-to-tableau: move the whole face-up run somewhere it fits.
		for sc in 7:
			if moved:
				break
			var sp: Array = s["tableau"][sc]
			if sp.is_empty():
				continue
			var si := sp.size() - 1
			while si > 0 and sp[si]["face_up"]:
				si -= 1
			if not sp[si]["face_up"]:
				si += 1
			if si >= sp.size():
				continue
			var cards := sp.slice(si)
			if cards.is_empty() or not cards[0]["face_up"]:
				continue
			for dc in 7:
				if moved or dc == sc:
					continue
				# Moving a full column onto an empty one gains nothing, so only
				# take an empty column when it uncovers a face-down card.
				if s["tableau"][dc].is_empty() and si == 0:
					continue
				if klondike_can_tableau(cards, s["tableau"][dc]):
					for card in cards:
						s["tableau"][dc].append(card)
					s["tableau"][sc].resize(si)
					klondike_auto_reveal(s)
					moved = true
		if moved:
			continue

		# Waste-to-tableau. The original solver omitted this, which left it
		# unable to solve essentially any deal — see the note on this function.
		if not s["waste"].is_empty():
			var wtop: Dictionary = s["waste"][s["waste"].size() - 1]
			for dc in 7:
				if moved:
					break
				if klondike_can_tableau([wtop], s["tableau"][dc]):
					s["waste"].pop_back()
					s["tableau"][dc].append(wtop)
					moved = true
		if moved:
			continue

		var snapshot := "%d,%d" % [s["stock"].size(), s["waste"].size()]
		s = klondike_draw(s)
		if "%d,%d" % [s["stock"].size(), s["waste"].size()] == snapshot:
			break
	return klondike_won(s)


# ══════════════════════════════════════════════════════════════════════════════
#  SPIDER
# ══════════════════════════════════════════════════════════════════════════════

static func init_spider(floor_index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = Cards.new_rng()
	var diff := difficulty(floor_index)
	var suits := 1 if diff == "easy" else (2 if diff == "medium" else 4)
	var deck := []
	for copy in 8:
		for r in range(1, 14):
			var s := 0
			if suits == 2:
				s = 0 if copy < 4 else 3
			elif suits == 4:
				s = copy % 4
			deck.append(Cards.make_card(s, r))
	var sh := Cards.shuffle(deck, rng)
	var tableau := []
	var idx := 0
	for c in 10:
		var count := 6 if c < 4 else 5
		var pile := []
		for i in count:
			var card: Dictionary = sh[idx].duplicate()
			card["face_up"] = (i == count - 1)
			pile.append(card)
			idx += 1
		tableau.append(pile)
	var stock_groups := []
	while idx < sh.size():
		var group := []
		for i in range(idx, mini(idx + 10, sh.size())):
			var card: Dictionary = sh[i].duplicate()
			card["face_up"] = true
			group.append(card)
		stock_groups.append(group)
		idx += 10
	return {
		"type": "spider",
		"tableau": tableau,
		"stock_groups": stock_groups,
		"foundations": [],
		"suits": suits,
		"floor": floor_index,
		"card_points": {},
	}


## Length of the descending same-suit run ending at the top of the pile.
static func spider_sequence_length(pile: Array) -> int:
	if pile.is_empty():
		return 0
	var length := 1
	for i in range(pile.size() - 2, -1, -1):
		var upper: Dictionary = pile[i]
		var lower: Dictionary = pile[i + 1]
		if not upper["face_up"] or upper["rank"] != lower["rank"] + 1 or upper["suit"] != lower["suit"]:
			break
		length += 1
	return length


static func spider_can_drop(cards: Array, target: Array) -> bool:
	if cards.is_empty():
		return false
	if target.is_empty():
		return true
	var top: Dictionary = target[target.size() - 1]
	return top["face_up"] and top["rank"] == cards[0]["rank"] + 1


## Returns the completed suit, or -1 when the pile does not end in K..A.
static func spider_check_complete(pile: Array) -> int:
	if pile.size() < 13:
		return -1
	var top := pile.slice(pile.size() - 13)
	var suit: int = top[0]["suit"]
	for i in 13:
		if top[i]["suit"] != suit or top[i]["rank"] != 13 - i:
			return -1
	return suit


## Deals one row. Refuses while any column is empty, as the original does.
## Returns {"state":…, "completed":[suits]} so the caller can score.
static func spider_deal(state: Dictionary) -> Dictionary:
	if state["stock_groups"].is_empty():
		return {"state": state, "completed": []}
	for col in state["tableau"]:
		if col.is_empty():
			return {"state": state, "completed": []}
	var s := Cards.clone_state(state)
	var group: Array = s["stock_groups"].pop_front()
	for i in group.size():
		group[i]["face_up"] = true
		s["tableau"][i].append(group[i])
	var completed := []
	for c in 10:
		var suit := spider_check_complete(s["tableau"][c])
		if suit >= 0:
			var pile: Array = s["tableau"][c]
			pile.resize(pile.size() - 13)
			if not pile.is_empty():
				pile[pile.size() - 1]["face_up"] = true
			s["foundations"].append(suit)
			completed.append(suit)
	return {"state": s, "completed": completed}


static func spider_won(state: Dictionary) -> bool:
	return state["foundations"].size() >= 8


# ══════════════════════════════════════════════════════════════════════════════
#  TRIPEAKS
# ══════════════════════════════════════════════════════════════════════════════

## Which pyramid slots block each slot. Ported verbatim from TP_BLK.
const TP_BLOCKERS := {
	0: [3, 4], 1: [5, 6], 2: [7, 8],
	3: [9, 10], 4: [10, 11], 5: [12, 13], 6: [13, 14],
	7: [15, 16], 8: [16, 17],
	9: [18, 19], 10: [19, 20], 11: [20, 21], 12: [21, 22], 13: [22, 23],
	14: [23, 24], 15: [24, 25], 16: [25, 26], 17: [26, 27],
}

const TP_ROWS := [
	[0, 1, 2],
	[3, 4, 5, 6, 7, 8],
	[9, 10, 11, 12, 13, 14, 15, 16, 17],
	[18, 19, 20, 21, 22, 23, 24, 25, 26, 27],
]


static func init_tripeaks(floor_index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = Cards.new_rng()
	var deck := Cards.shuffle(Cards.make_deck(), rng)
	var pyramid := []
	for i in 28:
		var card: Dictionary = deck[i].duplicate()
		card["face_up"] = false
		pyramid.append(card)
	tripeaks_update_face_up(pyramid)
	var stock := []
	for i in range(28, deck.size()):
		var card: Dictionary = deck[i].duplicate()
		card["face_up"] = false
		stock.append(card)
	var waste := []
	if not stock.is_empty():
		var first: Dictionary = stock.pop_front()
		first["face_up"] = true
		waste.append(first)
	return {
		"type": "tripeaks",
		"pyramid": pyramid,
		"stock": stock,
		"waste": waste,
		"recycle": 0,
		"max_recycle": 1 if difficulty(floor_index) == "easy" else 0,
		"floor": floor_index,
		"card_points": {},
	}


## A slot is free when nothing rests on top of it. Removed cards are null.
static func tripeaks_free(pyramid: Array, idx: int) -> bool:
	if pyramid[idx] == null:
		return false
	if not TP_BLOCKERS.has(idx):
		return true
	for b in TP_BLOCKERS[idx]:
		if pyramid[b] != null:
			return false
	return true


static func tripeaks_update_face_up(pyramid: Array) -> void:
	for i in 28:
		if pyramid[i] != null and tripeaks_free(pyramid, i):
			pyramid[i]["face_up"] = true


## Rank must be adjacent to the waste top, wrapping A-K.
static func tripeaks_can_play(card: Dictionary, waste_top) -> bool:
	if waste_top == null:
		return true
	var d: int = abs(card["rank"] - waste_top["rank"])
	if d == 1:
		return true
	return (card["rank"] == 1 and waste_top["rank"] == 13) \
		or (card["rank"] == 13 and waste_top["rank"] == 1)


static func tripeaks_won(state: Dictionary) -> bool:
	for c in state["pyramid"]:
		if c != null:
			return false
	return true


static func tripeaks_draw(state: Dictionary) -> Dictionary:
	var s := Cards.clone_state(state)
	if s["stock"].is_empty():
		return s
	var card: Dictionary = s["stock"].pop_front()
	card["face_up"] = true
	s["waste"].append(card)
	return s


# ══════════════════════════════════════════════════════════════════════════════
#  PYRAMID
# ══════════════════════════════════════════════════════════════════════════════

static func pyramid_index(row: int, col: int) -> int:
	@warning_ignore("integer_division")
	return row * (row + 1) / 2 + col


static func init_pyramid(floor_index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = Cards.new_rng()
	var deck := Cards.shuffle(Cards.make_deck(), rng)
	var pyramid := []
	for i in 28:
		var card: Dictionary = deck[i].duplicate()
		card["face_up"] = true
		pyramid.append(card)
	var stock := []
	for i in range(28, deck.size()):
		var card: Dictionary = deck[i].duplicate()
		card["face_up"] = false
		stock.append(card)
	var waste := []
	if not stock.is_empty():
		var first: Dictionary = stock.pop_front()
		first["face_up"] = true
		waste.append(first)
	var diff := difficulty(floor_index)
	var max_cycles := 9999 if diff == "easy" else (2 if diff == "medium" else 1)
	return {
		"type": "pyramid",
		"pyramid": pyramid,
		"stock": stock,
		"waste": waste,
		"cycles": 0,
		"max_cycles": max_cycles,
		"floor": floor_index,
		"card_points": {},
	}


## A pyramid card is blocked while either card resting on it remains.
static func pyramid_blocked(pyramid: Array, row: int, col: int) -> bool:
	if row >= 6:
		return false
	return pyramid[pyramid_index(row + 1, col)] != null \
		or pyramid[pyramid_index(row + 1, col + 1)] != null


## Pyramid pairs to 13: A=1 … K=13, and a King clears alone.
static func pyramid_pairs(a: Dictionary, b) -> bool:
	if b == null:
		return a["rank"] == Cards.RANK_KING
	return a["rank"] + b["rank"] == 13


static func pyramid_won(state: Dictionary) -> bool:
	for c in state["pyramid"]:
		if c != null:
			return false
	return true


static func pyramid_draw(state: Dictionary) -> Dictionary:
	var s := Cards.clone_state(state)
	if not s["stock"].is_empty():
		var card: Dictionary = s["stock"].pop_back()
		card["face_up"] = true
		s["waste"].append(card)
	elif not s["waste"].is_empty() and int(s["cycles"]) < int(s["max_cycles"]):
		var top: Dictionary = s["waste"].pop_back()
		var recycled := []
		var waste: Array = s["waste"]
		for i in range(waste.size() - 1, -1, -1):
			var card: Dictionary = waste[i].duplicate()
			card["face_up"] = false
			recycled.append(card)
		s["stock"] = recycled
		s["waste"] = [top]
		s["cycles"] = int(s["cycles"]) + 1
	return s


# ══════════════════════════════════════════════════════════════════════════════
#  FREECELL
# ══════════════════════════════════════════════════════════════════════════════

static func init_freecell(floor_index: int, extra_cell: bool = false, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = Cards.new_rng()
	var deck := Cards.shuffle(Cards.make_deck(), rng)
	var tableau := []
	var idx := 0
	for c in 8:
		var count := 7 if c < 4 else 6
		var pile := []
		for i in count:
			var card: Dictionary = deck[idx].duplicate()
			card["face_up"] = true
			pile.append(card)
			idx += 1
		tableau.append(pile)
	var cells := []
	for i in (5 if extra_cell else 4):
		cells.append(null)
	return {
		"type": "freecell",
		"tableau": tableau,
		"freecells": cells,
		"foundations": [[], [], [], []],
		"floor": floor_index,
		"card_points": {},
	}


static func freecell_can_foundation(card: Dictionary, foundations: Array) -> bool:
	return klondike_can_foundation(card, foundations)


static func freecell_can_tableau(card: Dictionary, target: Array) -> bool:
	if target.is_empty():
		return true
	var top: Dictionary = target[target.size() - 1]
	return top["rank"] == card["rank"] + 1 \
		and Cards.is_red(top["suit"]) != Cards.is_red(card["suit"])


## (free cells + 1) × 2^(empty columns) — the standard supermove capacity.
static func freecell_max_movable(state: Dictionary) -> int:
	var free := 0
	for c in state["freecells"]:
		if c == null:
			free += 1
	var empty := 0
	for col in state["tableau"]:
		if col.is_empty():
			empty += 1
	return (free + 1) * int(pow(2, empty))


static func freecell_won(state: Dictionary) -> bool:
	return klondike_won(state)


# ══════════════════════════════════════════════════════════════════════════════
#  DISPATCH
# ══════════════════════════════════════════════════════════════════════════════

static func init_game(type: String, floor_index: int, extra_cell: bool = false, rng: RandomNumberGenerator = null) -> Dictionary:
	match type:
		"klondike": return init_klondike(floor_index, rng)
		"spider": return init_spider(floor_index, rng)
		"tripeaks": return init_tripeaks(floor_index, rng)
		"pyramid": return init_pyramid(floor_index, rng)
		"freecell": return init_freecell(floor_index, extra_cell, rng)
	push_error("Unknown game type: %s" % type)
	return {}


static func is_won(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	match state.get("type", ""):
		"klondike": return klondike_won(state)
		"spider": return spider_won(state)
		"tripeaks": return tripeaks_won(state)
		"pyramid": return pyramid_won(state)
		"freecell": return freecell_won(state)
	return false
