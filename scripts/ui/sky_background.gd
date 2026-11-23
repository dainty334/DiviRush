# The sky behind every screen, with shapes floating over it (D-009 "lively screens").
# Each area of the game and each Episode has its own look, so the screens do not all look the same (D-020).
# Drawn in code each frame, which is lighter than one animated node per shape.
class_name SkyBackground  # Lets screens write SkyBackground.new(SkyBackground.Look.MEADOW).
extends Control  # A UI node that can draw.

enum Look { MENU, SELECT, DAY, MEADOW, SUNSET, NIGHT }  # The six looks (D-020).
enum Shape { BUBBLE, STAR, DIVIDE, LEAF, SPARKLE, TWINKLE }  # The shapes that can float over a sky.

# Each look: its sky colours (top and bottom), its floating shapes and how many, how they move
# ("rise" 1 = up at full speed, a minus number = falling, near 0 = almost still), their colour
# ("tint"), and one extra picture ("sun", "hills", "low_sun", "moon", or "" for none).
const LOOKS := {  # Look -> its settings.
	Look.MENU: {"top": Palette.SKY_TOP, "bottom": Palette.SKY_BOTTOM, "shapes": [Shape.BUBBLE], "count": 16, "rise": 1.0, "tint": Color("#FFFFFF"), "extra": ""},  # Main menu area: blue sky, white bubbles.
	Look.SELECT: {"top": Color("#5EE6C8"), "bottom": Color("#138A9E"), "shapes": [Shape.STAR, Shape.DIVIDE], "count": 14, "rise": 0.5, "tint": Color("#FFFFFF"), "extra": ""},  # Selection screens: teal sky, stars and ÷ signs.
	Look.DAY: {"top": Color("#BDF0FF"), "bottom": Color("#4FA8F5"), "shapes": [Shape.BUBBLE], "count": 12, "rise": 0.8, "tint": Color("#FFFFFF"), "extra": "sun"},  # Episode 1: light day sky, bubbles, a sun.
	Look.MEADOW: {"top": Color("#D4F58A"), "bottom": Color("#4CB050"), "shapes": [Shape.LEAF], "count": 14, "rise": -0.6, "tint": Color("#F4FFB8"), "extra": "hills"},  # Episode 2: green meadow, falling leaves, hills.
	Look.SUNSET: {"top": Color("#FFC46B"), "bottom": Color("#EE5A7A"), "shapes": [Shape.SPARKLE], "count": 16, "rise": 0.4, "tint": Color("#FFF7D6"), "extra": "low_sun"},  # Episode 3: orange-pink sunset, sparkles, a low sun.
	Look.NIGHT: {"top": Color("#3F2A9C"), "bottom": Color("#160B45"), "shapes": [Shape.TWINKLE], "count": 30, "rise": 0.08, "tint": Color("#FFF3B0"), "extra": "moon"},  # Episode 4: purple night, twinkling stars, a moon.
}  # End of the list.

var look: int = Look.MENU  # This background's look.
var _shapes: Array[Dictionary] = []  # Each shape: x, y, r (size), speed, phase, kind, angle, spin, ring.
var _time := 0.0  # Seconds since the screen opened, for swaying and twinkling.
var _gradient := Gradient.new()  # The sky colours, also used to colour the moon's shadow.
var _sky := GradientTexture2D.new()  # The sky picture, blended from the top colour to the bottom colour.


# Runs when the background is made: remembers which look to draw.
func _init(chosen_look: int = Look.MENU) -> void:
	look = chosen_look  # The look to draw.


# Returns the world look of an Episode: 1 day, 2 meadow, 3 sunset, 4 night (D-020).
static func for_episode(episode: int) -> int:
	var worlds := [Look.DAY, Look.MEADOW, Look.SUNSET, Look.NIGHT]  # Episodes 1 to 4.
	return worlds[clampi(episode, 1, worlds.size()) - 1]  # That Episode's world.


# Runs when the background is added to a screen: fills the screen, paints the sky and makes the first shapes.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Cover the whole screen, with no gaps at the edges.
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never block taps.
	var setup: Dictionary = LOOKS[look]  # This look's settings.
	_gradient.set_color(0, setup.top)  # Top colour ...
	_gradient.set_color(1, setup.bottom)  # ... and bottom colour of the sky.
	_sky.gradient = _gradient  # Use the blend in the sky picture.
	_sky.fill_from = Vector2(0.5, 0.0)  # Blend starts at the top middle ...
	_sky.fill_to = Vector2(0.5, 1.0)  # ... and ends at the bottom middle.
	_sky.width = 4  # A tiny picture is enough; it is stretched to fill the screen.
	_sky.height = 256  # Enough steps for a smooth blend from top to bottom.
	for i in range(setup.count):  # Make each shape ...
		_shapes.append(_new_shape(false))  # ... anywhere on screen to start.


# Makes one shape. A new shape starts just off screen (below if it rises, above if it falls);
# the first ones start anywhere.
func _new_shape(from_edge: bool) -> Dictionary:
	var area := get_viewport_rect().size  # Screen size.
	var setup: Dictionary = LOOKS[look]  # This look's settings.
	var kind: int = setup.shapes.pick_random()  # Which shape.
	var radius := _size_of(kind)  # How big.
	var y := randf_range(0.0, area.y)  # Anywhere up and down ...
	if from_edge:  # ... unless it is a new shape:
		y = area.y + radius if setup.rise >= 0.0 else -radius  # below the screen if it rises, above if it falls.
	return {  # The shape's values.
		"x": randf_range(0.0, area.x),  # Across the screen.
		"y": y,  # Up and down.
		"r": radius,  # Size.
		"speed": randf_range(30.0, 90.0),  # Pixels per second (times the look's "rise").
		"phase": randf() * TAU,  # Start point of the sway and the twinkle.
		"kind": kind,  # Which shape.
		"angle": randf() * TAU,  # How far it is turned.
		"spin": randf_range(-0.8, 0.8),  # How fast it turns, in radians per second.
		"ring": randf() < 0.3,  # For bubbles: about 1 in 3 is an outline ring instead of a filled bubble.
	}  # End of the list.


# Returns a random size for a shape, so each kind looks right (big bubbles, small night stars).
func _size_of(kind: int) -> float:
	match kind:  # Each kind has its own size range.
		Shape.BUBBLE:  # Bubbles ...
			return randf_range(14.0, 90.0)  # ... small to big.
		Shape.STAR, Shape.DIVIDE:  # Stars and ÷ signs ...
			return randf_range(20.0, 46.0)  # ... middle-sized.
		Shape.LEAF:  # Leaves ...
			return randf_range(18.0, 34.0)  # ... small to middle.
		Shape.SPARKLE:  # Sparkles ...
			return randf_range(10.0, 30.0)  # ... small.
	return randf_range(3.0, 9.0)  # Night stars are tiny.


# Runs every frame: moves and turns the shapes, starts new ones when they leave, and redraws.
func _process(delta: float) -> void:
	_time += delta  # Count time for the sway and the twinkle.
	var area := get_viewport_rect().size  # Screen size.
	var rise: float = LOOKS[look].rise  # How this look's shapes move.
	for i in range(_shapes.size()):  # Each shape ...
		var shape := _shapes[i]  # ... take it,
		shape.y -= shape.speed * rise * delta  # ... move it up (or down when "rise" is below 0),
		shape.angle += shape.spin * delta  # ... turn it a little,
		if (rise >= 0.0 and shape.y < -shape.r) or (rise < 0.0 and shape.y > area.y + shape.r):  # ... and once it leaves the screen,
			_shapes[i] = _new_shape(true)  # ... start a new one at the other edge.
	queue_redraw()  # Draw again with the new positions.


# Draws the sky, the look's extra picture, and every shape.
func _draw() -> void:
	draw_texture_rect(_sky, Rect2(Vector2.ZERO, size), false)  # The sky, stretched over the whole screen.
	_draw_extra(LOOKS[look].extra)  # The sun, hills, low sun or moon.
	var tint: Color = LOOKS[look].tint  # The shapes' colour.
	for shape in _shapes:  # Each shape ...
		var sway := sin(_time * 0.8 + shape.phase) * (24.0 if shape.kind == Shape.LEAF else 12.0)  # ... sways side to side (leaves more),
		_draw_shape(shape, Vector2(shape.x + sway, shape.y), tint)  # ... and is drawn there.


# Draws one shape at a point, in the look's colour.
func _draw_shape(shape: Dictionary, at: Vector2, tint: Color) -> void:
	var r: float = shape.r  # Its size.
	match shape.kind:  # Each kind is drawn its own way.
		Shape.BUBBLE:  # A bubble ...
			if shape.ring:  # ... as a thin ring,
				draw_arc(at, r, 0.0, TAU, 48, Color(tint, 0.35), 6.0, true)  # ... a see-through white ring,
			else:  # ... or filled,
				draw_circle(at, r, Color(tint, 0.18), true, -1.0, true)  # ... a soft see-through circle.
		Shape.STAR:  # A five-point star.
			draw_colored_polygon(_star_points(at, r, 5, 0.48, shape.angle), Color(tint, 0.4))  # See-through star.
		Shape.DIVIDE:  # A ÷ sign, turned by its angle.
			draw_set_transform(at, shape.angle)  # Draw around its middle, turned.
			var colour := Color(tint, 0.4)  # See-through colour.
			draw_circle(Vector2(0.0, -r * 0.55), r * 0.17, colour, true, -1.0, true)  # Top dot.
			draw_rect(Rect2(-r * 0.6, -r * 0.13, r * 1.2, r * 0.26), colour)  # Bar.
			draw_circle(Vector2(0.0, r * 0.55), r * 0.17, colour, true, -1.0, true)  # Bottom dot.
			draw_set_transform(Vector2.ZERO)  # Back to normal drawing.
		Shape.LEAF:  # A leaf, turned by its angle.
			draw_set_transform(at, shape.angle)  # Draw around its middle, turned.
			draw_colored_polygon(_leaf_points(r), Color(tint, 0.6))  # The leaf.
			draw_line(Vector2(0.0, -r * 0.8), Vector2(0.0, r * 0.9), Color(Palette.INK, 0.15), 2.0, true)  # Its middle line.
			draw_set_transform(Vector2.ZERO)  # Back to normal drawing.
		Shape.SPARKLE:  # A four-point sparkle that glows brighter and softer.
			var glow := 0.45 + 0.35 * sin(_time * 2.2 + shape.phase)  # 0.1 to 0.8.
			draw_colored_polygon(_star_points(at, r, 4, 0.3, shape.angle), Color(tint, glow))  # The sparkle.
		_:  # A tiny night star that twinkles.
			var twinkle := 0.55 + 0.4 * sin(_time * 2.0 + shape.phase * 3.0)  # 0.15 to 0.95.
			draw_colored_polygon(_star_points(at, r * 1.6, 4, 0.35, 0.0), Color(tint, twinkle))  # The twinkle.


# Draws the look's one extra picture: a sun (day), hills (meadow), a low sun (sunset) or a moon (night).
func _draw_extra(extra: String) -> void:
	match extra:  # Each picture is drawn its own way.
		"sun":  # A warm sun at the top right, with a soft glow.
			var sun := Vector2(size.x * 0.84, size.y * 0.1)  # Where it sits.
			draw_circle(sun, 170.0, Color("#FFE066", 0.18), true, -1.0, true)  # Wide glow.
			draw_circle(sun, 120.0, Color("#FFE066", 0.35), true, -1.0, true)  # Near glow.
			draw_circle(sun, 84.0, Color("#FFE066", 0.95), true, -1.0, true)  # The sun.
		"hills":  # Two soft green hills along the bottom.
			draw_set_transform(Vector2(size.x * 0.2, size.y * 1.04), 0.0, Vector2(1.0, 0.32))  # A flattened circle is a hill.
			draw_circle(Vector2.ZERO, size.x * 0.62, Color("#2E8B3E", 0.5), true, -1.0, true)  # Left hill.
			draw_set_transform(Vector2(size.x * 0.88, size.y * 1.05), 0.0, Vector2(1.0, 0.3))  # The right hill, a little lower.
			draw_circle(Vector2.ZERO, size.x * 0.55, Color("#3A9E48", 0.5), true, -1.0, true)  # Right hill.
			draw_set_transform(Vector2.ZERO)  # Back to normal drawing.
		"low_sun":  # A big setting sun at the bottom, with a glow.
			var low_sun := Vector2(size.x * 0.5, size.y * 1.0)  # Its middle, at the bottom edge.
			draw_circle(low_sun, size.x * 0.55, Color("#FFD166", 0.22), true, -1.0, true)  # Glow.
			draw_circle(low_sun, size.x * 0.38, Color("#FFD166", 0.45), true, -1.0, true)  # The sun.
		"moon":  # A pale crescent moon at the top right, with a soft glow.
			var moon := Vector2(size.x * 0.82, size.y * 0.1)  # Where it sits.
			draw_circle(moon, 130.0, Color("#FFF3C4", 0.08), true, -1.0, true)  # Glow.
			draw_circle(moon, 80.0, Color("#FFF3C4", 0.95), true, -1.0, true)  # The full moon ...
			draw_circle(moon + Vector2(34.0, -22.0), 72.0, _gradient.sample(0.1), true, -1.0, true)  # ... with a sky-coloured circle over it, leaving a crescent.


# Returns the corners of a star with `points` points, turned by `angle`. `inner` is how deep the dips are (0 to 1).
func _star_points(centre: Vector2, radius: float, points: int, inner: float, angle: float) -> PackedVector2Array:
	var corners := PackedVector2Array()  # The corner list.
	for i in range(points * 2):  # A point, then a dip, all the way round.
		var turn := angle + TAU * i / (points * 2) - PI / 2.0  # This corner's direction, starting at the top.
		var reach := radius if i % 2 == 0 else radius * inner  # A point reaches out; a dip stays close.
		corners.append(centre + Vector2(cos(turn), sin(turn)) * reach)  # Add the corner.
	return corners  # Hand back the corners.


# Returns the corners of a leaf of size `r`, pointing up, around (0, 0).
func _leaf_points(r: float) -> PackedVector2Array:
	return PackedVector2Array([  # A pointed oval, top to bottom and back up.
		Vector2(0.0, -r), Vector2(0.42 * r, -0.45 * r), Vector2(0.5 * r, 0.1 * r), Vector2(0.28 * r, 0.65 * r),  # Right side.
		Vector2(0.0, r), Vector2(-0.28 * r, 0.65 * r), Vector2(-0.5 * r, 0.1 * r), Vector2(-0.42 * r, -0.45 * r),  # Left side.
	])  # End of the list.
