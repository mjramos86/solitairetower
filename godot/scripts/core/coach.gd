class_name Coach
extends RefCounted

## The one line the run's patron says when the table refuses what the player
## just tried. Pure logic: it reads the same state and the same Rules helpers the
## refusal itself came from, and returns an ENGLISH source string — the caller
## passes it through Locale.t, so every line here needs a key in each
## translations_*.gd map.
##
## The point is to name the rule that blocked the action, not to narrate the
## failure. "No dealing while a column stands empty" tells the player what to do
## next; "invalid move" does not. Where a rule is numeric (FreeCell's supermove
## capacity) the live number goes in, because that is the part people get wrong.
##
## Every entry point returns "" when nothing useful can be said, and the caller
## then stays silent rather than filling the bubble with noise.


## The whole rulebook of one variant in a single speech, for the How to play
## button. Not a reaction: the player asked, so it is the one line the mute
## switch does not silence.
##
## Each variant is ONE multi-line string rather than a list of translated
## fragments, so a translator reads the briefing as a briefing and can reorder a
## clause without the key drifting from its English source.
static func how_to_play(type: String) -> String:
	match type:
		"klondike":
			return "Klondike. Four foundations, one suit each, climbing Ace to King — fill all four and the floor is yours.\n• The tableau runs down in alternating colours: red on black, black on red.\n• Only a King may open an empty column.\n• Draw from the stock to the waste and play the waste's top card.\n• Clearing the cards above a face-down one turns it over."
		"spider":
			return "Spider. Eight runs, King down to Ace in a single suit; each run you finish leaves the table.\n• A card lands on the rank just above it, whatever the suit.\n• Only a run already in one suit travels as a block — a mixed one moves card by card.\n• Deal ten more cards when you are stuck, but never while a column stands empty.\n• Clear all eight runs to win."
		"freecell":
			return "FreeCell. Every card is face up from the first move, and every deal can be won. Build four foundations, Ace to King, one suit each.\n• Columns run down in alternating colours: red on black, black on red.\n• Each free cell parks a single card.\n• One move carries (free cells + 1) cards, doubled for every empty column.\n• Nothing is hidden. The whole puzzle is in front of you from the start."
		"tripeaks":
			return "TriPeaks. Clear all twenty-eight cards from the three peaks.\n• Take any uncovered card one rank above or below the top of the waste.\n• The Ace bridges King and Two, so a chain never has to stop there.\n• A card is uncovered once the two below it are gone.\n• Draw from the stock when nothing fits — it breaks your chain, and a long chain scores far more."
		"pyramid":
			return "Pyramid. Clear every card of the pyramid by pairing them to thirteen.\n• The Ace counts one, the Jack eleven, the Queen twelve, the King thirteen.\n• A King is thirteen on its own and clears alone.\n• Only an uncovered card can be paired: the two below it must go first.\n• Pair with the top of the waste, or turn the stock for a new one."
	return ""


## Refused deal from the stock. Spider is the only variant that can refuse one.
static func deal(gs: Dictionary) -> String:
	if String(gs.get("type", "")) != "spider":
		return ""
	if (gs.get("stock_groups", []) as Array).is_empty():
		return "The stock is spent — what lies on the table is all that remains."
	for col in gs["tableau"]:
		if (col as Array).is_empty():
			return "No dealing while a column stands empty. Fill every gap first, then the stock will give."
	return ""


## Refused drop: `cards` could not land on `to`. `from` is where they came from.
static func drop(gs: Dictionary, cards: Array, to: Dictionary) -> String:
	if cards.is_empty():
		return ""
	var type := String(gs.get("type", ""))
	var moving: Dictionary = cards[0]
	match String(to.get("kind", "")):
		"foundation":
			if cards.size() > 1:
				return "A foundation takes one card at a time, never a run."
			var col := int(to.get("col", -1))
			if col >= 0 and col != int(moving["suit"]):
				return "Each foundation keeps to a single suit — that pile is not yours to fill."
			return "Foundations climb from the Ace upward, one rank at a time."
		"freecell":
			return "A free cell holds a single card, and that one is taken."
		"tableau":
			var target: Array = gs["tableau"][int(to["col"])]
			match type:
				"spider":
					if target.is_empty():
						return ""  # spider accepts anything on an empty column
					return "A card only lands on the rank just above it. Suit matters when you lift a run, not when you place one."
				"freecell":
					if cards.size() > 1:
						return _freecell_capacity(gs, cards.size())
					return "Columns run down in alternating colours — red on black, black on red."
				_:
					if target.is_empty():
						return "Only a King may open an empty column."
					return "The tableau runs down in alternating colours — red on black, black on red."
	return ""


## Refused pick-up: the player clicked a face-up card that will not travel.
static func pickup(gs: Dictionary, meta: Dictionary) -> String:
	var type := String(gs.get("type", ""))
	if String(meta.get("kind", "")) != "tableau":
		return _nowhere(type)
	var pile: Array = gs["tableau"][int(meta["col"])]
	var idx := int(meta.get("index", pile.size() - 1))
	if idx < 0 or idx >= pile.size():
		return ""
	if not pile[idx]["face_up"]:
		return "That card lies face down. Clear the cards above it and it will turn."
	var held := pile.size() - idx
	if held <= 1:
		return _nowhere(type)
	# A run was grabbed that the rules will not carry as one piece.
	match type:
		"spider":
			if held > Rules.spider_sequence_length(pile):
				return "Only a run descending in one suit travels as a block. A mixed run moves one card at a time."
		"freecell":
			var cap := Rules.freecell_max_movable(gs)
			if held > cap:
				return _freecell_capacity(gs, held)
		"klondike":
			return "A run travels whole only while it descends in alternating colours."
	return _nowhere(type)


## Refused single-click play in the two games that have no selection step.
static func play(gs: Dictionary, meta: Dictionary) -> String:
	var type := String(gs.get("type", ""))
	var idx := int(meta.get("index", -1))
	if type == "tripeaks":
		if idx >= 0 and not Rules.tripeaks_free(gs["pyramid"], idx):
			return "That card is still covered. Clear the two below it first."
		return "Take only a card one rank above or below the waste. The Ace bridges King and Two."
	if type == "pyramid":
		if String(meta.get("kind", "")) == "pyramid" and idx >= 0 and _pyramid_covered(gs, idx):
			return "That card is still covered. Clear the two below it first."
		return "Pair cards that add to thirteen. A King is worth thirteen alone."
	return ""


## Pyramid metas carry a flat index; the blocking rule is addressed by row/col.
static func _pyramid_covered(gs: Dictionary, idx: int) -> bool:
	var row := 0
	while Rules.pyramid_index(row + 1, 0) <= idx and row < 6:
		row += 1
	return Rules.pyramid_blocked(gs["pyramid"], row, idx - Rules.pyramid_index(row, 0))


## FreeCell's supermove capacity, with the live number — the rule players most
## often read as a bug. (free cells + 1) × 2^(empty columns).
##
## The only line here carrying numbers, so it is the only one translated at the
## source: Locale.tf translates the template and THEN fills the placeholders,
## which a caller holding the finished sentence could no longer do. Passing the
## result through Locale.t again (as the caller does) leaves it untouched, since
## a string with no entry in the map falls back to itself.
static func _freecell_capacity(gs: Dictionary, wanted: int) -> String:
	var cap := Rules.freecell_max_movable(gs)
	return Locale.tf("You can carry %d cards at once, not %d — each free cell and each empty column raises the count.",
		[cap, wanted])


static func _nowhere(type: String) -> String:
	match type:
		"spider": return "Nowhere for that card to go. Deal a new row once every column holds a card."
		"freecell": return "Nowhere for that card to go — park it in a free cell and dig deeper."
		"klondike": return "Nowhere for that card to go. Draw from the stock and come back to it."
	return "Nowhere for that card to go just now."
