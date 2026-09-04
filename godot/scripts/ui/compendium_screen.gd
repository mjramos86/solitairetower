extends Control

## The compendium: patron biographies, lore entries, and the connections between
## them, bought with banked Time Energy. Ported from the compendium section of
## index.html.
##
## Entries are PATRONS + LORE. An entry can be:
##   locked     silhouette only, shown as "Unknown Patron"
##   unlocked   name, portrait and bio readable
##   revealed   the true name replaces the alias (Mary, Queen of Scots)
##
## Two purchases exist, both paid from the profile's banked credits, which now
## persist locally for every player rather than only for signed-in accounts:
##   connection_cost      reveals an entry's `lore` — its link to Solitaire
##   patron_unlock_cost   unlocks an in-development patron entirely
##
## Alongside the nav list sits a "Timeline of Civilization" that plots every
## discovered entry by year and glows where two of them are historically linked.
## John Dee's page also carries the "Recorded Transmissions" — transcripts of
## every conversation the player has reached with him. Prev/Next page buttons and
## a "new content" badge on the map complete the port.

## Page prose colour, matching .compendium-page { color:#f0ede5 }.
const PAGE_TEXT := Color("f0ede5")
## The dim/glow gold used for timeline lines, from the .compendium-tl-* rules.
const GOLD_A18 := Color(0.831, 0.659, 0.294, 0.18)

@onready var _list: VBoxContainer = $Margin/Center/Frame/Col/Layout/Nav/Scroll/List
@onready var _page: VBoxContainer = $Margin/Center/Frame/Col/Layout/Page/Scroll/Content
@onready var _page_scroll: ScrollContainer = $Margin/Center/Frame/Col/Layout/Page/Scroll
@onready var _credits: Label = $Margin/Center/Frame/Col/Credits/CreditsLabel
@onready var _title: Label = $Margin/Center/Frame/Col/TitleBar/Bar/Title
@onready var _close_button: Button = $Margin/Center/Frame/Col/TitleBar/Bar/Close
@onready var _frame: PanelContainer = $Margin/Center/Frame
@onready var _titlebar: PanelContainer = $Margin/Center/Frame/Col/TitleBar
@onready var _credits_panel: PanelContainer = $Margin/Center/Frame/Col/Credits
@onready var _nav: PanelContainer = $Margin/Center/Frame/Col/Layout/Nav
@onready var _col: VBoxContainer = $Margin/Center/Frame/Col

var _entries: Array = []
var _selected := 0
var _footer: PanelContainer = null


func _ready() -> void:
	# PATRONS then LORE, in declaration order — the web nav is unsorted; only the
	# timeline is chronological.
	_entries = []
	for p in Narrative.PATRONS:
		_entries.append(p)
	for l in Narrative.LORE:
		_entries.append(l)

	_style_chrome()
	_build_footer()
	_close_button.pressed.connect(func(): RunState.set_screen("map"))
	# Opening the compendium clears the "new content" badge on the map.
	SaveManager.mark_compendium_seen()
	SaveManager.save_game()
	_refresh()


## Gold-framed occult panel with a Playfair gradient titlebar, banked-credits
## strip and right-divided nav — ported from the .compendium-* CSS.
func _style_chrome() -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = UITheme.BG_PANEL
	frame.set_border_width_all(2)
	frame.border_color = UITheme.GOLD_DIM
	frame.set_corner_radius_all(6)
	_frame.add_theme_stylebox_override("panel", frame)

	var bar := StyleBoxFlat.new()
	bar.bg_color = UITheme.W95_TITLEBAR2  # #2e2010, the gradient's light end
	bar.border_width_bottom = 2
	bar.border_color = UITheme.GOLD_DIM
	bar.corner_radius_top_left = 6
	bar.corner_radius_top_right = 6
	bar.content_margin_left = 20
	bar.content_margin_right = 16
	bar.content_margin_top = 12
	bar.content_margin_bottom = 12
	_titlebar.add_theme_stylebox_override("panel", bar)

	_title.add_theme_font_override("font", UITheme.font_at("title", 700))
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", UITheme.GOLD)

	_close_button.add_theme_stylebox_override("normal", _ghost_style(Color(0, 0, 0, 0), UITheme.GOLD_DIM))
	_close_button.add_theme_stylebox_override("hover", _ghost_style(Color(0.831, 0.659, 0.294, 0.1), UITheme.GOLD))
	_close_button.add_theme_stylebox_override("pressed", _ghost_style(Color(0.831, 0.659, 0.294, 0.1), UITheme.GOLD))
	_close_button.add_theme_color_override("font_color", UITheme.GOLD)
	_close_button.add_theme_color_override("font_hover_color", UITheme.GOLD)

	var cred := StyleBoxFlat.new()
	cred.bg_color = Color(0, 0, 0, 0)
	cred.border_width_bottom = 1
	cred.border_color = GOLD_A18
	cred.content_margin_top = 10
	cred.content_margin_bottom = 10
	_credits_panel.add_theme_stylebox_override("panel", cred)
	_credits.add_theme_font_override("font", UITheme.font("pixel"))
	_credits.add_theme_font_size_override("font_size", 16)
	_credits.add_theme_color_override("font_color", UITheme.GOLD)

	var nav := StyleBoxFlat.new()
	nav.bg_color = Color(0, 0, 0, 0)
	nav.border_width_right = 1
	nav.border_color = GOLD_A18
	nav.content_margin_left = 10
	nav.content_margin_right = 10
	nav.content_margin_top = 14
	nav.content_margin_bottom = 14
	_nav.add_theme_stylebox_override("panel", nav)


## Prev/Next strip at the bottom of the panel, the .compendium-page-nav footer.
func _build_footer() -> void:
	_footer = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_width_top = 1
	box.border_color = GOLD_A18
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	_footer.add_theme_stylebox_override("panel", box)

	var row := HBoxContainer.new()
	_footer.add_child(row)

	var prev := _footer_button("← Prev")
	prev.pressed.connect(func(): _step_page(-1))
	row.add_child(prev)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var next := _footer_button("Next →")
	next.pressed.connect(func(): _step_page(1))
	row.add_child(next)

	_col.add_child(_footer)


func _footer_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", UITheme.font("pixel"))
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", UITheme.GOLD)
	b.add_theme_color_override("font_hover_color", UITheme.GOLD)
	b.add_theme_stylebox_override("normal", _unlock_style(Color(0, 0, 0, 0), Color(0.831, 0.659, 0.294, 0.4)))
	b.add_theme_stylebox_override("hover", _unlock_style(Color(0.831, 0.659, 0.294, 0.12), UITheme.GOLD))
	b.add_theme_stylebox_override("pressed", _unlock_style(Color(0.831, 0.659, 0.294, 0.12), UITheme.GOLD))
	return b


## Cycles through every entry, wrapping around — compendiumPrev/Next.
func _step_page(delta: int) -> void:
	var n := _entries.size()
	if n == 0:
		return
	_selected = (_selected + delta + n) % n
	_page_scroll.scroll_vertical = 0
	_refresh()


func _ghost_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(5)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


func _entry_unlocked(entry: Dictionary) -> bool:
	# The web build shows an entry (not the silhouette) when it is flagged
	# unlocked OR revealed: `if(!p.revealed && !p.unlocked) locked`.
	return bool(entry.get("unlocked", false)) or _entry_revealed(entry)


func _entry_revealed(entry: Dictionary) -> bool:
	if bool(entry.get("revealed", false)):
		return true
	return SaveManager.is_patron_revealed(String(entry["id"]))


func _lore_unlocked(entry: Dictionary) -> bool:
	return SaveManager.has_seen("unlocked_connections", String(entry["id"]))


func _display_name(entry: Dictionary) -> String:
	if _entry_revealed(entry) and entry.has("true_name"):
		return String(entry["true_name"])
	return String(entry["name"])


## John Dee's link to Solitaire only becomes purchasable after his third
## transmission, matching connectionAvailable in the web build.
func _connection_available(entry: Dictionary) -> bool:
	if String(entry["id"]) == "johndee":
		return bool(SaveManager.profile.get("dee_dialogue3_done", false))
	return true


func _refresh() -> void:
	_credits.text = "⚡ Time Energy: %d" % int(SaveManager.profile.get("banked_credits", 0))

	for child in _list.get_children():
		child.queue_free()

	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var visible := _entry_unlocked(entry)
		var button := Button.new()
		button.text = _display_name(entry) if visible else "Unknown Patron"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		if visible and entry.has("img"):
			button.icon = load(String(entry["img"]))
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 28)
		elif not visible:
			button.text = "🔒  Unknown Patron"
		var idx := i
		button.pressed.connect(func():
			_selected = idx
			_page_scroll.scroll_vertical = 0
			_refresh())
		_style_nav_item(button, i == _selected, visible)
		_list.add_child(button)

	_build_timeline()
	_build_page()


## Cinzel nav entry: transparent normally, gold-outlined when active — the
## .compendium-nav-item / .active rules.
func _style_nav_item(button: Button, active: bool, visible: bool) -> void:
	button.add_theme_font_override("font", UITheme.font_at("display", 500))
	button.add_theme_font_size_override("font_size", 15)
	var fg := UITheme.GOLD if active else UITheme.TEXT
	if not visible:
		fg = Color(UITheme.TEXT, 0.6)  # .locked { opacity:.6 }
	button.add_theme_color_override("font_color", fg)
	button.add_theme_color_override("font_hover_color", UITheme.GOLD if visible else fg)
	button.add_theme_color_override("font_pressed_color", UITheme.GOLD)
	button.disabled = not visible
	button.add_theme_color_override("font_disabled_color", fg)

	var normal := _nav_item_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0))
	if active:
		normal = _nav_item_style(Color(0.831, 0.659, 0.294, 0.14), UITheme.GOLD)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _nav_item_style(Color(0.831, 0.659, 0.294, 0.1), Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("pressed", _nav_item_style(Color(0.831, 0.659, 0.294, 0.14), UITheme.GOLD))
	button.add_theme_stylebox_override("disabled", normal)


func _nav_item_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


# ══════════════════════════════════════════════════════════════════════════════
#  Timeline of Civilization
# ══════════════════════════════════════════════════════════════════════════════

func _index_of_id(id: String) -> int:
	for i in _entries.size():
		if String(_entries[i]["id"]) == id:
			return i
	return _selected


func _fmt_year(y: int) -> String:
	return "%d BC" % absi(y) if y < 0 else str(y)


## Every discovered entry that carries a year, oldest first. The web timeline
## filters on (revealed||unlocked) && year!=null and sorts ascending.
func _timeline_entries() -> Array:
	var visible: Array = []
	for entry in _entries:
		if _entry_unlocked(entry) and entry.has("year"):
			visible.append(entry)
	visible.sort_custom(func(a, b): return int(a["year"]) < int(b["year"]))
	return visible


func _build_timeline() -> void:
	var sep := HSeparator.new()
	var sep_box := StyleBoxLine.new()
	sep_box.color = GOLD_A18
	sep_box.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_box)
	sep.add_theme_constant_override("separation", 14)
	_list.add_child(sep)

	var heading := Label.new()
	heading.text = "TIMELINE OF CIVILIZATION"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", UITheme.font_at("display", 600))
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", UITheme.GOLD)
	_list.add_child(heading)

	var track := VBoxContainer.new()
	track.alignment = BoxContainer.ALIGNMENT_CENTER
	track.add_theme_constant_override("separation", 0)
	_list.add_child(track)

	var tl := _timeline_entries()
	if tl.is_empty():
		var empty := Label.new()
		empty.text = "No connections to the historical record have been uncovered yet."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_override("font", UITheme.font("body"))
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", UITheme.TEXT)
		track.add_child(empty)
		return

	for i in tl.size():
		var entry: Dictionary = tl[i]
		if i > 0:
			var linked := _linked(tl[i - 1], entry)
			track.add_child(_timeline_line(linked))
		track.add_child(_timeline_node(entry))


## Two entries are linked when either lists the other in its `links`.
func _linked(a: Dictionary, b: Dictionary) -> bool:
	var la: Array = a.get("links", [])
	var lb: Array = b.get("links", [])
	return la.has(String(b["id"])) or lb.has(String(a["id"]))


func _timeline_line(linked: bool) -> Control:
	var line := Panel.new()
	line.custom_minimum_size = Vector2(3 if linked else 2, 20)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var s := StyleBoxFlat.new()
	s.bg_color = UITheme.GOLD if linked else UITheme.GOLD_DIM
	line.add_theme_stylebox_override("panel", s)
	return line


func _timeline_node(entry: Dictionary) -> Control:
	var wrap := VBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 4)

	var active := String(_entries[_selected]["id"]) == String(entry["id"])
	var dot := Button.new()
	dot.custom_minimum_size = Vector2(14, 14)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dot.tooltip_text = "%s (%s)" % [_display_name(entry), _fmt_year(int(entry["year"]))]
	var dot_bg := UITheme.GOLD if active else Color("15101e")
	dot.add_theme_stylebox_override("normal", _dot_style(dot_bg))
	dot.add_theme_stylebox_override("hover", _dot_style(dot_bg, true))
	dot.add_theme_stylebox_override("pressed", _dot_style(UITheme.GOLD))
	var target_id := String(entry["id"])
	dot.pressed.connect(func():
		_selected = _index_of_id(target_id)
		_page_scroll.scroll_vertical = 0
		_refresh())
	wrap.add_child(dot)

	var label := Label.new()
	label.text = _display_name(entry)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UITheme.font("pixel"))
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", UITheme.TEXT)
	wrap.add_child(label)

	var year := Label.new()
	year.text = _fmt_year(int(entry["year"]))
	year.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	year.add_theme_font_override("font", UITheme.font("pixel"))
	year.add_theme_font_size_override("font_size", 9)
	year.add_theme_color_override("font_color", UITheme.GOLD)
	wrap.add_child(year)

	return wrap


func _dot_style(bg: Color, glow := false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(7)
	s.set_border_width_all(2)
	s.border_color = UITheme.GOLD if (glow or bg == UITheme.GOLD) else UITheme.GOLD_DIM
	return s


# ══════════════════════════════════════════════════════════════════════════════
#  Entry page
# ══════════════════════════════════════════════════════════════════════════════

func _build_page() -> void:
	for child in _page.get_children():
		child.queue_free()

	if _selected < 0 or _selected >= _entries.size():
		return
	var entry: Dictionary = _entries[_selected]

	if not _entry_unlocked(entry):
		_add_entry_head(entry, false)
		_add_paragraph("This Time Patron has not yet revealed themselves to you.")
		return

	_add_entry_head(entry, true)

	if bool(entry.get("in_development", false)):
		_add_dev_note()

	for para in entry.get("bio", []):
		_add_paragraph(String(para))

	# Web section order: bio → connection (lore) → dialogue → strategy.
	if entry.has("lore"):
		_add_connection_section(entry)

	if String(entry["id"]) == "johndee":
		_add_dee_transmissions()

	if entry.has("strategy"):
		_add_heading(String(entry.get("strategy_title", "Strategy")))
		for para in entry["strategy"]:
			_add_paragraph(String(para))


## The .compendium-entry-head: a 64px portrait beside the entry name.
func _add_entry_head(entry: Dictionary, visible: bool) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)

	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(64, 64)
	var pbox := StyleBoxFlat.new()
	pbox.bg_color = Color("15101e")
	pbox.set_border_width_all(2)
	pbox.border_color = UITheme.GOLD_DIM
	pbox.set_corner_radius_all(5)
	portrait.add_theme_stylebox_override("panel", pbox)
	if visible and entry.has("img"):
		var tex := TextureRect.new()
		tex.texture = load(String(entry["img"]))
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.custom_minimum_size = Vector2(60, 60)
		portrait.add_child(tex)
	else:
		var lock := Label.new()
		lock.text = "🔒"
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		portrait.add_child(lock)
	head.add_child(portrait)

	var name_label := Label.new()
	name_label.text = _display_name(entry) if visible else "Unknown Patron"
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_override("font", UITheme.font_at("title", 700))
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", UITheme.GOLD)
	head.add_child(name_label)

	_page.add_child(head)


func _add_heading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UITheme.font_at("display", 600))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", UITheme.GOLD)
	_page.add_child(label)


## The italic .compendium-subsection-title used inside Recorded Transmissions.
func _add_subheading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UITheme.font_at("title", 400))
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UITheme.GOLD)
	_page.add_child(label)


func _add_paragraph(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UITheme.font("body"))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", PAGE_TEXT)
	_page.add_child(label)


func _add_connection_section(entry: Dictionary) -> void:
	_add_heading("Connection to Solitaire")

	if _lore_unlocked(entry):
		for para in entry["lore"]:
			_add_paragraph(String(para))
		return

	if not _connection_available(entry):
		_add_paragraph("This thread is not yet visible to you. Keep descending.")
		return

	var cost := int(entry.get("connection_cost", 500))
	_add_paragraph("This thread can be uncovered for %d Time Energy." % cost)

	var button := Button.new()
	var banked := int(SaveManager.profile.get("banked_credits", 0))
	button.text = "UNCOVER (%d ⚡)" % cost if banked >= cost \
		else "NEED %d MORE ⚡" % (cost - banked)
	button.disabled = banked < cost
	button.pressed.connect(func():
		if SaveManager.spend_banked_credits(cost):
			SaveManager.mark_seen("unlocked_connections", String(entry["id"]))
			SaveManager.mark_compendium_seen()
			SaveManager.save_game()
			RunState.toast.emit("A thread comes loose.")
			_refresh())
	_style_unlock_button(button)
	_page.add_child(button)


# ══════════════════════════════════════════════════════════════════════════════
#  John Dee — Recorded Transmissions
# ══════════════════════════════════════════════════════════════════════════════

## Transcripts of every conversation with John Dee the player has reached, with
## the not-yet-reached ones shown as locked blocks. Ported from
## deeCompendiumDialogueHTML in index.html.
func _add_dee_transmissions() -> void:
	_add_heading("Recorded Transmissions")

	_add_subheading("The First Contact")
	_add_transcript(Narrative.DEE_DIALOGUE)

	_add_subheading("A Moment's Respite")
	_add_seen_topics(Narrative.DEE_CHECKIN_TOPICS, "seen_dee_topics")

	_add_subheading("More Than Halfway")
	_add_seen_topics(Narrative.DEE_DIALOGUE3_TOPICS, "seen_dee3_topics")

	_add_subheading("The Final Threshold")
	if bool(SaveManager.profile.get("dee_final_done", false)):
		_add_transcript(Narrative.DEE_FINAL)
	else:
		_add_locked_block("You have not yet reached this moment in your journey.")


func _add_seen_topics(topics: Array, seen_key: String) -> void:
	var any := false
	for topic in topics:
		if SaveManager.has_seen(seen_key, String(topic["id"])):
			any = true
			_add_topic_question(String(topic["question"]))
			_add_transcript(topic["beats"])
	if not any:
		_add_locked_block("You have not yet reached this moment in your journey.")


## Renders a run of dialogue beats: narration in italic, spoken lines prefixed
## with the speaker. Ported from dialogueTranscriptHTML.
func _add_transcript(beats: Array) -> void:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 8)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0.22)
	box.set_border_width_all(1)
	box.border_color = GOLD_A18
	box.set_corner_radius_all(5)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.add_child(block)

	for beat in beats:
		var is_narration := bool(beat.get("scene", false)) or String(beat.get("speaker", "")) == "scene"
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_override("font", UITheme.font("body"))
		line.add_theme_font_size_override("font_size", 18)
		if is_narration:
			line.text = String(beat.get("text", ""))
			line.add_theme_color_override("font_color", Color(UITheme.TEXT, 0.85))
		elif beat.has("choices"):
			line.text = "You: " + ", ".join(_as_string_array(beat["choices"]))
			line.add_theme_color_override("font_color", PAGE_TEXT)
		else:
			var label := "Dee" if String(beat.get("speaker", "")) == "dee" else "You"
			line.text = "%s: %s" % [label, _beat_text(beat)]
			line.add_theme_color_override("font_color", PAGE_TEXT)
		block.add_child(line)

	_page.add_child(panel)


## A beat's `text` is usually a String, but a couple of "you" beats in the web
## data are single-element arrays; normalise both.
func _beat_text(beat: Dictionary) -> String:
	var t = beat.get("text", "")
	if t is Array:
		return ", ".join(_as_string_array(t))
	return String(t)


func _as_string_array(a) -> PackedStringArray:
	var out := PackedStringArray()
	for v in a:
		out.append(String(v))
	return out


func _add_topic_question(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UITheme.font("pixel"))
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UITheme.GOLD)
	_page.add_child(label)


func _add_locked_block(text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0.25)
	box.set_border_width_all(1)
	box.border_color = Color(0.831, 0.659, 0.294, 0.3)
	box.set_corner_radius_all(5)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.add_child(row)

	var icon := Label.new()
	icon.text = "🔒"
	icon.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
	row.add_child(icon)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", UITheme.font("body"))
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UITheme.TEXT)
	row.add_child(label)

	_page.add_child(panel)


## Gold-outlined "uncover" button, the .compendium-unlock-btn rule.
func _style_unlock_button(button: Button) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_override("font", UITheme.font("pixel"))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", UITheme.GOLD)
	button.add_theme_color_override("font_hover_color", UITheme.GOLD)
	button.add_theme_color_override("font_pressed_color", UITheme.GOLD)
	button.add_theme_color_override("font_disabled_color", Color("555555"))
	button.add_theme_stylebox_override("normal", _unlock_style(Color(0.831, 0.659, 0.294, 0.1), Color(0.831, 0.659, 0.294, 0.4)))
	button.add_theme_stylebox_override("hover", _unlock_style(Color(0.831, 0.659, 0.294, 0.2), UITheme.GOLD))
	button.add_theme_stylebox_override("pressed", _unlock_style(Color(0.831, 0.659, 0.294, 0.2), UITheme.GOLD))
	button.add_theme_stylebox_override("disabled", _unlock_style(Color(0.2, 0.2, 0.2, 0.3), Color("333333")))


func _unlock_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(4)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


## In-development patrons show a note and cannot be selected or bought. Ported
## from the web build's devHTML — patron_unlock_cost exists in the data but its
## purchase flow was never implemented (tryUnlockPatron bails on inDevelopment),
## so there is deliberately no unlock button here.
func _add_dev_note() -> void:
	var note := Label.new()
	note.text = "⚙ This Time Patron is still in development and cannot yet be selected."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_override("font", UITheme.font("body"))
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", UITheme.GOLD)
	_page.add_child(note)
