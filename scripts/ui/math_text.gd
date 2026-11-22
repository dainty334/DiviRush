# One line of a division sentence, such as "56 ÷ ☐" or "☐ ÷ 8", in the bold Fredoka font.
# Each ☐ is drawn as a thick rounded box instead of a font sign, because Fredoka has no ☐ and
# the stand-in font draws it thin (D-013). Used on the Play screen's item card and the Level cards.
class_name MathText  # Lets screens write MathText.new(170, Palette.INK).
extends HBoxContainer  # Puts the words and boxes side by side.

const BOX_SIGN := "☐"  # The sign in the item text that marks the hidden number.

var _size := 40  # Font size of the words, in pixels.
var _colour := Palette.INK  # Colour of the words and the box outline.


# Runs when the line is made: remembers the font size and colour, and centres the line.
func _init(font_size: int = 40, colour: Color = Palette.INK) -> void:
	_size = font_size  # How big the words are.
	_colour = colour  # What colour they are.
	alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through to what is behind.
	add_theme_constant_override("separation", 0)  # Spaces come from the text itself.


# Shows a new line of text, drawing a box for each ☐. Called for every new item or answer.
func set_text(text: String) -> void:
	for old in get_children():  # Each part of the old line ...
		remove_child(old)  # ... is taken out at once, so it is not counted again,
		old.queue_free()  # ... and freed at the end of the frame.
	var parts := text.split(BOX_SIGN)  # The words between the boxes.
	for i in range(parts.size()):  # Each piece of words ...
		if not parts[i].is_empty():  # ... that has letters ...
			add_child(UiKit.label(parts[i], _size, _colour))  # ... is a label.
		if i < parts.size() - 1:  # A ☐ came after this piece ...
			add_child(_make_box())  # ... so draw the box there.


# Makes the drawn box: an empty rounded square with a thick outline, sized to the font.
func _make_box() -> Panel:
	var box := Panel.new()  # A plain node that shows one style box.
	var style := StyleBoxFlat.new()  # The look of the box.
	style.bg_color = Color(0, 0, 0, 0)  # Empty inside, so it reads as "a number goes here".
	style.border_color = _colour  # Outline in the text colour.
	style.set_border_width_all(maxi(3, roundi(_size * 0.07)))  # Thick like the font's strokes: about 12 px on the card.
	style.set_corner_radius_all(roundi(_size * 0.1))  # Softly rounded, like the rest of the art.
	style.anti_aliasing = true  # Smooth corners.
	box.add_theme_stylebox_override("panel", style)  # Use this look.
	box.custom_minimum_size = Vector2(_size * 0.62, _size * 0.7)  # About as wide as a digit and as tall as a capital.
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Sit in the middle of the line, level with the digits.
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	return box  # Hand it back.
