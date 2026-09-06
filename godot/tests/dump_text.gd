extends SceneTree

## Dev tool: dumps all structured game text (dialogue, lore, items, rules…) as
## JSON so the external text-editor tool can be seeded from the real data.
## Run: godot --headless --path godot --script res://tests/dump_text.gd

func _init() -> void:
	var out := {
		"patrons": Narrative.PATRONS,
		"lore": Narrative.LORE,
		"dee_dialogue": Narrative.DEE_DIALOGUE,
		"dee_checkin_intro": Narrative.DEE_CHECKIN_INTRO,
		"dee_checkin_topics": Narrative.DEE_CHECKIN_TOPICS,
		"dee_dialogue3_intro": Narrative.DEE_DIALOGUE3_INTRO,
		"dee_dialogue3_topics": Narrative.DEE_DIALOGUE3_TOPICS,
		"dee_final": Narrative.DEE_FINAL,
		"victory_lines": Narrative.VICTORY_LINES,
		"victory_choices": Narrative.VICTORY_CHOICES,
		"victory_responses": Narrative.VICTORY_RESPONSES,
		"names": GameData.NAMES,
		"icons": GameData.ICONS,
		"rules": GameData.RULES,
		"tier_names": GameData.TIER_NAMES,
		"shop_items": GameData.SHOP_ITEMS,
		"cardbacks": GameData.CARDBACKS,
	}
	print("<<<JSON>>>")
	print(JSON.stringify(out))
	print("<<<END>>>")
	quit()
