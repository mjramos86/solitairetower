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
	 "effect": "ace-to-found", "desc": "Instantly send any visible Ace to its foundation.",
	 "use": "Instant: auto-finds the first Ace.", "best_for": "Klondike · FreeCell"},
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


static func item_by_id(id: String) -> Dictionary:
	for item in SHOP_ITEMS:
		if item["id"] == id:
			return item
	return {}


## Three distinct items the player does not already own, weighted toward cheap
## tiers. Ported from generateShopItems.
static func generate_shop_items(owned_ids: Array, rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = Cards.new_rng()
	var available := []
	for item in SHOP_ITEMS:
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
	for i in 9:
		var t := TYPES.duplicate()
		for j in range(t.size() - 1, 0, -1):
			var k := rng.randi_range(0, j)
			var tmp = t[j]
			t[j] = t[k]
			t[k] = tmp
		if i == 0:
			var other := ""
			for x in t:
				if x != "klondike":
					other = x
					break
			choices.append({"left": "klondike", "right": other})
		else:
			choices.append({"left": t[0], "right": t[1]})
	choices.append({"left": "freecell", "right": "freecell"})
	return choices


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
