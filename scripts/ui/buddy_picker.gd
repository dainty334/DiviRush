# "Who's your buddy?": three tiles, Ana, Migo and Both, each with its face and name (D-030).
# The picked tile turns green. Used on the Welcome screen and the Profile screen.
class_name BuddyPicker  # Lets the screens and tests write BuddyPicker.new("Both").
extends HBoxContainer  # The three tiles side by side.

signal chosen(buddy: String)  # Sent when the learner taps a tile.

const TILE_SIZE := Vector2(300, 290)  # Each tile, so all three fit across the screen.
const FACE_SIDE := 150.0  # The face on each tile.

var selected := Profile.BOTH  # The Buddy picked now.
var _tiles: Dictionary = {}  # Each tile button, by Buddy.


# Makes the three tiles, with `start` picked.
func _init(start: String) -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	add_theme_constant_override("separation", 30)  # Space between the tiles.
	for buddy: String in Profile.BUDDIES:  # Ana, Migo and Both ...
		var tile := UiKit.card_button(Palette.WHITE, TILE_SIZE, 48)  # ... a tile button each,
		var lines := VBoxContainer.new()  # ... with the face above the name,
		lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # ... filling the tile,
		lines.alignment = BoxContainer.ALIGNMENT_CENTER  # ... centred up and down,
		lines.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ... letting taps reach the tile.
		var face := BuddyFace.new(buddy, FACE_SIDE)  # The face, or both faces.
		face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred across.
		lines.add_child(face)  # Add it.
		lines.add_child(UiKit.label(buddy, 48, Palette.INK))  # The name under it.
		tile.add_child(lines)  # Put them on the tile.
		tile.pressed.connect(select.bind(buddy, true))  # Tapping picks this Buddy and tells the screen.
		add_child(tile)  # Show the tile.
		_tiles[buddy] = tile  # Remember it.
	select(start)  # Show the starting choice.


# Picks a Buddy: its tile turns green and the others white. `tell` sends `chosen`, as a tap does.
func select(buddy: String, tell: bool = false) -> void:
	selected = buddy if _tiles.has(buddy) else Profile.BOTH  # A known Buddy, or Both.
	for each: String in _tiles:  # Each tile ...
		UiKit.style_button(_tiles[each], Palette.GREEN if each == selected else Palette.WHITE, 48)  # ... green when picked.
	if tell:  # A tap ...
		chosen.emit(selected)  # ... tells the screen.
