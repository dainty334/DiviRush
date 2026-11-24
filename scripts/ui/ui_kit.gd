# Builds the DiviRush look: the theme, labels, chunky cartoon buttons, icons and small animations.
# Screens call these helpers so every screen looks and moves the same way.
class_name UiKit  # Lets any script write UiKit.button(...).
extends RefCounted  # Only its static functions are used.

enum Icon { BACK, STAR, STAR_EMPTY, CLOCK, LOCK, MUSIC, SOUND, VIBRATION, PLAY, HELP, GEAR, EXIT, TROPHY, CHART, PENCIL, TICK, FLAME }  # Frame order in icons_96x96_17f.png.

const FONT_PATH := "res://assets/fonts/Fredoka-Variable.ttf"  # Rounded font (OFL licence, D-010).
const BORDER := 10  # Thick dark outline width, as in the style sample.

static var _font: FontVariation  # The bold Fredoka font, made once.
static var _grey: ShaderMaterial  # The grey look for Trophies not yet earned, made once (D-031).


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


# Makes a chunky button with a drawn icon on its left and its words in the middle (Main menu, D-017).
# The words stay centred on the button, as on every other button, so the buttons line up.
# `side` is the icon's size and `inset` its distance from the button's left edge; small buttons use smaller ones.
static func icon_button(text: String, which: int, colour: Color, min_size: Vector2, font_size: int, side: float = 84.0, inset: float = 44.0) -> Button:
	var node := button(text, colour, min_size, font_size)  # The usual chunky button.
	var picture := icon(which, side)  # The drawn icon.
	picture.anchor_top = 0.5  # Hang the icon from the button's middle ...
	picture.anchor_bottom = 0.5  # ... so it stays centred up and down.
	picture.offset_left = inset  # Its left edge, inside the button.
	picture.offset_right = inset + side  # Its right edge.
	picture.offset_top = -side / 2.0  # Half above the middle ...
	picture.offset_bottom = side / 2.0  # ... and half below.
	node.add_child(picture)  # Put the icon on the button.
	return node  # Hand back the button.


# Makes a flat button for a bottom bar (Main menu, D-025): its icon at the top and its name underneath,
# with no box of its own, so the bar around it is the only box. It darkens a little while held.
static func bar_button(text: String, which: int, min_size: Vector2, font_size: int) -> Button:
	var node := Button.new()  # A new button.
	node.text = text  # Its name.
	node.custom_minimum_size = min_size  # Big enough for small fingers.
	node.add_theme_font_override("font", font())  # Fredoka.
	node.add_theme_font_size_override("font_size", font_size)  # How big the name is.
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:  # Every text state ...
		node.add_theme_color_override(state, Palette.INK)  # ... uses dark text.
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:  # Each look of the button ...
		var style := StyleBoxFlat.new()  # ... a plain box,
		style.bg_color = Color(Palette.INK, 0.08) if state in ["pressed", "hover_pressed"] else Color(0, 0, 0, 0)  # ... see-through, a light shade while held,
		style.set_corner_radius_all(32)  # ... with round corners,
		style.content_margin_top = 96.0  # ... and room for the icon above the name.
		node.add_theme_stylebox_override(state, style)  # Use it.
	node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())  # No extra focus frame on phones.
	add_press_bounce(node)  # Squash and spring when tapped.
	var side := 76.0  # Icon size.
	var picture := icon(which, side)  # The drawn icon.
	picture.anchor_left = 0.5  # Hang the icon from the button's middle ...
	picture.anchor_right = 0.5  # ... so it stays centred across.
	picture.offset_left = -side / 2.0  # Half to the left ...
	picture.offset_right = side / 2.0  # ... and half to the right.
	picture.offset_top = 16.0  # Near the top edge ...
	picture.offset_bottom = 16.0 + side  # ... and as tall as the icon.
	node.add_child(picture)  # Put the icon on the button.
	return node  # Hand back the button.


# Makes a square-ish tile button with its icon at the top and its words underneath (Main menu
# tiles, D-022). The words are the button's own text, pushed below the icon by a big top margin.
static func tile_button(text: String, which: int, colour: Color, min_size: Vector2, font_size: int) -> Button:
	var node := button(text, colour, min_size, font_size)  # The usual chunky button.
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:  # Each look of the button ...
		var style := node.get_theme_stylebox(state).duplicate() as StyleBoxFlat  # ... a copy of its box,
		style.content_margin_top = 104.0  # ... with room for the icon above the words,
		node.add_theme_stylebox_override(state, style)  # ... used instead.
	var side := 84.0  # Icon size on the tile.
	var picture := icon(which, side)  # The drawn icon.
	picture.anchor_left = 0.5  # Hang the icon from the tile's middle ...
	picture.anchor_right = 0.5  # ... so it stays centred across.
	picture.offset_left = -side / 2.0  # Half to the left ...
	picture.offset_right = side / 2.0  # ... and half to the right.
	picture.offset_top = 26.0  # Near the top edge ...
	picture.offset_bottom = 26.0 + side  # ... and as tall as the icon.
	node.add_child(picture)  # Put the icon on the tile.
	return node  # Hand back the tile.


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


# Makes one small white count pill: an icon and "earned/total", for example "5/180".
# Used on the Profile screen for Stars, Trophies and Levels passed (D-030).
static func count_pill(which: int, earned: int, total: int) -> PanelContainer:
	var pill := PanelContainer.new()  # The pill.
	var style := box(Palette.WHITE, 40, 5)  # White, round, with a thin dark outline.
	style.set_content_margin_all(8)  # A little space inside ...
	style.content_margin_left = 16  # ... more at the ends,
	style.content_margin_right = 22  # ... so it looks round.
	pill.add_theme_stylebox_override("panel", style)  # Use this look.
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Not stretched tall.
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	var row := HBoxContainer.new()  # Icon beside the number.
	row.add_theme_constant_override("separation", 8)  # Close together.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	row.add_child(icon(which, 60))  # The icon.
	row.add_child(label("%d/%d" % [earned, total], 46, Palette.INK))  # The count.
	pill.add_child(row)  # Put them in the pill.
	return pill  # Hand back the pill.


# Makes one Trophy's own picture, `size` pixels square (D-031). A Trophy not yet earned shows its
# picture in grey with a small lock in the corner, so the learner sees what they are working towards.
static func trophy_picture(id: String, size: float, earned: bool) -> Control:
	var holder := Control.new()  # Holds the picture and, when locked, the lock.
	holder.custom_minimum_size = Vector2(size, size)  # Its size.
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the card around it.
	var picture := TextureRect.new()  # The Trophy's picture.
	picture.texture = SpriteSheet.trophies()[maxi(Trophies.index_of(id), 0)]  # Its own frame.
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep its shape.
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the holder.
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	holder.add_child(picture)  # Show it.
	if not earned:  # Not earned yet ...
		picture.material = _grey_material()  # ... so grey,
		var lock := icon(Icon.LOCK, size * 0.38)  # ... with a small lock,
		lock.anchor_left = 1.0  # ... hung from the right ...
		lock.anchor_right = 1.0  # ... edge,
		lock.anchor_top = 1.0  # ... and the bottom ...
		lock.anchor_bottom = 1.0  # ... edge,
		lock.offset_left = -size * 0.38  # ... in the corner.
		lock.offset_top = -size * 0.38  # Its top edge.
		holder.add_child(lock)  # Show it.
	return holder  # Hand back the picture.


# Returns the grey look for pictures of Trophies not yet earned: it keeps each picture's shape but
# turns its colours to soft grey (D-031). Made once, in code, so no shader file is needed.
static func _grey_material() -> ShaderMaterial:
	if _grey == null:  # Not made yet ...
		var shader := Shader.new()  # ... a small shader,
		shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat g = dot(c.rgb, vec3(0.3, 0.59, 0.11));\n\tCOLOR = vec4(vec3(g * 0.55 + 0.35), c.a * 0.9);\n}\n"  # ... that mixes each colour to a light grey,
		_grey = ShaderMaterial.new()  # ... in a material,
		_grey.shader = shader  # ... using it.
	return _grey  # Hand back the material.


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
