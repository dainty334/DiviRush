# Main menu: Play, How to Play, Settings and Exit (D-008), with the lively, lined-up look of D-017:
# a floating logo with a twinkling sparkle, a waving title, the tagline, the total-Stars pill,
# and four straight buttons with drawn icons, where only Play breathes.
extends ScreenBase  # Shared background, margins and column.

const LOGO_SIZE := 380.0  # Logo width and height (D-017 working value).
const BUTTON_WIDTH := 760.0  # Every menu button has this width, as on the Level end screen, so they line up.
const TWINKLE_SPOTS: Array[Vector2] = [Vector2(0.74, 0.16), Vector2(0.18, 0.34), Vector2(0.84, 0.66)]  # Where the sparkle shows on the logo, as parts of its size.

var _buttons: Array[Button] = []  # The four buttons, top to bottom.
var _play_breath: CenterContainer  # The box around Play that grows and shrinks, so Play's own size is free for its tap bounce.
var _title: HBoxContainer  # The waving DIVIRUSH title.
var _tagline: Label  # "Quick-tap division!"
var _star_pill: PanelContainer  # The white pill with the total Stars.
var _logo: TextureRect  # The floating logo.
var _next_spot := 0  # Which spot the next sparkle uses.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Calm menu music.
	add_spacer(0.8)  # Space at the top.
	_add_hero()  # Logo, title, tagline and Stars.
	add_spacer(1.0)  # Space between the top part and the buttons.
	_add_buttons()  # The four buttons.
	add_spacer(0.6)  # Space at the bottom, a little less than at the top, so the buttons sit low for thumbs.
	_start_twinkles()  # Sparkles on the logo now and then.


# Adds the top part: the floating logo, the waving title, the tagline and the Star pill.
func _add_hero() -> void:
	var hero := VBoxContainer.new()  # The top part, stacked.
	hero.add_theme_constant_override("separation", 10)  # Close together, so they read as one group.
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	column.add_child(hero)  # Show it first, because animations need it on screen.
	var holder := Control.new()  # A plain box that keeps the logo's place; the logo floats inside it.
	holder.custom_minimum_size = Vector2(LOGO_SIZE, LOGO_SIZE)  # As big as the logo.
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	hero.add_child(holder)  # Show the box.
	_logo = TextureRect.new()  # The logo picture.
	_logo.texture = SpriteSheet.logo()  # Yellow ÷ bubble.
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep its shape.
	_logo.size = Vector2(LOGO_SIZE, LOGO_SIZE)  # Its size on screen.
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	holder.add_child(_logo)  # Put the logo in its box.
	UiKit.pop_in(_logo, 0.05)  # Bounce in first.
	UiKit.bob(_logo, 16.0, 2.4, 0.5)  # Then float 16 px up and down every 2.4 s (D-017).
	_title = UiKit.wave_title(130)  # DIVIRUSH, one letter at a time.
	hero.add_child(_title)  # Show it; its letters bounce in, then wave.
	_tagline = UiKit.label("Quick-tap division!", 56, Palette.WHITE, 14)  # The tagline, as on the Start-up menu.
	hero.add_child(_tagline)  # Show it.
	UiKit.pop_in(_tagline, 0.7)  # Bounce in after the title letters.
	_star_pill = _make_star_pill()  # The total-Stars pill.
	hero.add_child(_star_pill)  # Show it.
	UiKit.pop_in(_star_pill, 0.8)  # Bounce in last.


# Makes the white pill with a gold Star and "earned/180", the learner's total Stars (D-017).
func _make_star_pill() -> PanelContainer:
	var pill := PanelContainer.new()  # The pill.
	var style := UiKit.box(Palette.WHITE, 40, 5)  # White, round, with a thin dark outline, like the Level select Star pill.
	style.set_content_margin_all(6)  # A little space around the Star and numbers ...
	style.content_margin_left = 22  # ... more at the ends ...
	style.content_margin_right = 26  # ... so the pill looks round.
	pill.add_theme_stylebox_override("panel", style)  # Use this look.
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Only as wide as its content, centred.
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	pill.add_child(make_stars_badge(Save.progress.total_stars(), Progress.MAX_STARS))  # Star icon and "5/180", as on the Episode cards.
	return pill  # Hand back the pill.


# Adds the four buttons, straight and lined up, each with its icon. Play is taller and breathes.
func _add_buttons() -> void:
	var list := VBoxContainer.new()  # The buttons, stacked.
	list.add_theme_constant_override("separation", 28)  # Even gaps between buttons.
	column.add_child(list)  # Show it first, because animations need it on screen.
	_play_breath = CenterContainer.new()  # The box that breathes around Play.
	_play_breath.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred, as wide as Play.
	_play_breath.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to Play itself.
	list.add_child(_play_breath)  # Play's place in the list.
	_add_button(_play_breath, "Play", UiKit.Icon.PLAY, Palette.GREEN, 190.0, 84, _on_play, 0.05)  # Biggest button first.
	_add_button(list, "How to Play", UiKit.Icon.HELP, Palette.YELLOW, 150.0, 64, _on_how_to_play, 0.15)  # Rules screen.
	_add_button(list, "Settings", UiKit.Icon.GEAR, Palette.WHITE, 150.0, 64, _on_settings, 0.25)  # Switches screen.
	_add_button(list, "Exit", UiKit.Icon.EXIT, Palette.PINK, 150.0, 64, _on_exit, 0.35)  # Close the game.
	UiKit.pulse(_play_breath, 0.06, 1.2)  # Only Play breathes: 6% bigger and back every 1.2 s (D-017).


# Adds one menu button with its icon to `parent`; it pops in after `delay` and then stands still.
func _add_button(parent: Control, text: String, icon: int, colour: Color, height: float, font_size: int, action: Callable, delay: float) -> void:
	var button := UiKit.icon_button(text, icon, colour, Vector2(BUTTON_WIDTH, height), font_size)  # Chunky button with its icon.
	button.pressed.connect(action)  # What it does.
	parent.add_child(button)  # Show it.
	UiKit.pop_in(button, delay)  # Bounce in one after another.
	_buttons.append(button)  # Remember it, top to bottom.


# Starts the sparkles: the first soon after the menu opens, then one every 3 s (D-017).
func _start_twinkles() -> void:
	var start := create_tween()  # A one-time tween for the first wait.
	start.tween_interval(1.1)  # Wait until the logo has popped in.
	start.tween_callback(_twinkle_forever)  # Then sparkle again and again.


# Shows a sparkle now and then every 3 s, for as long as the menu is open.
func _twinkle_forever() -> void:
	var tween := create_tween().set_loops()  # A tween that repeats forever.
	tween.tween_callback(_twinkle)  # Sparkle ...
	tween.tween_interval(3.0)  # ... then wait 3 s.


# Shows one sparkle on the logo, at the next of the spots in turn.
func _twinkle() -> void:
	var sparkle := Sparkle.new()  # A sparkle that plays once and removes itself.
	var spot: Vector2 = TWINKLE_SPOTS[_next_spot % TWINKLE_SPOTS.size()] * LOGO_SIZE  # Where on the logo.
	sparkle.position = spot - sparkle.size / 2.0  # Centre the sparkle on that spot.
	_logo.add_child(sparkle)  # Show it on the logo, so it floats with the logo.
	_next_spot += 1  # Use the next spot next time.


# Play opens Episode select.
func _on_play() -> void:
	Game.go_to("episode_select")  # Next screen in the path.


# How to Play opens the rules screen.
func _on_how_to_play() -> void:
	Game.go_to("how_to_play")  # Rules screen.


# Settings opens the switches screen.
func _on_settings() -> void:
	Game.go_to("settings_screen")  # Switches screen.


# Exit saves and closes the game.
func _on_exit() -> void:
	Game.quit_game()  # Save and close.


# Back on the Main menu returns to the Start-up menu.
func go_back() -> void:
	Game.go_to("start_screen")  # First screen.
