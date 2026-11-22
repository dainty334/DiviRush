# How to Play: a short rules screen (Game Spec, Main menu; D-008 scoring and Stars).
extends ScreenBase  # Shared background, margins and column.

const RULES := [  # [icon, rule text], shown top to bottom.
	[-1, "Look at the division, like 56 ÷ 8 = ?"],  # One rule as [icon, text].
	[UiKit.Icon.CLOCK, "Tap the bubble with the right answer before the timer runs out."],  # One rule as [icon, text].
	[UiKit.Icon.STAR, "A right answer gives 10 points, plus 1 point for each second left."],  # One rule as [icon, text].
	[UiKit.Icon.SOUND, "Get 4 or more right in a row for +5 streak points!"],  # One rule as [icon, text].
	[UiKit.Icon.STAR, "8 of 10 right = 1 Star. 9 = 2 Stars. 10 = 3 Stars."],  # One rule as [icon, text].
	[UiKit.Icon.LOCK, "Earn at least 1 Star to open the next Level."],  # One rule as [icon, text].
]  # End of the list.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	add_header("How to Play")  # Back button and title.
	var card := PanelContainer.new()  # White card for the rules.
	card.add_theme_stylebox_override("panel", UiKit.box(Palette.WHITE, 60))  # Rounded with a thick outline.
	var list := VBoxContainer.new()  # Rules stacked.
	list.add_theme_constant_override("separation", 26)  # Space between rules.
	card.add_child(list)  # Put the list on the card.
	for rule in RULES:  # Each rule ...
		list.add_child(_rule_row(rule[0], rule[1]))  # ... becomes a row.
	column.add_child(card)  # Show the card.
	UiKit.pop_in(card, 0.1)  # Bounce in.
	add_spacer(1.0)  # Push the button down.
	var done := UiKit.button("Got it!", Palette.GREEN)  # Leave the rules.
	done.pressed.connect(go_back)  # Back to the Main menu.
	column.add_child(done)  # Show it.
	UiKit.pop_in(done, 0.3)  # Bounce in.


# Makes one rule row: an icon (or a ÷ sign) and the rule text.
func _rule_row(which: int, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()  # Icon and text side by side.
	row.add_theme_constant_override("separation", 24)  # Space between them.
	if which >= 0:  # A real icon ...
		row.add_child(UiKit.icon(which, 80))  # ... from the icons sheet.
	else:  # No icon for the first rule ...
		var sign := UiKit.label("÷", 64, Palette.BLUE)  # ... so show a big ÷ sign,
		sign.custom_minimum_size = Vector2(80, 80)  # ... the same size as an icon.
		row.add_child(sign)  # Add it.
	var words := UiKit.label(text, 44, Palette.INK)  # The rule.
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # Lined up on the left.
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap long rules.
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the free width.
	row.add_child(words)  # Add it.
	return row  # Hand back the row.


# Back returns to the Main menu.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
