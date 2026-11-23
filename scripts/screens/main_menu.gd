# Main menu, laid out as a home dashboard on its own candy sky (D-022): a small floating logo, a
# "My progress" card, one big breathing Play button, a 2 x 2 grid of icon tiles (How to Play,
# Trophies, My Records, Settings), and a small Exit that asks first (D-021). No title, as asked.
extends ScreenBase  # Shared background, margins and column.

const LOGO_SIZE := 220.0  # Logo width and height: small, since the screen has no title now.
const TILE_SIZE := Vector2(436, 210)  # Each of the four tiles, so two fit side by side.
const TWINKLE_SPOTS: Array[Vector2] = [Vector2(0.74, 0.16), Vector2(0.18, 0.34), Vector2(0.84, 0.66)]  # Where the sparkle shows on the logo, as parts of its size.

var _buttons: Array[Button] = []  # Play, the four tiles and Exit, top to bottom.
var _play_breath: CenterContainer  # The box around Play that grows and shrinks, so Play's own size is free for its tap bounce.
var _logo: TextureRect  # The floating logo.
var _next_spot := 0  # Which spot the next sparkle uses.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	add_spacer(0.5)  # Space at the top.
	_add_logo()  # The small floating logo.
	column.add_child(_make_progress_card())  # Stars, Trophies and Levels at a glance.
	add_spacer(0.5)  # Space above Play.
	_add_play()  # The big Play button.
	_add_tiles()  # The four tiles.
	_add_exit()  # The small Exit button.
	add_spacer(0.4)  # Space at the bottom.
	_start_twinkles()  # Sparkles on the logo now and then.


# The Main menu has its own candy sky: pink to lavender with numbers and ÷ signs (D-022).
func sky_look() -> int:
	return SkyBackground.Look.CANDY  # Candy look.


# Adds the small logo, floating up and down inside a fixed box so the layout never moves.
func _add_logo() -> void:
	var holder := Control.new()  # A plain box that keeps the logo's place.
	holder.custom_minimum_size = Vector2(LOGO_SIZE, LOGO_SIZE)  # As big as the logo.
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	column.add_child(holder)  # Show the box first, because animations need it on screen.
	_logo = TextureRect.new()  # The logo picture.
	_logo.texture = SpriteSheet.logo()  # Yellow ÷ bubble.
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep its shape.
	_logo.size = Vector2(LOGO_SIZE, LOGO_SIZE)  # Its size on screen.
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	holder.add_child(_logo)  # Put the logo in its box.
	UiKit.pop_in(_logo, 0.05)  # Bounce in first.
	UiKit.bob(_logo, 12.0, 2.4, 0.5)  # Then float 12 px up and down every 2.4 s.


# Makes the white "My progress" card: Stars of 180, Trophies of 12 and Levels passed of 60 (D-022).
func _make_progress_card() -> PanelContainer:
	var card := PanelContainer.new()  # The card.
	var style := UiKit.box(Palette.WHITE, 48)  # White, round and outlined, like the other cards.
	style.set_content_margin_all(22)  # Room inside the card.
	card.add_theme_stylebox_override("panel", style)  # Use this look.
	card.custom_minimum_size.x = 900.0  # Nearly as wide as the screen.
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	var row := HBoxContainer.new()  # The three counts side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	row.add_theme_constant_override("separation", 60)  # Space between them.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	card.add_child(row)  # Put the row on the card.
	row.add_child(_make_count(UiKit.Icon.STAR, Save.progress.total_stars(), Progress.MAX_STARS, "Stars"))  # Stars earned.
	row.add_child(_make_count(UiKit.Icon.TROPHY, Save.records.trophies.size(), Trophies.ALL.size(), "Trophies"))  # Trophies earned.
	row.add_child(_make_count(UiKit.Icon.CHART, Save.progress.levels_passed(), Progress.LEVEL_TOTAL, "Levels"))  # Levels passed.
	return card  # Hand back the card.


# Makes one count on the progress card: an icon and "earned/total" above a small word.
func _make_count(which: int, earned: int, total: int, word: String) -> VBoxContainer:
	var count := VBoxContainer.new()  # Number above word.
	count.add_theme_constant_override("separation", 0)  # Close together.
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	var top := HBoxContainer.new()  # Icon beside the number.
	top.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred.
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	top.add_child(UiKit.icon(which, 60))  # The icon.
	top.add_child(UiKit.label("%d/%d" % [earned, total], 50, Palette.INK))  # For example "5/180".
	count.add_child(top)  # Add the top line.
	count.add_child(UiKit.label(word, 34, Palette.BLUE))  # "Stars", "Trophies" or "Levels".
	return count  # Hand back the count.


# Adds the big Play button, which breathes so the eye goes to it first (D-017, kept by D-022).
func _add_play() -> void:
	_play_breath = CenterContainer.new()  # The box that breathes around Play.
	_play_breath.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred, as wide as Play.
	_play_breath.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to Play itself.
	column.add_child(_play_breath)  # Play's place in the column.
	_add_button(_play_breath, UiKit.icon_button("Play", UiKit.Icon.PLAY, Palette.GREEN, Vector2(900, 200), 88), _on_play, 0.1)  # The biggest button.
	UiKit.pulse(_play_breath, 0.05, 1.2)  # Only Play breathes: 5% bigger and back every 1.2 s.


# Adds the 2 x 2 grid of tiles: How to Play, Trophies, My Records and Settings.
func _add_tiles() -> void:
	var grid := GridContainer.new()  # Two tiles per row.
	grid.columns = 2  # Two columns.
	grid.add_theme_constant_override("h_separation", 28)  # Space between the columns.
	grid.add_theme_constant_override("v_separation", 28)  # Space between the rows.
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	column.add_child(grid)  # Show it first, because animations need it on screen.
	_add_button(grid, UiKit.tile_button("How to Play", UiKit.Icon.HELP, Palette.YELLOW, TILE_SIZE, 50), _on_how_to_play, 0.2)  # Rules screen.
	_add_button(grid, UiKit.tile_button("Trophies", UiKit.Icon.TROPHY, Palette.ORANGE, TILE_SIZE, 50), _on_trophies, 0.25)  # Trophies screen (D-023).
	_add_button(grid, UiKit.tile_button("My Records", UiKit.Icon.CHART, Palette.SKY_TOP, TILE_SIZE, 50), _on_records, 0.3)  # My Records screen (D-023).
	_add_button(grid, UiKit.tile_button("Settings", UiKit.Icon.GEAR, Palette.WHITE, TILE_SIZE, 50), _on_settings, 0.35)  # Switches screen.


# Adds the small pink Exit button at the bottom; it asks first (D-021).
func _add_exit() -> void:
	var exit := UiKit.icon_button("Exit", UiKit.Icon.EXIT, Palette.PINK, Vector2(360, 110), 48)  # Small, so it is not tapped by mistake.
	_add_button(column, exit, _on_exit, 0.4)  # At the bottom of the column.


# Adds one button to `parent`; it does `action` when tapped and pops in after `delay`.
func _add_button(parent: Control, button: Button, action: Callable, delay: float) -> void:
	button.pressed.connect(action)  # What it does.
	parent.add_child(button)  # Show it.
	UiKit.pop_in(button, delay)  # Bounce in one after another.
	_buttons.append(button)  # Remember it, top to bottom.


# Starts the sparkles: the first soon after the menu opens, then one every 3 s.
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


# Trophies opens the Trophies screen (D-023).
func _on_trophies() -> void:
	Game.go_to("trophies_screen")  # Trophies screen.


# My Records opens the learner's game records (D-023).
func _on_records() -> void:
	Game.go_to("records_screen")  # My Records screen.


# Settings opens the switches screen.
func _on_settings() -> void:
	Game.go_to("settings_screen")  # Switches screen.


# Exit first asks with the "Leave DiviRush?" card; its Exit button saves and closes the game (D-021).
func _on_exit() -> void:
	show_exit_card()  # Ask before closing.


# Back on the Main menu returns to the Start-up menu.
func go_back() -> void:
	Game.go_to("start_screen")  # First screen.
