# Shared frame for every DiviRush screen: the bubble background, a safe margin around the edges,
# and a centred column where each screen puts its content. Also handles the Back button.
class_name ScreenBase  # Each screen script starts with `extends ScreenBase`.
extends Control  # A full-screen UI node.

const COLUMN_WIDTH := 1000.0  # Content width; the design screen is 1080 wide (D-009).
const EDGE := 40  # Space kept clear at every screen edge.

var column: VBoxContainer  # The centred column; screens add their content here.
var background: SkyBackground  # The sky behind the screen.
var _hint: Label  # Short message line at the bottom, for example why a card is locked.
var _exit_card: Control  # The "Leave DiviRush?" card, made the first time it is needed (D-021).


# Runs when the screen opens: builds the frame, then calls the screen's own _build().
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill the whole window.
	background = SkyBackground.new(sky_look())  # This screen's sky and floating shapes (D-020) ...
	add_child(background)  # ... behind everything.
	var margin := MarginContainer.new()  # Keeps content away from the edges.
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill the window.
	_apply_safe_area(margin)  # Stay clear of notches and rounded corners on phones.
	add_child(margin)  # Show it.
	column = VBoxContainer.new()  # The content column.
	column.custom_minimum_size.x = COLUMN_WIDTH  # Fixed width, so wide screens keep the same layout.
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred across.
	column.add_theme_constant_override("separation", 32)  # Space between blocks.
	margin.add_child(column)  # Put the column inside the margin.
	_build()  # Let the screen add its own content.


# Each screen fills its column here. Called once from _ready().
func _build() -> void:
	pass  # The base frame adds nothing.


# Each screen picks its background look (D-020). The Main menu area keeps the default blue bubble sky.
func sky_look() -> int:
	return SkyBackground.Look.MENU  # Blue sky with bubbles.


# Each screen decides where Back goes (the arrow button, Android Back, or Escape on a PC).
func go_back() -> void:
	pass  # The base frame does nothing.


# Sets the edge margins. On phones the margins also clear the notch and rounded corners.
func _apply_safe_area(margin: MarginContainer) -> void:
	var top := EDGE  # Top margin.
	var bottom := EDGE  # Bottom margin.
	if OS.has_feature("mobile"):  # Only phones and tablets have notches to avoid.
		var safe := DisplayServer.get_display_safe_area()  # Usable part of the screen, in screen pixels.
		var screen := DisplayServer.screen_get_size()  # Whole screen, in screen pixels.
		var scale_y := get_viewport_rect().size.y / float(maxi(screen.y, 1))  # Screen pixels -> game pixels.
		top += int(safe.position.y * scale_y)  # Add the notch height.
		bottom += int((screen.y - safe.end.y) * scale_y)  # Add the bottom bar height.
	margin.add_theme_constant_override("margin_top", top)  # Apply the top margin.
	margin.add_theme_constant_override("margin_bottom", bottom)  # Apply the bottom margin.
	margin.add_theme_constant_override("margin_left", EDGE)  # Apply the left margin.
	margin.add_theme_constant_override("margin_right", EDGE)  # Apply the right margin.


# Adds empty space that stretches, so taller phones spread the content out. Returns the spacer.
func add_spacer(weight: float = 1.0) -> Control:
	var spacer := Control.new()  # An empty node.
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL  # It takes leftover height.
	spacer.size_flags_stretch_ratio = weight  # Bigger weight, bigger share.
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never block taps.
	column.add_child(spacer)  # Put it in the column.
	return spacer  # Hand it back.


# Adds the top row: a round back button and a title. Used by every menu after the Main menu.
func add_header(title: String, subtitle: String = "") -> void:
	var row := HBoxContainer.new()  # Back button and title side by side.
	row.add_theme_constant_override("separation", 24)  # Space between them.
	row.add_child(make_back_button())  # Back arrow on the left.
	var titles := VBoxContainer.new()  # Title and subtitle stacked.
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the rest of the row.
	titles.add_theme_constant_override("separation", 0)  # No gap between title lines.
	titles.add_child(UiKit.label(title, 64, Palette.WHITE, 16))  # Big outlined title.
	if subtitle != "":  # A subtitle was given ...
		titles.add_child(UiKit.label(subtitle, 40, Palette.WHITE, 10))  # ... show it smaller.
	row.add_child(titles)  # Add the titles.
	var balance := Control.new()  # An empty box the size of the back button ...
	balance.custom_minimum_size = Vector2(120, 120)  # ... so the title stays centred on screen.
	row.add_child(balance)  # Add it on the right.
	column.add_child(row)  # Put the row at the top of the column.


# Makes the white rounded back button with an arrow, as in the style sample.
func make_back_button() -> Button:
	var button := UiKit.card_button(Palette.WHITE, Vector2(120, 120), 36)  # Small white button.
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Do not stretch tall.
	var arrow := UiKit.icon(UiKit.Icon.BACK, 72)  # Arrow icon.
	arrow.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill the button so the arrow is centred.
	button.add_child(arrow)  # Put the arrow on the button.
	button.pressed.connect(go_back)  # Tapping it goes back.
	return button  # Hand it back.


# Makes a wide choice card with a title, a subtitle and a badge on the right (Stars, lock or "Soon").
# Used by the Episode select and Difficulty select screens.
func make_choice_card(title: String, subtitle: String, colour: Color, badge: Control) -> Button:
	var card := UiKit.card_button(colour, Vector2(COLUMN_WIDTH - 40, 200))  # The card itself.
	var row := HBoxContainer.new()  # Words on the left, badge on the right.
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the card ...
	row.offset_left = 44  # ... with room on the left,
	row.offset_right = -44  # ... and on the right.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the card.
	var words := VBoxContainer.new()  # Title above subtitle.
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the free width.
	words.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the card.
	var top := UiKit.label(title, 54, Palette.INK)  # Dark title.
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # Lined up on the left.
	words.add_child(top)  # Add the title.
	var under := UiKit.label(subtitle, 40, Palette.BLUE)  # Blue subtitle.
	under.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # Lined up on the left.
	words.add_child(under)  # Add the subtitle.
	row.add_child(words)  # Words go first.
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Badge centred up and down.
	row.add_child(badge)  # Badge on the right.
	card.add_child(row)  # Put everything on the card.
	return card  # Hand back the card.


# Makes a small "Star 7/15" badge for a card.
func make_stars_badge(count: int, total: int) -> HBoxContainer:
	var badge := HBoxContainer.new()  # Star icon and numbers side by side.
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the card.
	badge.add_child(UiKit.icon(UiKit.Icon.STAR, 64))  # Gold Star icon.
	badge.add_child(UiKit.label("%d/%d" % [count, total], 44, Palette.INK))  # How many Stars of how many.
	return badge  # Hand back the badge.


# Adds the hint line at the bottom of the column. Call show_hint() to make it speak.
func add_hint_line() -> void:
	_hint = UiKit.label("", 42, Palette.WHITE, 12)  # Empty outlined text.
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap long messages.
	_hint.custom_minimum_size = Vector2(COLUMN_WIDTH, 120)  # Keep its space so nothing jumps.
	_hint.modulate.a = 0.0  # Hidden until needed.
	column.add_child(_hint)  # Put it in the column.


# Shows a short message for a few seconds, for example "Pass Level 1 to open this Level."
func show_hint(text: String) -> void:
	if _hint == null:  # No hint line on this screen ...
		return  # ... so nothing to show.
	_hint.text = text  # Set the message.
	var tween := _hint.create_tween()  # Fade in, wait, fade out.
	tween.tween_property(_hint, "modulate:a", 1.0, 0.15)  # Fade in.
	tween.tween_interval(2.2)  # Stay for a moment.
	tween.tween_property(_hint, "modulate:a", 0.0, 0.4)  # Fade out.


# Makes a hidden card over the whole screen: a dark veil, and a white card with a title and the
# given buttons under it. Used for the "Paused" card (D-015) and the "Leave DiviRush?" card (D-021),
# so both look the same. The caller adds the card to the screen and shows it when needed.
func make_card(title: String, buttons: Array, title_size: int = 110) -> Control:
	var card := Control.new()  # Holder that fills the screen.
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Cover everything.
	card.mouse_filter = Control.MOUSE_FILTER_STOP  # Taps stop here, so nothing behind can be tapped.
	card.visible = false  # Hidden until needed.
	var veil := ColorRect.new()  # Dark see-through layer.
	veil.color = Color(Palette.INK, 0.7)  # Dark ink, 70% strong.
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the screen.
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE  # The holder already stops taps.
	card.add_child(veil)  # Add it.
	var centre := CenterContainer.new()  # Puts the card in the middle.
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the screen.
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the buttons.
	card.add_child(centre)  # Add it.
	var panel := PanelContainer.new()  # The white card.
	var style := UiKit.box(Palette.WHITE, 70)  # Rounded and outlined, like the item card.
	style.set_content_margin_all(60)  # Room inside the card.
	panel.add_theme_stylebox_override("panel", style)  # Use this look.
	centre.add_child(panel)  # Add it.
	var lines := VBoxContainer.new()  # Title above the buttons.
	lines.add_theme_constant_override("separation", 40)  # Space between them.
	panel.add_child(lines)  # Add it.
	lines.add_child(UiKit.label(title, title_size, Palette.INK))  # Big dark title.
	for button: Button in buttons:  # Each button, top to bottom ...
		lines.add_child(button)  # ... goes under the title.
	return card  # Hand back the hidden card.


# Shows the "Leave DiviRush?" card (D-021). Stay is the big green button and closes the card;
# Exit saves and closes the game. The card is made the first time it is needed.
func show_exit_card() -> void:
	if _exit_card == null:  # Not made yet ...
		var stay := UiKit.button("Stay", Palette.GREEN, Vector2(600, 150))  # ... the big safe choice,
		stay.pressed.connect(hide_exit_card)  # ... which closes the card,
		var leave := UiKit.button("Exit", Palette.PINK, Vector2(600, 140), 60)  # ... the smaller pink choice,
		leave.pressed.connect(Game.quit_game)  # ... which saves and closes the game,
		_exit_card = make_card("Leave DiviRush?", [stay, leave], 84)  # ... on one card,
		add_child(_exit_card)  # ... added last, so it draws on top of the screen.
	_exit_card.visible = true  # Show it.


# Hides the "Leave DiviRush?" card. Called by Stay, and by Back while the card is open.
func hide_exit_card() -> void:
	if _exit_card != null:  # The card was made ...
		_exit_card.visible = false  # ... so hide it.


# Returns true while the "Leave DiviRush?" card is showing.
func is_exit_card_open() -> bool:
	return _exit_card != null and _exit_card.visible  # Made and showing.


# Runs for Android Back and for Escape on a PC. While the Exit card is open, Back is the same as
# Stay (D-021); otherwise the screen goes back.
func back_pressed() -> void:
	if is_exit_card_open():  # The card is showing ...
		hide_exit_card()  # ... so close it and stay.
	else:  # No card ...
		go_back()  # ... so go to the previous screen.


# Catches the Android Back button and sends it to back_pressed().
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android Back was pressed ...
		back_pressed()  # ... so close the card or go back.


# Lets Escape act as Back on a PC, so the game can be tested in the editor.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):  # Escape was pressed ...
		get_viewport().set_input_as_handled()  # ... handle it here,
		back_pressed()  # ... and close the card or go back.
