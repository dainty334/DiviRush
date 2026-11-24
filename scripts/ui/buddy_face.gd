# A learner's Buddy as small round faces (D-030): one face for Ana or Migo, and for "Both" Ana's and
# Migo's faces side by side, overlapping a little. Each face is cut from the mascot's own head, eyes,
# eyebrows and smile, on a pale round background. Used on the Main menu's Profile pill, the Profile
# screen, the Buddy picker and the Welcome screen.
class_name BuddyFace  # Lets the screens and tests write BuddyFace.new("Ana", 84).
extends Control  # A plain UI node that holds the faces.

const OVERLAP := 0.38  # How much the second face covers the first, as a part of one face's width.
const BACKGROUND := {"Ana": Color("#FFD6E0"), "Migo": Color("#C9ECFB")}  # Pale pink behind Ana, pale blue behind Migo.

var buddy: String  # The Buddy shown: "Ana", "Migo" or "Both".
var side: float  # The width and height of one face, in pixels.


# Makes the faces for a Buddy choice, each `face_side` pixels wide.
func _init(chosen_buddy: String, face_side: float) -> void:
	buddy = chosen_buddy  # Remember the choice.
	side = face_side  # Remember the size.
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the button or card around it.
	var names := Profile.mascots_for(buddy)  # One name, or both.
	custom_minimum_size = Vector2(side + (names.size() - 1) * side * (1.0 - OVERLAP), side)  # Room for every face.
	for i in range(names.size()):  # Each face, left to right ...
		_add_face(names[i], Vector2(i * side * (1.0 - OVERLAP), 0.0))  # ... placed a little to the right of the last.


# Adds one round face at a place: a pale circle with a dark outline, and the face pictures on top.
func _add_face(mascot: String, at: Vector2) -> void:
	var circle := Panel.new()  # The round background.
	var ring := maxi(3, int(side / 22.0))  # The outline, thicker for bigger faces.
	var style := UiKit.box(BACKGROUND[mascot], int(side / 2.0), ring)  # Pale colour, fully round.
	style.border_width_bottom = ring  # The same outline all round, not the chunky button bottom.
	circle.add_theme_stylebox_override("panel", style)  # Use this look.
	circle.position = at  # Its place.
	circle.size = Vector2(side, side)  # Its size.
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	add_child(circle)  # Show it.
	var inset := side * 0.06  # Keep the hair inside the outline.
	for picture in SpriteSheet.mascot_face(mascot):  # Head, eyes, eyebrows and smile, back to front ...
		var layer := TextureRect.new()  # ... one picture each,
		layer.texture = picture  # ... this part,
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # ... any size,
		layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # ... keeping its shape,
		layer.position = Vector2(inset, inset)  # ... inside the circle,
		layer.size = Vector2(side, side) - Vector2(inset, inset) * 2.0  # ... filling it,
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ... letting taps through,
		circle.add_child(layer)  # ... stacked on the circle.
