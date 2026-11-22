# Tests for the polish of the card text and the bubbles: the drawn ☐ box in MathText,
# and numbers up to 100 fitting inside an answer bubble.
extends GutTest  # GUT gives this script its assert_* checks.


# Counts the drawn boxes (Panels) in a MathText.
func _boxes(text: MathText) -> int:
	var count := 0  # None yet.
	for child in text.get_children():  # Each part of the line ...
		if child is Panel:  # ... that is a drawn box ...
			count += 1  # ... is counted.
	return count  # Hand back the count.


# Joins the words of a MathText's labels, with "[]" for each box, so a test can read the line.
func _read(text: MathText) -> String:
	var line := ""  # Nothing yet.
	for child in text.get_children():  # Each part, left to right.
		if child is Label:  # A word part ...
			line += (child as Label).text  # ... adds its text.
		elif child is Panel:  # A box ...
			line += "[]"  # ... shows as [].
	return line  # Hand back the line.


# Text with no ☐ is one plain label and no box.
func test_plain_text_has_no_box() -> void:
	var text := MathText.new(170, Palette.INK)  # A big dark line.
	add_child_autofree(text)  # In the tree, freed after the test.
	text.set_text("56 ÷ 8")  # A missing-quotient question.
	assert_eq(_boxes(text), 0)  # No box.
	assert_eq(_read(text), "56 ÷ 8")  # The same words.


# Each ☐ becomes a drawn box in its place: "56 ÷ ☐" and "☐ ÷ 8".
func test_box_replaces_the_square_sign() -> void:
	var text := MathText.new(170, Palette.INK)  # A big dark line.
	add_child_autofree(text)  # In the tree, freed after the test.
	text.set_text("56 ÷ ☐")  # Missing divisor.
	assert_eq(_boxes(text), 1)  # One box.
	assert_eq(_read(text).strip_edges(), "56 ÷ []")  # The box comes last.
	text.set_text("☐ ÷ 8")  # Missing dividend: the old parts are replaced.
	assert_eq(_boxes(text), 1)  # Still one box.
	assert_eq(_read(text).strip_edges(), "[] ÷ 8")  # The box comes first.


# The box grows with the font, so the big card and the small Level card both look right.
func test_box_size_follows_the_font() -> void:
	var big := MathText.new(170, Palette.INK)  # The item card size.
	var small := MathText.new(40, Palette.BLUE)  # The Level card size.
	add_child_autofree(big)  # In the tree, freed after the test.
	add_child_autofree(small)  # In the tree, freed after the test.
	big.set_text("☐")  # Only a box.
	small.set_text("☐")  # Only a box.
	var big_box: Panel = big.get_child(0)  # The big box.
	var small_box: Panel = small.get_child(0)  # The small box.
	assert_gt(big_box.custom_minimum_size.y, small_box.custom_minimum_size.y * 3.0)  # About 4 times as tall.


# Numbers 1 to 100 fit inside a bubble with room to spare, so "100" is not cut off or crowded.
func test_numbers_up_to_100_fit_in_a_bubble() -> void:
	for number: int in [7, 56, 100]:  # One, two and three digits.
		var size := AnswerBubble.font_size_for(number)  # The font size the bubble uses.
		var width := UiKit.font().get_string_size(str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x  # How wide it draws.
		assert_lt(width, AnswerBubble.SIZE * 0.62, "%d is %.0f px wide" % [number, width])  # Inside the round part of the bubble.
