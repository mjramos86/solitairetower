class_name BevelStyleBox
extends StyleBox

## An authentic two-tone Windows-95 bevel, the one thing StyleBoxFlat cannot do:
## Godot's flat box has a single border colour, but the Win95 look needs a light
## top-left edge and a dark bottom-right edge (or the reverse, for a sunken well).
## This draws them by hand, reproducing the CSS `border-color: white darker
## darker white` idiom the web build used on every window, button and pane.

@export var bg_color: Color = Color("c0c0c0")
@export var light_color: Color = Color("ffffff")
@export var dark_color: Color = Color("404040")
## Border thickness in pixels, matching the CSS `border:Npx`.
@export var bevel_width: float = 2.0
## When true the light and dark edges swap, giving a pressed / inset well.
@export var sunken: bool = false


func _init(bg := Color("c0c0c0"), width := 2.0, is_sunken := false,
		light := Color("ffffff"), dark := Color("404040")) -> void:
	bg_color = bg
	bevel_width = width
	sunken = is_sunken
	light_color = light
	dark_color = dark


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	# Top-left and bottom-right colours; sunken swaps them so the same box can be
	# a raised button or a sunken board with one flag.
	var tl := dark_color if sunken else light_color
	var br := light_color if sunken else dark_color
	var w := bevel_width

	RenderingServer.canvas_item_add_rect(to_canvas_item, rect, bg_color)

	# Bottom and right first, then top and left on top, so the light corner wins.
	RenderingServer.canvas_item_add_rect(to_canvas_item,
		Rect2(rect.position.x, rect.position.y + rect.size.y - w, rect.size.x, w), br)
	RenderingServer.canvas_item_add_rect(to_canvas_item,
		Rect2(rect.position.x + rect.size.x - w, rect.position.y, w, rect.size.y), br)
	RenderingServer.canvas_item_add_rect(to_canvas_item,
		Rect2(rect.position.x, rect.position.y, rect.size.x, w), tl)
	RenderingServer.canvas_item_add_rect(to_canvas_item,
		Rect2(rect.position.x, rect.position.y, w, rect.size.y), tl)
