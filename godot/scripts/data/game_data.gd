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

## Per-variant rules shown as a reference strip during play. Ported from RULES.
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
const UNDOS_PER_FLOOR := 3

## Perfect card score: 52 cards × 20 points. Used by the progress bar.
const MAX_CARD_POINTS := 1040

const TIER_NAMES := ["CHEAP", "MEDIUM", "PRICEY", "RARE"]
const TIER_WEIGHTS := [5, 3, 2, 1]

## Every purchasable item. `effect` is the switch the game logic dispatches on.
const SHOP_ITEMS := [
	# ── tier 0, cheap ──
	{"id": "sticky-note", "name": "Scrying Glass", "icon": "🔮", "price": 60, "tier": 0,
	 "effect": "hint", "desc": "Highlights one valid move on the board.",
	 "use": "Instant: glows on valid source & target.", "best_for": "All games"},
	{"id": "rubber-band", "name": "Knotted Cord", "icon": "🪢", "price": 75, "tier": 0,
	 "effect": "extra-undos", "desc": "You only get 3 undos per floor. This adds 5 more.",
	 "use": "Instant: adds 5 undos to your budget.", "best_for": "All games"},
	{"id": "coffee", "name": "Mortlake Brew", "icon": "🧪", "price": 70, "tier": 0,
	 "effect": "free-draw", "desc": "Draw 1 extra card from stock for free.",
	 "use": "Instant: free stock draw.", "best_for": "Klondike · TriPeaks"},
	{"id": "pencil", "name": "Quill of Ravens", "icon": "🪶", "price": 85, "tier": 0,
	 "effect": "peek", "desc": "Peek at the top 3 cards in the stock pile.",
	 "use": "Shows a 6-second preview window.", "best_for": "Klondike · TriPeaks"},
	{"id": "tape", "name": "Sealing Wax", "icon": "🕯️", "price": 90, "tier": 0,
	 "effect": "extra-cycle", "desc": "Get one free waste→stock recycle.",
	 "use": "Instant: recycles without counting.", "best_for": "Klondike · Pyramid"},
	# ── tier 1, medium ──
	{"id": "scissors", "name": "Athame", "icon": "🗡️", "price": 185, "tier": 1,
	 "effect": "remove-card", "desc": "Remove any one face-up card from the board entirely.",
	 "use": "Click mode: pick a card to vanish it.", "best_for": "Pyramid · TriPeaks"},
	{"id": "magnifier", "name": "Obsidian Mirror", "icon": "🪞", "price": 210, "tier": 1,
	 "effect": "reveal-all", "desc": "Reveal all face-down cards for 8 seconds.",
	 "use": "Instant: temporary x-ray vision.", "best_for": "Spider · Klondike"},
	{"id": "stapler", "name": "Wax Seal Press", "icon": "🏷️", "price": 220, "tier": 1,
	 "effect": "ace-to-found", "desc": "Digs an Ace out from anywhere — even buried or face-down — and sends it to its foundation.",
	 "use": "Instant: finds an Ace anywhere.", "best_for": "Klondike · FreeCell"},
	{"id": "eraser", "name": "Philosopher's Sponge", "icon": "🧽", "price": 245, "tier": 1,
	 "effect": "big-undo", "desc": "Mega-undo: rewind up to 10 moves at once.",
	 "use": "Instant: pops 10 undo states.", "best_for": "All games"},
	{"id": "envelope", "name": "Sealed Letter", "icon": "✉️", "price": 195, "tier": 1,
	 "effect": "free-cycle", "desc": "Shuffle waste back into stock for free.",
	 "use": "Instant: free recycle.", "best_for": "Klondike · Pyramid"},
	{"id": "paperclip", "name": "Brass Compass", "icon": "🧭", "price": 165, "tier": 1,
	 "effect": "flip-card", "desc": "Flip any face-down tableau card face-up.",
	 "use": "Click mode: pick a face-down card.", "best_for": "Spider · Klondike"},
	{"id": "calculator", "name": "Astrolabe", "icon": "⚙️", "price": 180, "tier": 1,
	 "effect": "hint-all", "desc": "Flash ALL valid moves for 8 seconds.",
	 "use": "Instant: full board hint glow.", "best_for": "All games"},
	# ── tier 2, expensive ──
	{"id": "briefcase", "name": "Hermetic Casket", "icon": "⚱️", "price": 430, "tier": 2,
	 "effect": "retrieve-waste", "desc": "Bring any buried waste card to the top to play next.",
	 "use": "Opens waste picker -- select a card.", "best_for": "Klondike · TriPeaks"},
	{"id": "spare-key", "name": "Skeleton Key", "icon": "🗝️", "price": 390, "tier": 2,
	 "effect": "extra-freecell", "desc": "Unlock a 5th free cell for this entire floor.",
	 "use": "Instant: adds a free cell slot.", "best_for": "FreeCell"},
	{"id": "toolbox", "name": "Alchemist's Cabinet", "icon": "🗄️", "price": 360, "tier": 2,
	 "effect": "toolbox", "desc": "Creates a temporary off-board card stash (1 card, 8 uses).",
	 "use": "Drag any card in/out of the stash.", "best_for": "Spider · FreeCell · Klondike"},
	{"id": "broom", "name": "Angelic Besom", "icon": "🧹", "price": 410, "tier": 2,
	 "effect": "broom", "desc": "Sweep the top card of any pile to the first empty column.",
	 "use": "Click mode: pick a source pile top.", "best_for": "Spider · FreeCell"},
	# ── tier 3, rare ──
	{"id": "master-key", "name": "Enochian Key", "icon": "🔑", "price": 920, "tier": 3,
	 "effect": "choose-from-stock", "desc": "Pull any card from stock to the top of the waste pile.",
	 "use": "Opens stock browser -- pick your card.", "best_for": "Klondike · TriPeaks"},
	{"id": "extinguisher", "name": "Vial of Quicksilver", "icon": "🧫", "price": 1100, "tier": 3,
	 "effect": "no-life-abandon", "desc": "Abandon this floor without losing a life.",
	 "use": "Instant: safe retreat to the map.", "best_for": "All games (emergency!)"},
	{"id": "exec-chair", "name": "Queen's Patronage", "icon": "👑", "price": 1400, "tier": 3,
	 "effect": "skip-floor", "desc": "Skip this floor entirely -- counts as cleared!",
	 "use": "Instant: auto-win current floor.", "best_for": "All games (boss skip!)"},
]

## Selectable card backs. `requires_reveal` gates a back behind a patron reveal.
const CARDBACKS := [
	{"id": "classic", "name": "The Solitaire Tower", "unlocked": true},
	{"id": "cult", "name": "The Cult", "unlocked": true},
	{"id": "dee", "name": "John Dee's Sigil", "unlocked": true},
	{"id": "marie", "name": "Mary's Cipher", "unlocked": false, "requires_reveal": "marie"},
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
		patron: String = "") -> Array:
	if rng == null:
		rng = Cards.new_rng()
	var available := []
	for item in patron_item_pool(patron):
		if not owned_ids.has(item["id"]):
			available.append(item)
	var chosen := []
	for i in 3:
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
static func floor_gold_breakdown(elapsed_ms: int, score_gained: int, undos_used: int, lives_kept: bool) -> Array:
	var rows := [{"label": "Floor Cleared", "amount": 50, "earned": true}]
	var no_undo := undos_used == 0
	rows.append({"label": "No Undos", "amount": 20 if no_undo else 0, "earned": no_undo})
	var fast := elapsed_ms < 180000
	rows.append({"label": "Under 3 min", "amount": 15 if fast else 0, "earned": fast})
	rows.append({"label": "Full Lives", "amount": 10 if lives_kept else 0, "earned": lives_kept})
	var pts_bonus := int(score_gained / 500.0) * 5
	if pts_bonus > 0:
		rows.append({"label": "Score Bonus", "amount": pts_bonus, "earned": true})
	return rows
