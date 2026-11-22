# Draws all DiviRush art in the flat cartoon style (D-009) and saves it twice:
#   assets/art/<name>_<W>x<H>_<N>f.svg      the editable source drawing (all frames side by side)
#   assets/sprites/<name>_<W>x<H>_<N>f.png  the same drawing as a PNG sprite sheet on a fixed grid
# The PNG sheets can be edited in Piskel or Clip Studio Paint EX: each frame is W x H pixels,
# frames go left to right, and the game cuts them by the size in the file name.
# Run from the project folder with:
#   godot --headless --script res://tools/build_art.gd
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const INK := "#1B1B3A"  # Dark outline colour.
const YELLOW := "#FFD166"  # Sunny yellow.
const PINK := "#EF476F"  # Bright pink.
const GREEN := "#06D6A0"  # Correct-answer green.
const RED := "#D62839"  # Deeper red for a wrong answer.
const WHITE := "#FFFFFF"  # Card white.
const SKY := "#4CC9F0"  # Light sky blue.
const BLUE := "#4361EE"  # Deep sky blue.
const GREY := "#B8C0D9"  # Locked / empty grey-blue.
const ART_DIR := "res://assets/art/"  # Where the SVG sources go.
const SPRITE_DIR := "res://assets/sprites/"  # Where the PNG sheets go.


# Runs once when the tool starts: draws every sheet, then quits.
func _init() -> void:
	_save_sheet("bubble_yellow", 320, 320, _bubble_frames(YELLOW))  # Answer bubble, yellow.
	_save_sheet("bubble_green", 320, 320, _bubble_frames(GREEN))  # Answer bubble, green (also "correct").
	_save_sheet("bubble_pink", 320, 320, _bubble_frames(PINK))  # Answer bubble, pink.
	_save_sheet("bubble_red", 320, 320, _bubble_frames(RED))  # Answer bubble after a wrong tap.
	_save_sheet("sparkle", 160, 160, _sparkle_frames())  # Sparkle burst for a correct answer.
	_save_sheet("star", 200, 200, _star_frames())  # Level end Star filling up.
	_save_sheet("icons", 96, 96, _icon_frames())  # Small icons: back, Stars, clock, lock, music, sound, vibration.
	_save_sheet("logo", 512, 512, [_logo_frame()])  # Title-screen logo bubble.
	_save_icon_svg()  # The app icon (icon.svg in the project folder).
	quit()  # Close the tool when done.


# Puts frames side by side in one SVG, saves it, then rasterizes it to a PNG sheet.
func _save_sheet(name: String, w: int, h: int, frames: Array) -> void:
	var file_stem := "%s_%dx%d_%df" % [name, w, h, frames.size()]  # Example: bubble_yellow_320x320_6f.
	var body := ""  # The drawing of all frames.
	for i in range(frames.size()):  # Each frame ...
		body += "<g transform=\"translate(%d 0)\">%s</g>\n" % [i * w, frames[i]]  # ... moves right by one frame width.
	var svg := _svg(w * frames.size(), h, body)  # Wrap the frames in an SVG document.
	_write_text(ART_DIR + file_stem + ".svg", svg)  # Save the editable source.
	var image := Image.new()  # An empty picture.
	var error := image.load_svg_from_string(svg, 1.0)  # Let Godot draw the SVG at full size.
	if error != OK:  # Drawing failed ...
		push_error("SVG could not be drawn: " + file_stem)  # ... so say which one.
		return  # Stop for this sheet.
	image.save_png(SPRITE_DIR + file_stem + ".png")  # Save the PNG sprite sheet.
	print("saved ", file_stem)  # Report it.


# Wraps drawing commands in an SVG document of the given size.
func _svg(w: int, h: int, body: String) -> String:
	var head := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\">\n" % [w, h, w, h]  # Document start.
	return head + body + "</svg>\n"  # Document start, drawing, document end.


# Writes text to a file inside the project.
func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)  # Open the file for writing.
	if file == null:  # It could not be opened ...
		push_error("Could not write " + path)  # ... so say so.
		return  # Stop here.
	file.store_string(text)  # Write the text.


# Six bubble frames: 0 = resting bubble, 1-5 = the bubble popping into droplets.
func _bubble_frames(fill: String) -> Array:
	var c := 160.0  # Centre of the 320 x 320 frame.
	var shine := _bubble_shine(c, 145.0)  # White shine marks on the top left.
	var frames := []  # The finished frames.
	frames.append(_circle(c, c, 145.0, fill, 10.0) + shine)  # 0: resting bubble.
	frames.append(_ellipse(c, c + 4.0, 152.0, 140.0, fill, 10.0) + shine)  # 1: squashed, about to pop.
	frames.append(_circle(c, c, 154.0, fill, 8.0, 0.9) + shine)  # 2: stretched thin.
	frames.append(_broken_ring(c, 150.0, fill))  # 3: skin breaks into pieces.
	frames.append(_droplets(c, 125.0, 16.0, fill, 1.0))  # 4: droplets fly out.
	frames.append(_droplets(c, 150.0, 9.0, fill, 0.5))  # 5: droplets fade away.
	return frames  # Hand back all six.


# White shine marks that make a circle look like a shiny bubble, as in the style sample.
func _bubble_shine(c: float, r: float) -> String:
	var arc := "<path d=\"M%.0f %.0f A%.0f %.0f 0 0 1 %.0f %.0f\" fill=\"none\" stroke=\"%s\" stroke-width=\"20\" stroke-linecap=\"round\" opacity=\"0.8\"/>" % [c - r * 0.55, c - r * 0.45, r * 0.75, r * 0.75, c + r * 0.05, c - r * 0.8, WHITE]  # Curved highlight.
	var dot := "<circle cx=\"%.0f\" cy=\"%.0f\" r=\"11\" fill=\"%s\" opacity=\"0.8\"/>" % [c + r * 0.4, c - r * 0.66, WHITE]  # Small round highlight.
	return arc + dot  # Both marks together.


# A circle with a thick dark outline.
func _circle(cx: float, cy: float, r: float, fill: String, stroke_w: float, opacity: float = 1.0) -> String:
	return "<circle cx=\"%.1f\" cy=\"%.1f\" r=\"%.1f\" fill=\"%s\" stroke=\"%s\" stroke-width=\"%.1f\" opacity=\"%.2f\"/>" % [cx, cy, r, fill, INK, stroke_w, opacity]  # One SVG circle.


# An oval with a thick dark outline.
func _ellipse(cx: float, cy: float, rx: float, ry: float, fill: String, stroke_w: float) -> String:
	return "<ellipse cx=\"%.1f\" cy=\"%.1f\" rx=\"%.1f\" ry=\"%.1f\" fill=\"%s\" stroke=\"%s\" stroke-width=\"%.1f\"/>" % [cx, cy, rx, ry, fill, INK, stroke_w]  # One SVG oval.


# The bubble skin breaking: a faint inside and a dashed outline.
func _broken_ring(c: float, r: float, fill: String) -> String:
	var inside := "<circle cx=\"%.0f\" cy=\"%.0f\" r=\"%.0f\" fill=\"%s\" opacity=\"0.35\"/>" % [c, c, r, fill]  # Faint inside.
	var ring := "<circle cx=\"%.0f\" cy=\"%.0f\" r=\"%.0f\" fill=\"none\" stroke=\"%s\" stroke-width=\"12\" stroke-dasharray=\"60 40\" stroke-linecap=\"round\"/>" % [c, c, r, fill]  # Broken coloured skin.
	var ink := "<circle cx=\"%.0f\" cy=\"%.0f\" r=\"%.0f\" fill=\"none\" stroke=\"%s\" stroke-width=\"6\" stroke-dasharray=\"60 40\" stroke-linecap=\"round\"/>" % [c, c, r + 9.0, INK]  # Broken dark outline.
	return inside + ring + ink  # All three layers.


# Eight droplets on a ring around the centre.
func _droplets(c: float, ring_r: float, drop_r: float, fill: String, opacity: float) -> String:
	var out := ""  # The drawing.
	for i in range(8):  # Eight droplets ...
		var angle := TAU * i / 8.0 + 0.2  # ... spread evenly around the circle.
		var x := c + cos(angle) * ring_r  # Droplet position across.
		var y := c + sin(angle) * ring_r  # Droplet position down.
		out += "<circle cx=\"%.1f\" cy=\"%.1f\" r=\"%.1f\" fill=\"%s\" stroke=\"%s\" stroke-width=\"4\" opacity=\"%.2f\"/>" % [x, y, drop_r, fill, INK, opacity]  # One droplet.
	return out  # All droplets.


# Six sparkle frames: four-point stars that grow, turn, then fade.
func _sparkle_frames() -> Array:
	var sizes := [20.0, 45.0, 70.0, 62.0, 45.0, 25.0]  # Star size in each frame.
	var fades := [1.0, 1.0, 1.0, 0.85, 0.6, 0.3]  # How solid each frame is.
	var frames := []  # The finished frames.
	for i in range(6):  # Each frame.
		var big := _four_point_star(80.0, 80.0, sizes[i], YELLOW, fades[i], i * 8.0)  # Main sparkle.
		var small := _four_point_star(130.0, 40.0, sizes[i] * 0.35, WHITE, fades[i], -i * 10.0)  # Small helper sparkle.
		var dot := "<circle cx=\"35\" cy=\"125\" r=\"%.1f\" fill=\"%s\" opacity=\"%.2f\"/>" % [4.0 + i * 1.5, WHITE, fades[i]]  # Twinkle dot.
		frames.append(big + small + dot)  # Add the frame.
	return frames  # Hand back all six.


# A four-point sparkle star with a dark outline, turned by `spin` degrees.
func _four_point_star(cx: float, cy: float, r: float, fill: String, opacity: float, spin: float) -> String:
	var points := ""  # The corner list.
	for i in range(8):  # Eight corners: 4 long points and 4 short dips.
		var angle := deg_to_rad(spin) + TAU * i / 8.0 - PI / 2.0  # Angle of this corner.
		var radius := r if i % 2 == 0 else r * 0.3  # Long point or short dip.
		points += "%.1f,%.1f " % [cx + cos(angle) * radius, cy + sin(angle) * radius]  # Add the corner.
	return "<polygon points=\"%s\" fill=\"%s\" stroke=\"%s\" stroke-width=\"5\" stroke-linejoin=\"round\" opacity=\"%.2f\"/>" % [points, fill, INK, opacity]  # The star shape.


# The corner list of a five-point star centred at (cx, cy).
func _star_points(cx: float, cy: float, outer: float) -> String:
	var points := ""  # The corner list.
	for i in range(10):  # Ten corners: 5 points and 5 dips.
		var angle := TAU * i / 10.0 - PI / 2.0  # Start at the top point.
		var radius := outer if i % 2 == 0 else outer * 0.48  # Point or dip.
		points += "%.1f,%.1f " % [cx + cos(angle) * radius, cy + sin(angle) * radius]  # Add the corner.
	return points  # Hand back the list.


# Six Star frames: 0 = empty, 1-4 = gold filling from the middle, 5 = full and shining.
func _star_frames() -> Array:
	var empty := "<polygon points=\"%s\" fill=\"%s\" stroke=\"%s\" stroke-width=\"10\" stroke-linejoin=\"round\" opacity=\"0.9\"/>" % [_star_points(100, 106, 88), GREY, INK]  # Empty grey Star.
	var frames := [empty]  # Frame 0 is the empty Star.
	for scale in [0.3, 0.55, 0.8, 1.0]:  # Frames 1-4: the gold grows ...
		var gold := "<polygon points=\"%s\" fill=\"%s\" stroke-linejoin=\"round\"/>" % [_star_points(100, 106, 80 * scale), YELLOW]  # ... from the middle.
		var outline := "<polygon points=\"%s\" fill=\"none\" stroke=\"%s\" stroke-width=\"10\" stroke-linejoin=\"round\"/>" % [_star_points(100, 106, 88), INK]  # Outline on top.
		frames.append(empty + gold + outline)  # Add the frame.
	var full := "<polygon points=\"%s\" fill=\"%s\" stroke=\"%s\" stroke-width=\"10\" stroke-linejoin=\"round\"/>" % [_star_points(100, 106, 88), YELLOW, INK]  # Full gold Star.
	var shine := "<path d=\"M70 80 L86 62\" stroke=\"%s\" stroke-width=\"12\" stroke-linecap=\"round\" opacity=\"0.85\"/>" % WHITE  # Shine stroke.
	frames.append(full + shine)  # Frame 5: full and shining.
	return frames  # Hand back all six.


# Eight small 96 x 96 icons, in this order:
# 0 back arrow, 1 gold Star, 2 empty Star, 3 clock, 4 lock, 5 music note, 6 speaker, 7 vibrating phone.
func _icon_frames() -> Array:
	var frames := []  # The finished icons.
	frames.append("<path d=\"M60 20 L30 48 L60 76\" fill=\"none\" stroke=\"%s\" stroke-width=\"14\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>" % INK)  # 0: back arrow.
	frames.append("<polygon points=\"%s\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\" stroke-linejoin=\"round\"/>" % [_star_points(48, 51, 40), YELLOW, INK])  # 1: gold Star.
	frames.append("<polygon points=\"%s\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\" stroke-linejoin=\"round\" opacity=\"0.9\"/>" % [_star_points(48, 51, 40), GREY, INK])  # 2: empty Star.
	var clock := _circle(48, 50, 36, WHITE, 7.0)  # Clock face.
	clock += "<path d=\"M48 50 L48 28 M48 50 L64 58\" stroke=\"%s\" stroke-width=\"7\" stroke-linecap=\"round\"/>" % INK  # Clock hands.
	clock += "<rect x=\"40\" y=\"4\" width=\"16\" height=\"10\" rx=\"4\" fill=\"%s\"/>" % INK  # Clock top button.
	frames.append(clock)  # 3: clock.
	var lock := "<path d=\"M30 44 V32 A18 18 0 0 1 66 32 V44\" fill=\"none\" stroke=\"%s\" stroke-width=\"9\"/>" % INK  # Lock loop.
	lock += "<rect x=\"18\" y=\"42\" width=\"60\" height=\"46\" rx=\"12\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\"/>" % [YELLOW, INK]  # Lock body.
	lock += "<circle cx=\"48\" cy=\"62\" r=\"7\" fill=\"%s\"/>" % INK  # Key hole.
	frames.append(lock)  # 4: lock.
	var note := "<path d=\"M40 70 V18 L74 10 V60\" fill=\"none\" stroke=\"%s\" stroke-width=\"8\" stroke-linejoin=\"round\"/>" % INK  # Note stems and bar.
	note += "<ellipse cx=\"30\" cy=\"72\" rx=\"14\" ry=\"11\" fill=\"%s\"/><ellipse cx=\"64\" cy=\"62\" rx=\"14\" ry=\"11\" fill=\"%s\"/>" % [INK, INK]  # Note heads.
	frames.append(note)  # 5: music note.
	var speaker := "<polygon points=\"14,36 32,36 54,18 54,78 32,60 14,60\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\" stroke-linejoin=\"round\"/>" % [WHITE, INK]  # Speaker box.
	speaker += "<path d=\"M64 34 A18 18 0 0 1 64 62 M72 24 A30 30 0 0 1 72 72\" fill=\"none\" stroke=\"%s\" stroke-width=\"7\" stroke-linecap=\"round\"/>" % INK  # Sound waves.
	frames.append(speaker)  # 6: speaker.
	var phone := "<rect x=\"30\" y=\"12\" width=\"36\" height=\"72\" rx=\"9\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\"/>" % [WHITE, INK]  # Phone body.
	phone += "<path d=\"M16 34 L10 42 L16 50 L10 58 M80 34 L86 42 L80 50 L86 58\" fill=\"none\" stroke=\"%s\" stroke-width=\"6\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>" % INK  # Shake lines.
	frames.append(phone)  # 7: vibrating phone.
	return frames  # Hand back all eight.


# The logo: a big yellow bubble with a division sign, for the Start-up menu.
func _logo_frame() -> String:
	var out := _circle(256, 256, 220, YELLOW, 16.0)  # Big bubble.
	out += _bubble_shine(256, 220)  # Shine marks.
	out += "<circle cx=\"256\" cy=\"160\" r=\"34\" fill=\"%s\"/>" % INK  # Top dot of ÷.
	out += "<rect x=\"136\" y=\"232\" width=\"240\" height=\"48\" rx=\"24\" fill=\"%s\"/>" % INK  # Bar of ÷.
	out += "<circle cx=\"256\" cy=\"352\" r=\"34\" fill=\"%s\"/>" % INK  # Bottom dot of ÷.
	return out  # Hand back the logo.


# Saves the app icon (res://icon.svg): the logo bubble on a sky background, 128 x 128.
func _save_icon_svg() -> void:
	var defs := "<defs><linearGradient id=\"sky\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"%s\"/><stop offset=\"1\" stop-color=\"%s\"/></linearGradient></defs>" % [SKY, BLUE]  # Sky colours.
	var bg := "<rect width=\"512\" height=\"512\" rx=\"96\" fill=\"url(#sky)\"/>"  # Rounded sky square.
	var logo := "<g transform=\"translate(40 40) scale(0.84)\">%s</g>" % _logo_frame()  # Logo, a little smaller.
	var svg := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"128\" height=\"128\" viewBox=\"0 0 512 512\">%s%s%s</svg>\n" % [defs, bg, logo]  # The whole icon.
	_write_text("res://icon.svg", svg)  # Replace the default Godot icon.
	print("saved icon.svg")  # Report it.
