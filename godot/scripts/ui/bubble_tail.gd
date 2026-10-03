class_name BubbleTail
extends MarginContainer

## A speech bubble's pointy tail, drawn in _draw so it cannot be resized by the
## layout the way a Panel child would be. Extends MarginContainer, whose margin
## on the pointing side reserves the space the triangle is painted into.
##   "left"  — points left toward a portrait beside the bubble (John Dee's lines)
##   "right" — points right toward a portrait beside the bubble (the table coach)
##   "down"  — points down toward the viewer (the player's lines)
## The base of the triangle overlaps a few pixels into the bubble so the white
## fill blends over the bubble's black border, and only the two outer edges are
## outlined — so it reads as a real comic-book tail, not a square notch.
##
## Shared by the dialogue screen and the table-side patron coach.

const REACH := 22.0   # how far the point sticks out past the bubble
const SPREAD := 28.0  # width of the tail where it meets the bubble

var dir := "left"
## Where the tail leaves the bubble, measured along the pointing edge: from the
## top for "left"/"right", from the left for "down". The coach's bubble is wide
## and short, so it points from low on its edge rather than from the top corner.
var offset := 26.0


## Reserves the margin the triangle is painted into. Call after setting `dir`.
func apply_margin() -> void:
	match dir:
		"down": add_theme_constant_override("margin_bottom", int(REACH))
		"right": add_theme_constant_override("margin_right", int(REACH))
		_: add_theme_constant_override("margin_left", int(REACH))


func _draw() -> void:
	var fill := Color.WHITE
	var line := Color.BLACK
	var overlap := 4.0  # push the base into the bubble to cover its border
	match dir:
		"down":
			var dy := size.y - REACH
			_tail(Vector2(offset, dy - overlap), Vector2(offset + SPREAD, dy - overlap),
				Vector2(offset + SPREAD * 0.4, size.y - 1.0), fill, line)
		"right":
			var rx := size.x - REACH
			_tail(Vector2(rx - overlap, offset), Vector2(rx - overlap, offset + SPREAD),
				Vector2(size.x - 1.0, offset + SPREAD * 0.4), fill, line)
		_:  # left
			_tail(Vector2(REACH + overlap, offset), Vector2(REACH + overlap, offset + SPREAD),
				Vector2(1.0, offset + SPREAD * 0.4), fill, line)


func _tail(a: Vector2, b: Vector2, tip: Vector2, fill: Color, line: Color) -> void:
	draw_colored_polygon([a, b, tip], fill)
	draw_line(a, tip, line, 3.0)
	draw_line(b, tip, line, 3.0)
