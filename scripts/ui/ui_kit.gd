# Builds the DiviRush look: the theme, labels, chunky cartoon buttons, icons and small animations.
# Screens call these helpers so every screen looks and moves the same way.
class_name UiKit  # Lets any script write UiKit.button(...).
extends RefCounted  # Only its static functions are used.

enum Icon { BACK, STAR, STAR_EMPTY, CLOCK, LOCK, MUSIC, SOUND, VIBRATION, PLAY, HELP, GEAR, EXIT }  # Frame order in icons_96x96_12f.png.

const FONT_PATH := "res://assets/fonts/Fredoka-Variable.ttf"  # Rounded font (OFL licence, D-010).
const BORDER := 10  # Thick dark outline width, as in the style sample.

static var _font: FontVariation  # The bold Fredoka font, made once.


# Returns Fredoka at a bold weight. Fredoka is a variable font, so the weight is set here.
static func font() -> FontVariation:
	if _font == null:  # Not made yet ...
		_font = FontVariation.new()  # ... make a font variation,
		_font.base_font = load(FONT_PATH)  # ... based on the Fredoka file,
		var weight_axis := TextServerManager.get_primary_interface().name_to_tag("wght")  # The font's weight setting, as a number Godot reads.
		_font.variation_opentype = {weight_axis: 600}  # ... at weight 600 (semi-bold), like the sample.
	return _font  # Hand back the font.


# Makes the big DIVIRUSH title. It has extra space between letters, because at this weight
# the letters I and V touch and "DIVIRUSH" can be misread as "DMIRUSH".
static func title(size: int) -> Label:
	var node := label("DIVIRUSH", size, Palette.YELLOW, int(size / 5.0))  # Yellow title with a thick outline.
	var spaced := FontVariation.new()  # A copy of the font ...
	spaced.base_font = load(FONT_PATH)  # ... based on the Fredoka file,
	spaced.variation_opentype = font().variation_opentype  # ... at the same bold weight,
	spaced.spacing_glyph = int(size / 10.0)  # ... with space added after every letter.
	node.label_settings.font = spaced  # Use the spaced font for the title.
	return node  # Hand back the title.


# Makes the DIVIRUSH title with every letter on its own, so the letters can bounce in one by one
# and then wave (Main menu, D-017). Each letter sits in a holder box, because a container would
# move a letter back into line; inside a plain holder the letter is free to rise and fall.
# The animations start when the title is shown, since tweens need the node on screen.
static func wave_title(size: int) -> HBoxContainer:
	var row := HBoxContainer.new()  # The letters side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Only as wide as the word.
	row.add_theme_constant_override("separation", int(size / 10.0))  # The same gap title() adds, so I and V do not touch.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	var letters: Array[Label] = []  # The letter labels, for the animations below.
	for character in "DIVIRUSH":  # Each letter of the name ...
		var letter := label(character, size, Palette.YELLOW, int(size / 5.0))  # ... yellow with a thick outline, as in title().
		letter.size = letter.get_minimum_size()  # Exactly as big as its letter.
		var holder := Control.new()  # A plain box that keeps the letter's place in the row.
		holder.custom_minimum_size = letter.size  # The same size as the letter.
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
		holder.add_child(letter)  # The letter inside its box.
		row.add_child(holder)  # The box in the row.
		letters.append(letter)  # Remember the letter.
	row.ready.connect(func() -> void: _start_wave(letters, size), CONNECT_ONE_SHOT)  # Animate once the title is on screen.
	return row  # Hand back the title.


# Pops the title letters in one after another, then makes them rise and fall in turn, like a wave.
# Called once, when the wave title is first shown.
static func _start_wave(letters: Array[Label], size: int) -> void:
	for i in range(letters.size()):  # Each letter, left to right ...
		pop_in(letters[i], 0.1 + i * 0.06)  # ... bounces in 0.06 s after the one before (D-017),
		bob(letters[i], size * 0.08, 1.2, 0.9 + i * 0.12)  # ... then rises and falls a little later than the one before.


# Makes a chunky button with a drawn icon on its left and its words in the middle (Main menu, D-017).
# The words stay centred on the button, as on every other button, so the buttons line up.
static func icon_button(text: String, which: int, colour: Color, min_size: Vector2, font_size: int) -> Button:
	var node := button(text, colour, min_size, font_size)  # The usual chunky button.
	var side := 84.0  # Icon size on the button.
	var picture := icon(which, side)  # The drawn icon.
	picture.anchor_top = 0.5  # Hang the icon from the button's middle ...
	picture.anchor_bottom = 0.5  # ... so it stays centred up and down.
	picture.offset_left = 44.0  # Its left edge, inside the button.
	picture.offset_right = 44.0 + side  # Its right edge.
	picture.offset_top = -side / 2.0  # Half above the middle ...
	picture.offset_bottom = side / 2.0  # ... and half below.
	node.add_child(picture)  # Put the icon on the button.
	return node  # Hand back the button.


# Builds the game-wide theme. Called once at start-up by the Game autoload.
static func build_theme() -> Theme:
	var theme := Theme.new()  # An empty theme.
	theme.default_font = font()  # Every text uses Fredoka.
	theme.default_font_size = 48  # Big, readable text for children.
	theme.set_color("font_color", "Label", Palette.INK)  # Labels are dark by default.
	return theme  # Hand back the theme.


# Makes a text label. Used for titles, numbers and notes on every screen.
static func label(text: String, size: int, colour: Color = Palette.WHITE, outline: int = 0) -> Label:
	var node := Label.new()  # A new label.
	node.text = text  # Its words.
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Centred across.
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER  # Centred up and down.
	var settings := LabelSettings.new()  # Font settings for this label.
	settings.font = font()  # Fredoka.
	settings.font_size = size  # How big.
	settings.font_color = colour  # Text colour.
	settings.outline_size = outline  # Dark outline width (0 = none).
	settings.outline_color = Palette.INK  # Outline colour.
	node.label_settings = settings  # Use these settings.
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through to what is behind.
	return node  # Hand back the label.


# Makes a rounded box with a thick dark outline, used for cards, buttons and badges.
static func box(colour: Color, radius: int = 48, border: int = BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()  # A flat-colour box.
	style.bg_color = colour  # Fill colour.
	style.border_color = Palette.INK  # Outline colour.
	style.set_border_width_all(border)  # Outline on every side ...
	style.border_width_bottom = border + 8  # ... a little thicker at the bottom for a chunky 3D look.
	style.set_corner_radius_all(radius)  # Round corners.
	style.set_content_margin_all(20)  # Space between the outline and the content.
	style.anti_aliasing = true  # Smooth round edges.
	return style  # Hand back the box.


# Makes a chunky cartoon button with a bounce when pressed. Used for every menu button.
static func button(text: String, colour: Color, min_size: Vector2 = Vector2(760, 150), font_size: int = 64) -> Button:
	var node := Button.new()  # A new button.
	node.text = text  # Its words.
	node.custom_minimum_size = min_size  # Big enough for small fingers.
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred in its row.
	style_button(node, colour)  # Colours and outline.
	node.add_theme_font_override("font", font())  # Fredoka.
	node.add_theme_font_size_override("font_size", font_size)  # How big the words are.
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:  # Every text state ...
		node.add_theme_color_override(state, Palette.INK)  # ... uses dark text.
	add_press_bounce(node)  # Squash and spring when tapped.
	return node  # Hand back the button.


# Makes a blank card button; the caller puts labels and icons inside it.
static func card_button(colour: Color, min_size: Vector2, radius: int = 56) -> Button:
	var node := Button.new()  # A new button with no text.
	node.custom_minimum_size = min_size  # Its size.
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred in its row.
	style_button(node, colour, radius)  # Colours and outline.
	add_press_bounce(node)  # Squash and spring when tapped.
	return node  # Hand back the card.


# Sets a button's colours for every state: normal, hover, pressed and disabled.
static func style_button(node: Button, colour: Color, radius: int = 48) -> void:
	node.add_theme_stylebox_override("normal", box(colour, radius))  # Normal look.
	node.add_theme_stylebox_override("hover", box(colour.lightened(0.12), radius))  # A bit lighter under a mouse.
	node.add_theme_stylebox_override("pressed", box(colour.darkened(0.12), radius))  # A bit darker while held.
	node.add_theme_stylebox_override("hover_pressed", box(colour.darkened(0.12), radius))  # Same while held under a mouse.
	node.add_theme_stylebox_override("disabled", box(Palette.LOCKED, radius))  # Grey when switched off.
	node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())  # No extra focus frame on phones.


# Keeps a control's turning point in its middle, so it grows, shrinks and wobbles around its centre.
static func center_pivot(node: Control) -> void:
	node.pivot_offset = node.size / 2.0  # Centre now ...
	node.resized.connect(func() -> void: node.pivot_offset = node.size / 2.0)  # ... and again whenever its size changes.


# Makes a button squash when held and spring back with a bounce, and play the tap sound.
static func add_press_bounce(node: BaseButton) -> void:
	center_pivot(node)  # Squash around the middle.
	node.button_down.connect(func() -> void: _scale_to(node, Vector2(0.92, 0.92), 0.07, Tween.TRANS_QUAD))  # Squash down.
	node.button_up.connect(func() -> void: _scale_to(node, Vector2.ONE, 0.35, Tween.TRANS_ELASTIC))  # Spring back.
	node.pressed.connect(func() -> void: Audio.play_sfx("tap"))  # Tap sound.


# Tweens a control's size scale, stopping any scale tween still running on it first.
static func _scale_to(node: Control, target: Vector2, seconds: float, trans: Tween.TransitionType) -> void:
	if node.has_meta("scale_tween"):  # An older scale tween ...
		var old: Tween = node.get_meta("scale_tween")  # ... is found,
		if old != null and old.is_valid():  # ... and still running,
			old.kill()  # ... so stop it, or the two would fight.
	var tween := node.create_tween()  # A new tween on this control.
	tween.tween_property(node, "scale", target, seconds).set_trans(trans).set_ease(Tween.EASE_OUT)  # Move to the new scale.
	node.set_meta("scale_tween", tween)  # Remember it so the next one can stop it.


# Makes a small icon from the icons sheet, for example UiKit.icon(UiKit.Icon.LOCK, 80).
static func icon(which: int, size: float = 96.0) -> TextureRect:
	var node := TextureRect.new()  # A picture node.
	node.texture = SpriteSheet.icons()[which]  # The chosen icon frame.
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Let it be any size.
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep its shape.
	node.custom_minimum_size = Vector2(size, size)  # Its size on screen.
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	return node  # Hand back the icon.


# Makes a control pop in from nothing with a bounce, after a delay. Used when screens open.
static func pop_in(node: Control, delay: float = 0.0) -> void:
	center_pivot(node)  # Grow from the middle.
	node.scale = Vector2.ZERO  # Start invisible (zero size).
	var tween := node.create_tween()  # A tween on this control.
	tween.tween_property(node, "scale", Vector2.ONE, 0.45).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # Grow with a small overshoot.


# Makes a control rock gently from side to side forever, so menus feel alive.
static func rock(node: Control, degrees: float = 2.0, seconds: float = 1.6, delay: float = 0.0) -> void:
	center_pivot(node)  # Rock around the middle.
	var tween := node.create_tween().set_loops()  # A tween that repeats forever.
	tween.tween_interval(delay)  # Wait first, so buttons do not all move together.
	tween.tween_property(node, "rotation", deg_to_rad(degrees), seconds / 2.0).set_trans(Tween.TRANS_SINE)  # Lean one way.
	tween.tween_property(node, "rotation", deg_to_rad(-degrees), seconds / 2.0).set_trans(Tween.TRANS_SINE)  # Lean the other way.


# Makes a control float up and down forever. The first rise waits `delay` seconds, then every rise
# and fall takes the same time, so controls given different delays keep their order (a wave).
# Used for the Main menu logo and title letters (D-017). The control must sit in a plain Control,
# not a container, or the container would move it back into line.
static func bob(node: Control, pixels: float, seconds: float, delay: float = 0.0) -> void:
	var rest := node.position.y  # Where the control rests.
	var start := node.create_tween()  # A one-time tween for the first wait.
	start.tween_interval(delay)  # Wait once, so each control starts at its own time.
	start.tween_callback(func() -> void: _float_forever(node, rest, pixels, seconds))  # Then float forever.


# Rises `pixels` above `rest` and falls back, again and again. Called by bob() after its first wait.
static func _float_forever(node: Control, rest: float, pixels: float, seconds: float) -> void:
	var tween := node.create_tween().set_loops()  # A tween that repeats forever.
	tween.tween_property(node, "position:y", rest - pixels, seconds / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # Rise.
	tween.tween_property(node, "position:y", rest, seconds / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # Fall back.


# Makes a control grow and shrink a little forever, like it is breathing. Used for "Tap to Start".
static func pulse(node: Control, amount: float = 0.08, seconds: float = 1.0) -> void:
	center_pivot(node)  # Pulse around the middle.
	var tween := node.create_tween().set_loops()  # A tween that repeats forever.
	tween.tween_property(node, "scale", Vector2.ONE * (1.0 + amount), seconds / 2.0).set_trans(Tween.TRANS_SINE)  # Grow.
	tween.tween_property(node, "scale", Vector2.ONE, seconds / 2.0).set_trans(Tween.TRANS_SINE)  # Shrink back.


# Shakes a control by quickly turning it left and right. Used when a locked card is tapped.
static func shake(node: Control) -> void:
	center_pivot(node)  # Turn around the middle.
	var tween := node.create_tween()  # A tween on this control.
	for angle in [8.0, -8.0, 5.0, -5.0, 0.0]:  # Smaller and smaller turns ...
		tween.tween_property(node, "rotation", deg_to_rad(angle), 0.06)  # ... each one quick.


# Shows text that floats up and fades away, for example "+25" over a bubble.
static func float_text(parent: Control, text: String, at: Vector2, colour: Color, size: int = 72) -> void:
	var node := label(text, size, colour, 16)  # Big outlined text.
	parent.add_child(node)  # Show it on top of the screen.
	node.position = at - Vector2(150, 50)  # Centre it on the given point.
	node.size = Vector2(300, 100)  # Room for the text.
	var tween := node.create_tween().set_parallel(true)  # Move and fade together.
	tween.tween_property(node, "position:y", node.position.y - 160.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)  # Float up.
	tween.tween_property(node, "modulate:a", 0.0, 0.9).set_delay(0.3)  # Fade out.
	tween.chain().tween_callback(node.queue_free)  # Remove it when done.
