class_name Hints
extends RefCounted

## Legal-move finders for all five variants, ported from findHints* in
## index.html. Used by the Scrying Glass (one hint) and the Astrolabe (all
## hints), and by any future "no moves left" detection.
##
## A hint is a Dictionary describing a source and, where one exists, a target:
##   {"src": "tab"/"waste"/"fc"/"pycard", "col": int, "index": int,
##    "tsrc": "tab"/"found"/"fc"/"waste"/"pycard", "tcol": int, "tindex": int}
##
## `all = false` stops at the first hint found, matching the original.


static func find(state: Dictionary, all: bool = false) -> Array:
	if state.is_empty():
		return []
	match state.get("type", ""):
		"klondike": return klondike(state, all)
		"spider": return spider(state, all)
		"tripeaks": return tripeaks(state, all)
		"pyramid": return pyramid(state, all)
		"freecell": return freecell(state, all)
	return []


static func klondike(gs: Dictionary, all: bool) -> Array:
	var hints := []
	var waste: Array = gs["waste"]
	if not waste.is_empty():
		var wtop: Dictionary = waste[waste.size() - 1]
		if Rules.klondike_can_foundation(wtop, gs["foundations"]):
			hints.append({"src": "waste", "col": -1, "index": -1,
				"tsrc": "found", "tcol": wtop["suit"]})
		for c in 7:
			if Rules.klondike_can_tableau([wtop], gs["tableau"][c]):
				hints.append({"src": "waste", "col": -1, "index": -1, "tsrc": "tab", "tcol": c})

	for c in 7:
		var pile: Array = gs["tableau"][c]
		if pile.is_empty():
			continue
		var top: Dictionary = pile[pile.size() - 1]
		if top["face_up"] and Rules.klondike_can_foundation(top, gs["foundations"]):
			hints.append({"src": "tab", "col": c, "index": pile.size() - 1,
				"tsrc": "found", "tcol": top["suit"]})
		for idx in pile.size():
			if not pile[idx]["face_up"]:
				continue
			var cards := pile.slice(idx)
			for d in 7:
				if d == c:
					continue
				if Rules.klondike_can_tableau(cards, gs["tableau"][d]):
					hints.append({"src": "tab", "col": c, "index": idx, "tsrc": "tab", "tcol": d})
			if not all:
				break
		if not all and not hints.is_empty():
			break

	if all:
		return hints
	return hints.slice(0, 1)


static func spider(gs: Dictionary, all: bool) -> Array:
	var hints := []
	var columns: int = gs["tableau"].size()
	for c in columns:
		var pile: Array = gs["tableau"][c]
		if pile.is_empty():
			continue
		# Only the trailing same-suit run can be picked up as a unit.
		var start := pile.size() - Rules.spider_sequence_length(pile)
		for idx in range(start, pile.size()):
			var cards := pile.slice(idx)
			for d in columns:
				if d == c:
					continue
				if Rules.spider_can_drop(cards, gs["tableau"][d]):
					hints.append({"src": "tab", "col": c, "index": idx, "tsrc": "tab", "tcol": d})
					if not all:
						return hints
	return hints


static func tripeaks(gs: Dictionary, all: bool) -> Array:
	var hints := []
	var wtop = null
	if not gs["waste"].is_empty():
		wtop = gs["waste"][gs["waste"].size() - 1]
	for i in 28:
		var card = gs["pyramid"][i]
		if card == null:
			continue
		if Rules.tripeaks_free(gs["pyramid"], i) and Rules.tripeaks_can_play(card, wtop):
			hints.append({"src": "pycard", "col": 0, "index": i})
			if not all:
				return hints
	return hints


static func pyramid(gs: Dictionary, all: bool) -> Array:
	var hints := []
	var wtop = null
	if not gs["waste"].is_empty():
		wtop = gs["waste"][gs["waste"].size() - 1]

	for r in 7:
		for c in range(r + 1):
			var i := Rules.pyramid_index(r, c)
			var card = gs["pyramid"][i]
			if card == null or Rules.pyramid_blocked(gs["pyramid"], r, c):
				continue

			# A king clears by itself.
			if int(card["rank"]) == Cards.RANK_KING:
				hints.append({"src": "pycard", "col": 0, "index": i})
				if not all:
					return hints

			# Pair with the waste top.
			if wtop != null and int(wtop["rank"]) + int(card["rank"]) == 13:
				hints.append({"src": "pycard", "col": 0, "index": i, "tsrc": "waste"})
				if not all:
					return hints

			# Pair with another exposed pyramid card. Only look forward so each
			# pair is reported once.
			for r2 in 7:
				for c2 in range(r2 + 1):
					var i2 := Rules.pyramid_index(r2, c2)
					if i2 <= i:
						continue
					var other = gs["pyramid"][i2]
					if other == null or Rules.pyramid_blocked(gs["pyramid"], r2, c2):
						continue
					if int(card["rank"]) + int(other["rank"]) == 13:
						hints.append({"src": "pycard", "col": 0, "index": i,
							"tsrc": "pycard", "tcol": 0, "tindex": i2})
						if not all:
							return hints
	return hints


static func freecell(gs: Dictionary, all: bool) -> Array:
	var hints := []
	var movable := []
	for c in gs["tableau"].size():
		var pile: Array = gs["tableau"][c]
		if not pile.is_empty():
			movable.append({"card": pile[pile.size() - 1], "src": "tab", "col": c,
				"index": pile.size() - 1})
	for c in gs["freecells"].size():
		if gs["freecells"][c] != null:
			movable.append({"card": gs["freecells"][c], "src": "fc", "col": c, "index": -1})

	# Foundations first — they are always the best move available.
	for m in movable:
		if Rules.freecell_can_foundation(m["card"], gs["foundations"]):
			hints.append({"src": m["src"], "col": m["col"], "index": m["index"],
				"tsrc": "found", "tcol": m["card"]["suit"]})
			if not all:
				return hints

	for m in movable:
		for d in 8:
			if m["src"] == "tab" and d == m["col"]:
				continue
			if Rules.freecell_can_tableau(m["card"], gs["tableau"][d]):
				hints.append({"src": m["src"], "col": m["col"], "index": m["index"],
					"tsrc": "tab", "tcol": d})
				if not all:
					return hints

	for m in movable:
		for d in gs["freecells"].size():
			if gs["freecells"][d] == null:
				hints.append({"src": m["src"], "col": m["col"], "index": m["index"],
					"tsrc": "fc", "tcol": d})
				if not all:
					return hints
	return hints
