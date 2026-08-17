extends Node
# Drives real mouse events through the game screen to prove drag-and-drop moves
# a card. Run under Xvfb. Builds a rigged Klondike board with a guaranteed legal
# tableau move, then presses on the source card, moves the cursor to the target
# column, and releases.

var _pass := 0
var _fail := 0

func ck(cond: bool, desc: String) -> void:
	if cond: _pass += 1
	else: _fail += 1; print("  FAIL: ", desc)

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame
	RunState.new_run()
	RunState.start_game("klondike", 4)

	# Rig a trivially legal move: a red 6 on column 0 top, a black 7 on column 1
	# top. The 6 should drop onto the 7.
	var gs := RunState.gs
	gs["tableau"][0] = [Cards.make_card(Cards.Suit.HEARTS, 6, true)]
	gs["tableau"][1] = [Cards.make_card(Cards.Suit.SPADES, 7, true)]
	RunState.gs = gs

	var screen: PackedScene = load("res://scenes/screens/game_screen.tscn")
	var view = screen.instantiate()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	for i in 6: await get_tree().process_frame

	# Find the source (H6 on col 0) and target (S7 on col 1) card views.
	var board: Control = view.get_node("Board")
	var src: Control = null
	var dst: Control = null
	for c in board.get_children():
		if not (c is Control): continue
		var m: Dictionary = c.get_meta("slot", {})
		if m.get("kind") == "tableau" and m.get("col") == 0: src = c
		if m.get("kind") == "tableau" and m.get("col") == 1: dst = c
	ck(src != null, "found source card")
	ck(dst != null, "found target card")
	if src == null or dst == null:
		_finish(); return

	var col1_before: int = RunState.gs["tableau"][1].size()

	var from := src.get_global_rect().get_center()
	var to := dst.get_global_rect().get_center()

	# Press on source, drag to target in steps, release.
	_send_button(from, true)
	await get_tree().process_frame
	for t in range(1, 9):
		_send_motion(from.lerp(to, t / 8.0))
		await get_tree().process_frame
	_send_button(to, false)
	await get_tree().process_frame
	await get_tree().process_frame

	var col1_after: int = RunState.gs["tableau"][1].size()
	var col0_after: int = RunState.gs["tableau"][0].size()
	ck(col1_after == col1_before + 1, "target column gained the dragged card (%d -> %d)" % [col1_before, col1_after])
	ck(col0_after == 0, "source column is now empty")
	if col1_after == col1_before + 1:
		var top: Dictionary = RunState.gs["tableau"][1][col1_after - 1]
		ck(top["rank"] == 6 and top["suit"] == Cards.Suit.HEARTS, "the moved card is the red 6")

	# A drag to an illegal target must snap back. Put a black 6 on col 2; drag
	# col1 top (now red 6) onto it — same colour, illegal.
	var gs2 := RunState.gs
	gs2["tableau"][2] = [Cards.make_card(Cards.Suit.CLUBS, 6, true)]
	RunState.gs = gs2
	view._rebuild()
	await get_tree().process_frame
	var src2: Control = null
	var dst2: Control = null
	for c in board.get_children():
		if not (c is Control): continue
		var m: Dictionary = c.get_meta("slot", {})
		if m.get("kind") == "tableau" and m.get("col") == 1: src2 = c
		if m.get("kind") == "tableau" and m.get("col") == 2: dst2 = c
	if src2 and dst2:
		var col1b: int = RunState.gs["tableau"][1].size()
		var f := src2.get_global_rect().get_center()
		var t2 := dst2.get_global_rect().get_center()
		_send_button(f, true)
		await get_tree().process_frame
		for t in range(1, 9):
			_send_motion(f.lerp(t2, t / 8.0))
			await get_tree().process_frame
		_send_button(t2, false)
		await get_tree().process_frame
		ck(RunState.gs["tableau"][1].size() == col1b, "illegal drag snapped back (no change)")

	_finish()

func _to_window(pos: Vector2) -> Vector2:
	# Control global coords are in the stretched canvas; push_input wants window
	# coords, which the viewport then transforms back into canvas space.
	var win := Vector2(get_window().size)
	var canvas := get_viewport().get_visible_rect().size
	return pos * (win / canvas)

func _send_button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = _to_window(pos)
	get_viewport().push_input(e)

func _send_motion(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = _to_window(pos)
	get_viewport().push_input(e)

func _finish() -> void:
	print("DRAG passed=%d failed=%d" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
