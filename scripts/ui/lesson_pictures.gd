# The pictures for the How to Play lessons (D-032), made from the real game parts: the item card,
# the answer bubbles, the timer bar and the Stars, so the learner sees exactly what the game shows.
# Each picture is a plain node for the lesson's stage. The "Try it!" page is built by the screen.
class_name LessonPictures  # Lets the How to Play screen write LessonPictures.make(0).
extends RefCounted  # Only its static functions are used.

const BUBBLE_SCALE := 0.7  # Answer bubbles at 70 % of their size in the play area, so three fit.
const BUBBLE_COLOURS := ["yellow", "green", "pink"]  # Resting bubble colours, as on the Play screen.


# Returns the picture for one lesson page, 0 to 5.
static func make(index: int) -> Control:
	match index:  # Each page has its own picture.
		0:  # Read the division.
			return _read_picture()  # The item card.
		1:  # Tap the right bubble before the timer runs out.
			return _tap_picture()  # Card, timer bar and bubbles.
		2:  # Right and wrong.
			return _right_wrong_picture()  # A green and a red bubble.
		3:  # Stars.
			return _stars_picture()  # 8, 9 and 10 right.
		4:  # The times-table trick.
			return _trick_picture()  # Division to times table.
		5:  # Easy, Medium and Hard.
			return _difficulty_picture()  # Bubbles and seconds.
	return Control.new()  # No picture for other pages.


# Makes a white item card with a division and "= ?" under it, like the Play screen's card.
static func item_card(question: String, font_size: int, card_size: Vector2) -> PanelContainer:
	var card := PanelContainer.new()  # The card.
	card.add_theme_stylebox_override("panel", UiKit.box(Palette.WHITE, 60))  # Rounded, outlined.
	card.custom_minimum_size = card_size  # Its size.
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	var lines := VBoxContainer.new()  # Question above "= ?".
	lines.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	lines.add_theme_constant_override("separation", -8)  # Close together.
	var question_text := MathText.new(font_size, Palette.INK)  # The division, as the Play screen draws it.
	question_text.set_text(question)  # For example "56 ÷ 8".
	lines.add_child(question_text)  # Add it.
	lines.add_child(UiKit.label("= ?", int(font_size * 0.42), Palette.BLUE))  # The question mark under it.
	card.add_child(lines)  # Put them on the card.
	return card  # Hand back the card.


# Makes a row of answer bubbles at 70 % size inside a holder of the given width. The bubble at
# `highlight` (or none, -1) pulses gently. Returns the holder; the bubbles are its children.
static func bubble_row(numbers: Array, width: float, highlight: int = -1) -> Control:
	var side := AnswerBubble.SIZE * BUBBLE_SCALE  # Each bubble's size on screen.
	var holder := Control.new()  # Places the bubbles by hand, as the Play screen does.
	holder.custom_minimum_size = Vector2(width, side + 20.0)  # Room for the bubbles and their bob.
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps reach the bubbles.
	var gap := (width - side * numbers.size()) / float(numbers.size() + 1)  # Even space around the bubbles.
	for i in range(numbers.size()):  # Each number ...
		var bubble := AnswerBubble.new()  # ... a real answer bubble,
		bubble.setup(numbers[i], BUBBLE_COLOURS[i % BUBBLE_COLOURS.size()])  # ... with its number and colour,
		bubble.scale = Vector2(BUBBLE_SCALE, BUBBLE_SCALE)  # ... a little smaller,
		var left := gap + i * (side + gap)  # ... spread across,
		bubble.place(Vector2(left - (AnswerBubble.SIZE - side) / 2.0, 10.0 - (AnswerBubble.SIZE - side) / 2.0))  # ... placed so the shrunken bubble sits in its spot,
		holder.add_child(bubble)  # ... and shown.
		if i == highlight:  # The bubble to tap in the picture ...
			bubble.lock()  # ... is only a picture,
			var pulse := bubble.create_tween().set_loops()  # ... and pulses forever, around its own smaller size,
			pulse.tween_property(bubble, "scale", Vector2.ONE * BUBBLE_SCALE * 1.12, 0.45).set_trans(Tween.TRANS_SINE)  # ... growing a little,
			pulse.tween_property(bubble, "scale", Vector2.ONE * BUBBLE_SCALE, 0.45).set_trans(Tween.TRANS_SINE)  # ... and back, to say "this one".
	return holder  # Hand back the row.


# Page 1: the item card with "Question 1 of 10" above it.
static func _read_picture() -> Control:
	var box := _column(24)  # Stacked.
	box.add_child(UiKit.label("Question 1 of 10", 48, Palette.WHITE, 12))  # Each Level has 10 questions.
	box.add_child(item_card("56 ÷ 8", 160, Vector2(820, 360)))  # The card.
	return box  # Hand back the picture.


# Page 2: a small card, the timer bar part way down, and three bubbles with the right one pulsing.
static func _tap_picture() -> Control:
	var box := _column(20)  # Stacked.
	box.add_child(item_card("56 ÷ 8", 110, Vector2(620, 230)))  # The card.
	var timer := TimerBar.new()  # The real timer bar ...
	timer.ratio = 0.6  # ... part way down,
	timer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # ... centred,
	box.add_child(timer)  # ... under the card.
	var row := bubble_row([6, 7, 9], 900.0, 1)  # The bubbles, with 7 pulsing.
	for bubble in row.get_children():  # Every bubble is only a picture here ...
		(bubble as AnswerBubble).lock()  # ... so it cannot be tapped.
	box.add_child(row)  # Under the timer.
	box.add_child(UiKit.label("Tap the 7!", 48, Palette.YELLOW, 12))  # What to do.
	return box  # Hand back the picture.


# Page 3: a right answer that turns green and sparkles, beside a wrong one that turns red and shakes.
static func _right_wrong_picture() -> Control:
	var row := HBoxContainer.new()  # The two examples side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	row.add_theme_constant_override("separation", 60)  # Space between them.
	row.add_child(_example(7, true, "Right! It sparkles."))  # The right answer.
	row.add_child(_example(9, false, "Wrong? The right one shows in green."))  # A wrong answer.
	return row  # Hand back the picture.


# Makes one right-or-wrong example: a bubble that plays its real feedback, and a caption.
static func _example(number: int, right: bool, caption: String) -> VBoxContainer:
	var box := _column(10)  # Bubble above caption.
	var holder := bubble_row([number], 360.0)  # One bubble.
	var bubble := holder.get_child(0) as AnswerBubble  # The bubble.
	bubble.lock()  # Only a picture.
	box.add_child(holder)  # Show it.
	if right:  # The right answer ...
		bubble.call_deferred("mark_correct")  # ... turns green with a tick and sparkles, once it is on screen.
	else:  # A wrong answer ...
		bubble.call_deferred("mark_wrong")  # ... turns red with a cross and shakes.
	var words := UiKit.label(caption, 42, Palette.WHITE, 12)  # The caption.
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap long captions.
	words.custom_minimum_size.x = 400.0  # Its width.
	box.add_child(words)  # Under the bubble.
	return box  # Hand back the example.


# Page 4: three rows of Stars: 8 right = 1 Star, 9 = 2, 10 = 3, and "1 Star opens the next Level!".
static func _stars_picture() -> Control:
	var card := _white_card()  # A white card.
	var lines := card.get_child(0) as VBoxContainer  # Its rows.
	for row: Array in [[8, 1], [9, 2], [10, 3]]:  # Right answers and Stars ...
		var line := HBoxContainer.new()  # ... one row each,
		line.alignment = BoxContainer.ALIGNMENT_CENTER  # ... centred,
		line.add_theme_constant_override("separation", 16)  # ... with a little space.
		var words := UiKit.label("%d right" % row[0], 60, Palette.INK)  # "8 right".
		words.custom_minimum_size.x = 260.0  # Same width on every row, so the Stars line up.
		line.add_child(words)  # Add it.
		for s in range(3):  # Three Star places ...
			var star := TextureRect.new()  # ... each a Star picture,
			star.texture = SpriteSheet.star()[5 if s < row[1] else 0]  # ... gold if earned, empty if not,
			star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # ... any size,
			star.custom_minimum_size = Vector2(100, 100)  # ... this big,
			line.add_child(star)  # ... in the row.
		lines.add_child(line)  # Add the row.
	var opens := HBoxContainer.new()  # The last line: a lock opening.
	opens.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred.
	opens.add_theme_constant_override("separation", 16)  # A little space.
	opens.add_child(UiKit.icon(UiKit.Icon.LOCK, 80))  # The lock.
	opens.add_child(UiKit.label("1 Star opens the next Level!", 46, Palette.BLUE))  # What a Star does.
	lines.add_child(opens)  # Add it.
	return card  # Hand back the picture.


# Page 5: the times-table trick, from the division to the answer, one step per line.
static func _trick_picture() -> Control:
	var card := _white_card()  # A white card.
	var lines := card.get_child(0) as VBoxContainer  # Its lines.
	var question := MathText.new(120, Palette.INK)  # The division, as the Play screen draws it.
	question.set_text("56 ÷ 8 = ?")  # The question.
	lines.add_child(question)  # First line.
	lines.add_child(UiKit.label("Think:", 48, Palette.BLUE))  # The trick.
	lines.add_child(UiKit.label("8 × ? = 56", 88, Palette.BLUE))  # The times table.
	lines.add_child(UiKit.label("8 × 7 = 56", 88, Palette.GREEN.darkened(0.2)))  # The fact.
	lines.add_child(UiKit.label("So 56 ÷ 8 = 7", 72, Palette.INK))  # The answer.
	return card  # Hand back the picture.


# Page 6: Easy, Medium and Hard, each with its bubbles and its seconds (D-008).
static func _difficulty_picture() -> Control:
	var card := _white_card()  # A white card.
	var lines := card.get_child(0) as VBoxContainer  # Its rows.
	var chips := [Palette.GREEN, Palette.YELLOW, Palette.PINK]  # Easy, Medium and Hard colours.
	for kind: int in Difficulty.Kind.values():  # Each Difficulty ...
		var line := HBoxContainer.new()  # ... one row,
		line.add_theme_constant_override("separation", 18)  # ... with a little space.
		var chip := PanelContainer.new()  # Its name on a coloured chip.
		var style := UiKit.box(chips[kind], 30, 6)  # The chip's colour.
		style.set_content_margin_all(8)  # Room inside.
		chip.add_theme_stylebox_override("panel", style)  # Use this look.
		chip.custom_minimum_size = Vector2(250, 0)  # Same width for every row.
		chip.add_child(UiKit.label(Difficulty.name_of(kind), 50, Palette.INK))  # "Easy".
		line.add_child(chip)  # On the left.
		var dots := HBoxContainer.new()  # Its bubbles.
		dots.add_theme_constant_override("separation", 4)  # Close together.
		dots.custom_minimum_size.x = 330.0  # Same width for every row, so the times line up.
		for b in range(Difficulty.bubble_count(kind)):  # One small bubble per answer bubble ...
			var dot := TextureRect.new()  # ... a bubble picture,
			dot.texture = SpriteSheet.bubble(BUBBLE_COLOURS[b % BUBBLE_COLOURS.size()])[0]  # ... resting,
			dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # ... any size,
			dot.custom_minimum_size = Vector2(76, 76)  # ... small,
			dots.add_child(dot)  # ... in the row.
		line.add_child(dots)  # In the middle.
		line.add_child(UiKit.icon(UiKit.Icon.CLOCK, 70))  # The clock.
		line.add_child(UiKit.label("%d s" % int(Difficulty.time_limit(kind)), 56, Palette.INK))  # "15 s".
		lines.add_child(line)  # Add the row.
	return card  # Hand back the picture.


# Makes a column that stacks its parts in the middle.
static func _column(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()  # Parts top to bottom.
	box.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	box.add_theme_constant_override("separation", separation)  # Space between parts.
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	return box  # Hand it back.


# Makes a white card with a column inside it (its first child), for the rows of a picture.
static func _white_card() -> PanelContainer:
	var card := PanelContainer.new()  # The card.
	var style := UiKit.box(Palette.WHITE, 56)  # White, round and outlined.
	style.set_content_margin_all(32)  # Room inside.
	card.add_theme_stylebox_override("panel", style)  # Use this look.
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	card.add_child(_column(18))  # The rows go here.
	return card  # Hand back the card.
