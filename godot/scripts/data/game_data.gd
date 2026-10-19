class_name GameData
extends RefCounted

## Static game data ported from index.html: game types, shop stock, card backs.
## Kept as plain data so it can be unit-tested and serialised without a scene.

const TYPES := ["klondike", "spider", "tripeaks", "pyramid"]

const NAMES := {
	"klondike": "Klondike",
	"spider": "Spider",
	"tripeaks": "TriPeaks",
	"pyramid": "Pyramid",
	"freecell": "FreeCell",
}

const ICONS := {
	"klondike": "🂡",
	"spider": "🕷",
	"tripeaks": "⛰",
	"pyramid": "△",
	"freecell": "👑",
}

## Per-variant rules, one terse line each. These were the reference strip above
## the board until the patron's How to play briefing replaced it — the strip and
## the briefing said the same thing twice, and only one of them was written as
## someone speaking. Nothing in the game draws these now; they are still exported
## by tests/dump_text.gd for the external Tower Text Studio. Ported from RULES.
const RULES := {
	"klondike": [
		"Build 4 foundation piles A→K by suit",
		"Tableau: descending rank, alternating colour",
		"Draw from stock to waste; move waste top card to play",
		"Flip hidden cards by clearing cards above them",
	],
	"spider": [
		"Build complete K→A sequences of the same suit",
		"Completed sequences removed to foundations",
		"Deal 10 new cards from stock when stuck",
		"Clear all 8 sequences to win",
	],
	"tripeaks": [
		"Play cards +1 or -1 rank from waste top (A↔K wrap)",
		"Click pyramid cards to chain onto the waste",
		"Draw from stock when no move available",
		"Clear all 28 pyramid cards to win",
	],
	"pyramid": [
		"Pair cards that sum to 13 (A=1, J=11, Q=12, K=13)",
		"Kings are removed alone",
		"Use the waste top to pair with pyramid cards",
		"Clear all pyramid cards to win",
	],
	"freecell": [
		"All cards dealt face-up — every deal is solvable",
		"Build foundations A→K by suit",
		"Use free cells as temporary card parking",
		"Tableau: descending rank, alternating colour",
	],
}

const TOTAL_FLOORS := 10
const STARTING_LIVES := 3
const INVENTORY_SLOTS := 3

## ── The in-game shop ──────────────────────────────────────────────────────────
##
## Gold is paid out as the board advances rather than in a lump when the floor
## ends, because the shop now opens DURING a floor and needs something to spend
## there. The rate is per variant, and keyed to progress rather than to score,
## for a specific reason: score is not comparable between variants. A cleared
## Klondike floor scores around 1200 and a cleared Pyramid around 160, so paying
## a fraction of score would make Klondike roughly seven times richer and push
## every player down the same branch of the tower.
##
## Each rate is instead calibrated against the number of progress events a full
## clear contains, so clearing any floor pays about GOLD_PER_FLOOR, whichever
## variant it was.
##
## The figure is 160, up from 50, and the end-of-floor bonuses below came down
## from 95 to 25 to pay for most of it. That trade is the whole point. At 50 a
## floor could not fund even the cheapest item (60) out of its own play: every
## purchase was really being paid for by the PREVIOUS floor's end bonuses, which
## made an in-floor shop a between-floors shop wearing a costume. Simulated
## runs put only 15% of purchases after the first third of a floor. At 160 the
## board crosses the cheap tier about every seven progress events, so the money
## arrives while there is still a board to spend it on.
##
## Spider pays in lumps of 20 rather than a trickle because its progress event
## is a completed suit. Finishing one should visibly unlock something.
const GOLD_PER_FLOOR := 160
const GOLD_PER_PROGRESS := {
	"klondike": 3,    # 52 cards reaching a foundation → 156
	"freecell": 3,    # 52 cards reaching a foundation → 156
	"spider": 20,     #  8 suits completed             → 160
	"tripeaks": 6,    # 28 cards taken from the peaks  → 168
	"pyramid": 6,     # 28 cards cleared               → 168
}

const SHOP_BUYS_PER_FLOOR := 3

## Rerolling the remaining offers. Deliberately under the cheapest item (40), so
## it stays a real option on a thin purse without being free.
const REROLL_COST := 25


## Gold for one progress event in the variant being played.
static func gold_per_progress(type: String) -> int:
	return int(GOLD_PER_PROGRESS.get(type, 0))
const UNDOS_PER_FLOOR := 3

## Perfect card score: 52 cards × 20 points. Used by the progress bar.
const MAX_CARD_POINTS := 1040

const TIER_NAMES := ["CHEAP", "MEDIUM", "PRICEY", "RARE"]
const TIER_WEIGHTS := [5, 3, 2, 1]

## Every purchasable item. `effect` is the switch the game logic dispatches on.
const SHOP_ITEMS := [
	# ── tier 0, cheap ──
	{"id": "sticky-note", "name": "Scrying Glass", "icon": "🔮", "price": 40, "tier": 0,
	 "effect": "hint", "desc": "Highlights one valid move on the board.",
	 "use": "Instant: glows on valid source & target.", "best_for": "All games"},
	{"id": "rubber-band", "name": "Knotted Cord", "icon": "🪢", "price": 50, "tier": 0,
	 "effect": "extra-undos", "desc": "You only get 3 undos per floor. This adds 5 more.",
	 "use": "Instant: adds 5 undos to your budget.", "best_for": "All games"},
	{"id": "coffee", "name": "Mortlake Brew", "icon": "🧪", "price": 45, "tier": 0,
	 "effect": "free-draw", "desc": "Draw 1 extra card from stock for free.",
	 "use": "Instant: free stock draw.", "best_for": "Klondike · TriPeaks"},
	{"id": "pencil", "name": "Quill of Ravens", "icon": "🪶", "price": 55, "tier": 0,
	 "effect": "peek", "desc": "Peek at the top 3 cards in the stock pile.",
	 "use": "Shows a 6-second preview window.", "best_for": "Klondike · TriPeaks"},
	{"id": "tape", "name": "Sealing Wax", "icon": "🕯️", "price": 60, "tier": 0,
	 "effect": "extra-cycle", "desc": "Get one free waste→stock recycle.",
	 "use": "Instant: recycles without counting.", "best_for": "Klondike · Pyramid"},
	# ── tier 1, medium ──
	{"id": "scissors", "name": "Athame", "icon": "🗡️", "price": 120, "tier": 1,
	 "effect": "remove-card", "desc": "Remove any one face-up card from the board entirely.",
	 "use": "Click mode: pick a card to vanish it.", "best_for": "Pyramid · TriPeaks"},
	{"id": "magnifier", "name": "Obsidian Mirror", "icon": "🪞", "price": 135, "tier": 1,
	 "effect": "reveal-all", "desc": "Reveal all face-down cards for 8 seconds.",
	 "use": "Instant: temporary x-ray vision.", "best_for": "Spider · Klondike"},
	{"id": "stapler", "name": "Wax Seal Press", "icon": "🏷️", "price": 140, "tier": 1,
	 "effect": "ace-to-found", "desc": "Digs an Ace out from anywhere — even buried or face-down — and sends it to its foundation.",
	 "use": "Instant: finds an Ace anywhere.", "best_for": "Klondike · FreeCell"},
	{"id": "eraser", "name": "Philosopher's Sponge", "icon": "🧽", "price": 160, "tier": 1,
	 "effect": "big-undo", "desc": "Mega-undo: rewind up to 10 moves at once.",
	 "use": "Instant: pops 10 undo states.", "best_for": "All games"},
	{"id": "envelope", "name": "Sealed Letter", "icon": "✉️", "price": 125, "tier": 1,
	 "effect": "free-cycle", "desc": "Shuffle waste back into stock for free.",
	 "use": "Instant: free recycle.", "best_for": "Klondike · Pyramid"},
	{"id": "paperclip", "name": "Brass Compass", "icon": "🧭", "price": 105, "tier": 1,
	 "effect": "flip-card", "desc": "Flip any face-down tableau card face-up.",
	 "use": "Click mode: pick a face-down card.", "best_for": "Spider · Klondike"},
	{"id": "calculator", "name": "Astrolabe", "icon": "⚙️", "price": 115, "tier": 1,
	 "effect": "hint-all", "desc": "Flash ALL valid moves for 8 seconds.",
	 "use": "Instant: full board hint glow.", "best_for": "All games"},
	# ── tier 2, expensive ──
	{"id": "briefcase", "name": "Hermetic Casket", "icon": "⚱️", "price": 300, "tier": 2,
	 "effect": "retrieve-waste", "desc": "Bring any buried waste card to the top to play next.",
	 "use": "Opens waste picker -- select a card.", "best_for": "Klondike · TriPeaks"},
	{"id": "spare-key", "name": "Skeleton Key", "icon": "🗝️", "price": 270, "tier": 2,
	 "effect": "extra-freecell", "desc": "Unlock a 5th free cell for this entire floor.",
	 "use": "Instant: adds a free cell slot.", "best_for": "FreeCell"},
	{"id": "toolbox", "name": "Alchemist's Cabinet", "icon": "🗄️", "price": 250, "tier": 2,
	 "effect": "toolbox", "desc": "Creates a temporary off-board card stash (1 card, 8 uses).",
	 "use": "Drag any card in/out of the stash.", "best_for": "Spider · FreeCell · Klondike"},
	{"id": "broom", "name": "Angelic Besom", "icon": "🧹", "price": 285, "tier": 2,
	 "effect": "broom", "desc": "Sweep the top card of any pile to the first empty column.",
	 "use": "Click mode: pick a source pile top.", "best_for": "Spider · FreeCell"},
	# ── tier 3, rare ──
	{"id": "master-key", "name": "Enochian Key", "icon": "🔑", "price": 690, "tier": 3,
	 "effect": "choose-from-stock", "desc": "Pull any card from stock to the top of the waste pile.",
	 "use": "Opens stock browser -- pick your card.", "best_for": "Klondike · TriPeaks"},
	{"id": "extinguisher", "name": "Vial of Quicksilver", "icon": "🧫", "price": 825, "tier": 3,
	 "effect": "no-life-abandon", "desc": "Abandon this floor without losing a life.",
	 "use": "Instant: safe retreat to the map.", "best_for": "All games (emergency!)"},
	{"id": "exec-chair", "name": "Queen's Patronage", "icon": "👑", "price": 1050, "tier": 3,
	 "effect": "skip-floor", "desc": "Skip this floor entirely -- counts as cleared!",
	 "use": "Instant: auto-win current floor.", "best_for": "All games (boss skip!)"},
]

## Selectable card backs. `requires_reveal` gates a back behind a patron reveal.
const CARDBACKS := [
	{"id": "classic", "name": "The Solitaire Tower", "unlocked": true},
	{"id": "cult", "name": "The King of Hearts", "unlocked": true},
	{"id": "dee", "name": "John Dee's portrait", "unlocked": true},
	{"id": "marie", "name": "Mary Stuart's portrait", "unlocked": false, "requires_reveal": "marie"},
]


## Each time patron stocks a different shop, so the patron you pick shapes your
## whole run. John Dee — the scryer and astrologer — deals only in items that
## reveal what is hidden or look ahead (plus his two emergency escapes, the Vial
## of Quicksilver and the Queen's Patronage). A patron absent from this map sells
## the full catalogue.
const PATRON_ITEMS := {
	"johndee": [
		"sticky-note",   # Scrying Glass  — reveal a move
		"pencil",        # Quill of Ravens — look ahead at the stock
		"magnifier",     # Obsidian Mirror — reveal the hidden
		"stapler",       # Wax Seal Press  — find a buried Ace
		"paperclip",     # Brass Compass   — reveal a face-down card
		"calculator",    # Astrolabe       — reveal every move
		"master-key",    # Enochian Key    — reach into the stock
		"extinguisher",  # Vial of Quicksilver — emergency escape
		"exec-chair",    # Queen's Patronage   — boss skip
	],
}


static func item_by_id(id: String) -> Dictionary:
	for item in SHOP_ITEMS:
		if item["id"] == id:
			return item
	return {}


## The items a given patron is willing to sell, in catalogue order. Patrons not
## listed in PATRON_ITEMS offer everything.
static func patron_item_pool(patron: String) -> Array:
	if not PATRON_ITEMS.has(patron):
		return SHOP_ITEMS.duplicate()
	var allowed: Array = PATRON_ITEMS[patron]
	var pool := []
	for item in SHOP_ITEMS:
		if allowed.has(item["id"]):
			pool.append(item)
	return pool


## Three distinct items the player does not already own, weighted toward cheap
## tiers. Ported from generateShopItems.
static func generate_shop_items(owned_ids: Array, rng: RandomNumberGenerator = null,
		patron: String = "", count: int = SHOP_BUYS_PER_FLOOR) -> Array:
	if rng == null:
		rng = Cards.new_rng()
	var available := []
	for item in patron_item_pool(patron):
		if not owned_ids.has(item["id"]):
			available.append(item)
	var chosen := []
	for i in maxi(count, 0):
		if available.is_empty():
			break
		var total := 0
		for item in available:
			total += TIER_WEIGHTS[item["tier"]]
		var r := rng.randf() * total
		var idx := 0
		while idx < available.size() - 1:
			r -= TIER_WEIGHTS[available[idx]["tier"]]
			if r <= 0:
				break
			idx += 1
		chosen.append(available[idx])
		available.remove_at(idx)
	return chosen


## The 10 floors' game-type choices. Floor 10 always offers Klondike; the
## final floor is FreeCell. Ported from genChoices.
static func generate_choices(rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = Cards.new_rng()
	var choices := []
	for i in TOTAL_FLOORS:
		choices.append(floor_choice(i, rng))
	return choices


## The pair of variants offered on a single floor. The final floor is always the
## FreeCell boss; the first floor always offers Klondike (so a brand-new player
## starts on the familiar game); every other floor is two distinct random types.
## Re-rolled when the player abandons a floor, giving a fresh set of options.
static func floor_choice(floor_index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = Cards.new_rng()
	if floor_index >= TOTAL_FLOORS - 1:
		return {"left": "freecell", "right": "freecell"}
	var t := TYPES.duplicate()
	for j in range(t.size() - 1, 0, -1):
		var k := rng.randi_range(0, j)
		var tmp = t[j]
		t[j] = t[k]
		t[k] = tmp
	if floor_index == 0:
		var other := ""
		for x in t:
			if x != "klondike":
				other = x
				break
		return {"left": "klondike", "right": other}
	return {"left": t[0], "right": t[1]}


## Time-credit awards for clearing a floor. Ported from calcFloorGoldBreakdown.
## `board_gold` is what the floor already paid out progressively; it is listed
## so the player can see where their money came from, but it is NOT added again
## here — the row is marked already_paid and settle_floor skips it.
##
## There is no "Floor Cleared" row any more. It used to pay a flat 50 for
## finishing, on top of the board's own payout, which meant the bulk of a
## floor's income landed after the shop for that floor had closed. The board
## payout IS the clear reward now: collecting all of it is what clearing a
## floor means. What is left here is the three skill bonuses, shrunk to match,
## so playing well still pays without pulling the money back out of the floor.
static func floor_gold_breakdown(elapsed_ms: int, score_gained: int, undos_used: int,
		lives_kept: bool, board_gold: int = 0) -> Array:
	var rows := [{"label": "Earned on the Board", "amount": board_gold, "earned": true,
		"already_paid": true}]
	var no_undo := undos_used == 0
	rows.append({"label": "No Undos", "amount": 10 if no_undo else 0, "earned": no_undo})
	var fast := elapsed_ms < 180000
	rows.append({"label": "Under 3 min", "amount": 8 if fast else 0, "earned": fast})
	rows.append({"label": "Full Lives", "amount": 7 if lives_kept else 0, "earned": lives_kept})
	var pts_bonus := int(score_gained / 500.0) * 5
	if pts_bonus > 0:
		rows.append({"label": "Score Bonus", "amount": pts_bonus, "earned": true})
	return rows
