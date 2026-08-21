class_name Cards
extends RefCounted

## Card model, deck building and shuffling.
##
## Cards are plain Dictionaries rather than a class: the game state is cloned on
## every move for the undo stack and serialised whole into the save file, and
## Dictionary gives both for free via duplicate(true) and JSON. Ported from
## mkCard/makeDeck/shuffle in index.html.

enum Suit { SPADES, HEARTS, DIAMONDS, CLUBS }

const SUIT_SYMBOLS := ["♠", "♥", "♦", "♣"]
const RANK_NAMES := ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

const RANK_ACE := 1
const RANK_KING := 13


static func make_card(suit: int, rank: int, face_up: bool = false) -> Dictionary:
	return {"suit": suit, "rank": rank, "face_up": face_up}


static func is_red(suit: int) -> bool:
	return suit == Suit.HEARTS or suit == Suit.DIAMONDS


static func symbol(card: Dictionary) -> String:
	return SUIT_SYMBOLS[card["suit"]]


static func rank_name(card: Dictionary) -> String:
	return RANK_NAMES[card["rank"]]


## Unique key per card identity, for the per-card scoring ledger.
static func key(card: Dictionary) -> String:
	return "%d-%d" % [card["suit"], card["rank"]]


static func make_deck() -> Array:
	var deck := []
	for s in 4:
		for r in range(1, 14):
			deck.append(make_card(s, r))
	return deck


## Fisher-Yates over a deep copy, so the source deck is never disturbed.
static func shuffle(deck: Array, rng: RandomNumberGenerator) -> Array:
	var d := deck.duplicate(true)
	for i in range(d.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = d[i]
		d[i] = d[j]
		d[j] = tmp
	return d


static func new_rng(seed_value: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	return rng


## Deep copy of a game state Dictionary — the undo stack depends on this being
## a true copy, since moves mutate piles in place.
static func clone_state(state: Dictionary) -> Dictionary:
	return state.duplicate(true)


## A monotonic id used only by the UI to follow a card across a move for the
## slide animation. Spider deals duplicate suit/rank cards, so suit-rank is not a
## unique identity; a uid is. clone_state preserves it (duplicate copies the key).
static var _uid_counter := 0


## Stamps every card in a freshly dealt state with a unique uid if it lacks one.
## Idempotent, so it is safe to call after a resume or a mid-game deal.
static func assign_uids(state: Dictionary) -> void:
	for pile_key in ["stock", "waste"]:
		for c in state.get(pile_key, []):
			_tag_uid(c)
	for pile in state.get("tableau", []):
		for c in pile:
			_tag_uid(c)
	for f in state.get("foundations", []):
		if typeof(f) == TYPE_ARRAY:
			for c in f:
				_tag_uid(c)
	for c in state.get("freecells", []):
		_tag_uid(c)
	for c in state.get("pyramid", []):
		_tag_uid(c)
	for grp in state.get("stock_groups", []):
		for c in grp:
			_tag_uid(c)


static func _tag_uid(c) -> void:
	if typeof(c) == TYPE_DICTIONARY and not c.has("uid"):
		_uid_counter += 1
		c["uid"] = _uid_counter
