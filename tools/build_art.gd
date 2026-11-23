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
const NAVY := "#2B3A78"  # Navy blue school skirt and shorts (D-026).
const SHOE := "#2A2A33"  # Black school shoes (D-026).
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
	_save_sheet("icons", 96, 96, _icon_frames())  # Small icons: back, Stars, clock, lock, music, sound, vibration, and the Main menu icons.
	_save_sheet("logo", 512, 512, [_logo_frame()])  # Title-screen logo bubble.
	_save_sheet("mascot_ana", 450, 780, _mascot_parts(true))  # Ana from head to toe, in ten parts (D-026 to D-028).
	_save_sheet("mascot_migo", 450, 780, _mascot_parts(false))  # Migo from head to toe, in ten parts (D-026 to D-028).
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


# Fourteen small 96 x 96 icons, in this order:
# 0 back arrow, 1 gold Star, 2 empty Star, 3 clock, 4 lock, 5 music note, 6 speaker, 7 vibrating phone,
# 8 play arrow, 9 question mark, 10 gear, 11 door (for the Main menu, D-017), 12 Trophy, 13 bar chart (D-022, D-023).
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
	frames.append_array(_menu_icon_frames())  # 8-11: the Main menu button icons (D-017).
	frames.append_array(_progress_icon_frames())  # 12-13: Trophy and My Records icons (D-022, D-023).
	return frames  # Hand back all fourteen.


# Two icons for the progress screens (D-022, D-023): 12 a gold Trophy cup, 13 a bar chart for My Records.
func _progress_icon_frames() -> Array:
	var frames := []  # The finished icons.
	var cup := "<path d=\"M28 20 A12 12 0 0 0 28 46 M68 20 A12 12 0 0 1 68 46\" fill=\"none\" stroke=\"%s\" stroke-width=\"7\" stroke-linecap=\"round\"/>" % INK  # 12: the two handles ...
	cup += "<path d=\"M24 12 H72 V34 A24 24 0 0 1 24 34 Z\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\" stroke-linejoin=\"round\"/>" % [YELLOW, INK]  # ... the gold cup,
	cup += "<rect x=\"42\" y=\"56\" width=\"12\" height=\"14\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [YELLOW, INK]  # ... its stem,
	cup += "<rect x=\"28\" y=\"70\" width=\"40\" height=\"14\" rx=\"5\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\"/>" % [YELLOW, INK]  # ... its base,
	cup += "<path d=\"M36 20 V32\" stroke=\"%s\" stroke-width=\"6\" stroke-linecap=\"round\" opacity=\"0.85\"/>" % WHITE  # ... and a shine.
	frames.append(cup)  # 12: Trophy.
	var chart := "<rect x=\"14\" y=\"52\" width=\"18\" height=\"30\" rx=\"4\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [PINK, INK]  # 13: a short bar ...
	chart += "<rect x=\"39\" y=\"34\" width=\"18\" height=\"48\" rx=\"4\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [YELLOW, INK]  # ... a middle bar,
	chart += "<rect x=\"64\" y=\"14\" width=\"18\" height=\"68\" rx=\"4\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [GREEN, INK]  # ... a tall bar,
	chart += "<path d=\"M8 86 H88\" stroke=\"%s\" stroke-width=\"7\" stroke-linecap=\"round\"/>" % INK  # ... and the ground line.
	frames.append(chart)  # 13: My Records.
	return frames  # Hand back both.


# Four icons for the Main menu buttons (D-017), white with a dark outline so they show on every
# button colour: 8 play arrow, 9 question mark, 10 gear, 11 door with an arrow going out.
func _menu_icon_frames() -> Array:
	var frames := []  # The finished icons.
	frames.append("<polygon points=\"28,14 80,48 28,82\" fill=\"%s\" stroke=\"%s\" stroke-width=\"8\" stroke-linejoin=\"round\"/>" % [WHITE, INK])  # 8: play arrow.
	var help := _circle(48, 48, 40, WHITE, 7.0)  # 9: round white face ...
	help += "<path d=\"M35 36 A13 13 0 0 1 61 36 C61 46 48 46 48 56 V58\" fill=\"none\" stroke=\"%s\" stroke-width=\"9\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>" % INK  # ... with the hook of a question mark,
	help += "<circle cx=\"48\" cy=\"72\" r=\"6\" fill=\"%s\"/>" % INK  # ... and its dot.
	frames.append(help)  # 9: question mark.
	var gear := ""  # 10: gear.
	for i in range(8):  # Eight teeth around the middle ...
		var angle := TAU * i / 8.0  # ... spread evenly.
		var tip := Vector2(48, 48) + Vector2(cos(angle), sin(angle)) * 43.0  # Outer end of the tooth.
		gear += "<line x1=\"48\" y1=\"48\" x2=\"%.1f\" y2=\"%.1f\" stroke=\"%s\" stroke-width=\"22\"/>" % [tip.x, tip.y, INK]  # Dark tooth (its outline).
	for i in range(8):  # The same eight teeth again ...
		var angle := TAU * i / 8.0  # ... at the same angles,
		var tip := Vector2(48, 48) + Vector2(cos(angle), sin(angle)) * 37.0  # ... a little shorter,
		gear += "<line x1=\"48\" y1=\"48\" x2=\"%.1f\" y2=\"%.1f\" stroke=\"%s\" stroke-width=\"8\"/>" % [tip.x, tip.y, WHITE]  # ... and thinner and white, so each tooth has a dark outline.
	gear += _circle(48, 48, 28, WHITE, 7.0)  # Round gear body on top of the teeth.
	gear += _circle(48, 48, 10, WHITE, 7.0)  # Hole in the middle.
	frames.append(gear)  # 10: gear.
	var door := "<rect x=\"10\" y=\"10\" width=\"44\" height=\"76\" rx=\"6\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\"/>" % [WHITE, INK]  # 11: white door ...
	door += "<circle cx=\"21\" cy=\"50\" r=\"5\" fill=\"%s\"/>" % INK  # ... with a knob,
	door += "<path d=\"M38 48 H84 M72 35 L85 48 L72 61\" fill=\"none\" stroke=\"%s\" stroke-width=\"9\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>" % INK  # ... and an arrow going out.
	frames.append(door)  # 11: door.
	return frames  # Hand back all four.


const MASCOT_SKIN := "#E0A872"  # Warm brown skin for both mascots.
const MASCOT_HAIR := "#2B1B17"  # Dark brown-black hair for both mascots.
const MASCOT_SCALE := 1.5  # The mascot is drawn 1.5 times bigger than its 300 x 520 plan, so it stays sharp (D-027).
const MASCOT_HEAD_SCALE := 0.82  # The head is drawn smaller than its plan, so the mascot is about 3.5 heads tall (D-028).
const MASCOT_FINGER_INK := 12.0  # Width of a finger's dark outline (D-028).
const MASCOT_FINGER_SKIN := 6.0  # Width of a finger's skin inside the outline.


# The ten parts of a student mascot from head to toe (D-026 to D-028), each on its own 450 x 780
# frame at its place in the whole picture, so the game can stack them and move each part on its
# own. The order matches Mascot.Part: 0 body, 1 left arm, 2 right arm, 3 right arm waving with an
# open hand, 4 head, 5 eyes open, 6 eyes closed, 7 eyebrows, 8 mouth smiling, 9 mouth talking.
# Ana is a girl with pigtails, a clip, a blue ribbon and a navy skirt; Migo is a boy with short
# hair, a blue school patch and navy shorts (D-024, D-026).
func _mascot_parts(is_ana: bool) -> Array:
	var head := "translate(150 28) scale(%.2f) translate(-150 -28)" % MASCOT_HEAD_SCALE  # Shrinks the head from the top of the hair, so it sits on the neck.
	var parts := [  # The ten drawings, in the order the game expects.
		_mascot_body(is_ana),  # 0: backpack, body and legs.
		_mascot_arm(false, false),  # 1: left arm (on the viewer's left), fingers together.
		_mascot_arm(true, false),  # 2: right arm (on the viewer's right), fingers together.
		_mascot_arm(true, true),  # 3: right arm with the hand open wide, shown while waving (D-028).
		_in_group(head, _mascot_head(is_ana)),  # 4: hair, ears, face and cheeks, with no eyes, eyebrows or mouth.
		_in_group(head, _mascot_eyes(false)),  # 5: eyes open.
		_in_group(head, _mascot_eyes(true)),  # 6: eyes closed, for blinking.
		_in_group(head, _mascot_brows()),  # 7: eyebrows, which lift while talking.
		_in_group(head, _mascot_mouth(is_ana, false)),  # 8: smiling mouth.
		_in_group(head, _mascot_mouth(is_ana, true)),  # 9: talking mouth.
	]
	var frames := []  # The same drawings, made bigger.
	for part: String in parts:  # Each drawing ...
		frames.append(_in_group("scale(%.2f)" % MASCOT_SCALE, part))  # ... drawn 1.5 times bigger.
	return frames  # Hand back all ten.


# Wraps a drawing in an SVG group that moves or resizes it by `transform`.
func _in_group(transform: String, drawing: String) -> String:
	return "<g transform=\"%s\">%s</g>" % [transform, drawing]  # The wrapped drawing.


# The body, balanced for a head about a third of the height (D-028): a pink backpack behind, neck,
# chunky white school top with backpack straps and collar, navy skirt or shorts, long sturdy legs,
# white socks and black school shoes (D-026, D-027).
func _mascot_body(is_ana: bool) -> String:
	var out := ""  # The drawing, back to front.
	out += "<rect x=\"64\" y=\"192\" width=\"172\" height=\"118\" rx=\"34\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\"/>" % [PINK, INK]  # Backpack, peeking out behind the shoulders.
	out += "<rect x=\"106\" y=\"356\" width=\"36\" height=\"108\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [MASCOT_SKIN, INK]  # Left leg.
	out += "<rect x=\"158\" y=\"356\" width=\"36\" height=\"108\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [MASCOT_SKIN, INK]  # Right leg.
	out += "<rect x=\"103\" y=\"440\" width=\"42\" height=\"46\" rx=\"8\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [WHITE, INK]  # Left white sock.
	out += "<rect x=\"155\" y=\"440\" width=\"42\" height=\"46\" rx=\"8\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [WHITE, INK]  # Right white sock.
	out += "<path d=\"M146 476 V500 Q146 512 134 512 H88 Q74 512 76 498 Q78 478 102 476 Z\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\" stroke-linejoin=\"round\"/>" % [SHOE, INK]  # Left black shoe, toe pointing out.
	out += "<path d=\"M154 476 V500 Q154 512 166 512 H212 Q226 512 224 498 Q222 478 198 476 Z\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\" stroke-linejoin=\"round\"/>" % [SHOE, INK]  # Right black shoe, toe pointing out.
	out += "<path d=\"M92 488 Q100 482 110 486 M190 486 Q200 482 208 488\" fill=\"none\" stroke=\"%s\" stroke-width=\"4\" stroke-linecap=\"round\" opacity=\"0.5\"/>" % WHITE  # Shine on the shoes.
	if is_ana:  # Ana: a navy pleated skirt.
		out += "<path d=\"M80 300 H220 L246 380 Q150 396 54 380 Z\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\" stroke-linejoin=\"round\"/>" % [NAVY, INK]  # Skirt.
		out += "<path d=\"M114 306 L100 384 M150 306 V388 M186 306 L200 384\" fill=\"none\" stroke=\"%s\" stroke-width=\"4\" stroke-linecap=\"round\" opacity=\"0.6\"/>" % INK  # Pleats.
	else:  # Migo: navy shorts.
		out += "<path d=\"M82 300 H218 L228 372 H160 L150 336 L140 372 H72 Z\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\" stroke-linejoin=\"round\"/>" % [NAVY, INK]  # Shorts.
	out += "<rect x=\"134\" y=\"164\" width=\"32\" height=\"36\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [MASCOT_SKIN, INK]  # Neck.
	out += "<path d=\"M76 316 V240 Q76 196 118 190 H182 Q224 196 224 240 V316 Z\" fill=\"%s\" stroke=\"%s\" stroke-width=\"8\" stroke-linejoin=\"round\"/>" % [WHITE, INK]  # Chunky white school top.
	out += "<rect x=\"94\" y=\"196\" width=\"22\" height=\"112\" rx=\"10\" fill=\"%s\" stroke=\"%s\" stroke-width=\"5\"/>" % [PINK, INK]  # Left backpack strap.
	out += "<rect x=\"184\" y=\"196\" width=\"22\" height=\"112\" rx=\"10\" fill=\"%s\" stroke=\"%s\" stroke-width=\"5\"/>" % [PINK, INK]  # Right backpack strap.
	out += "<path d=\"M126 190 L150 218 L112 214 Z M174 190 L150 218 L188 214 Z\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\" stroke-linejoin=\"round\"/>" % [WHITE, INK]  # Collar.
	if is_ana:  # Ana: a blue ribbon at the collar.
		out += "<path d=\"M150 222 L124 208 L124 238 Z M150 222 L176 208 L176 238 Z\" fill=\"%s\" stroke=\"%s\" stroke-width=\"5\" stroke-linejoin=\"round\"/>" % [BLUE, INK]  # Bow.
		out += _circle(150, 223, 9, BLUE, 5.0)  # Knot.
	else:  # Migo: a blue school patch on his chest.
		out += "<rect x=\"154\" y=\"240\" width=\"26\" height=\"24\" rx=\"5\" fill=\"%s\" stroke=\"%s\" stroke-width=\"5\"/>" % [BLUE, INK]  # Patch.
	return out  # Hand back the drawing.


# One chunky arm hanging at the side: a short white sleeve, a skin-coloured arm and a five-finger
# hand (D-028). `right` draws the arm on the viewer's right; otherwise the one on the left. `open`
# spreads all five fingers wide for a wave; otherwise they are held loosely together. The game
# turns the arm around its shoulder (see Mascot.SHOULDER_LEFT and SHOULDER_RIGHT) to swing and wave.
func _mascot_arm(right: bool, open: bool) -> String:
	var x := 216.0 if right else 54.0  # Left edge of the arm.
	var middle := x + 15.0  # The middle of the arm, where the hand hangs.
	var inner := -1.0 if right else 1.0  # Which way is towards the body, for the thumb.
	var out := ""  # The drawing, back to front.
	out += "<rect x=\"%.0f\" y=\"234\" width=\"30\" height=\"88\" rx=\"15\" fill=\"%s\" stroke=\"%s\" stroke-width=\"6\"/>" % [x, MASCOT_SKIN, INK]  # Arm.
	out += _mascot_hand_open(middle, inner) if open else _mascot_hand_relaxed(middle, inner)  # The hand.
	out += "<rect x=\"%.0f\" y=\"190\" width=\"46\" height=\"56\" rx=\"20\" fill=\"%s\" stroke=\"%s\" stroke-width=\"7\"/>" % [x - 8.0, WHITE, INK]  # Short white sleeve, over the top of the arm.
	return out  # Hand back the drawing.


# A relaxed hand hanging down at `cx`: four fingers held loosely together and a thumb on the side
# towards the body (`inner` is 1 or -1), drawn before the palm so the palm covers their roots (D-028).
func _mascot_hand_relaxed(cx: float, inner: float) -> String:
	var out := ""  # The drawing, back to front.
	var spots := [-10.5, -3.5, 3.5, 10.5]  # Where each of the four fingers hangs, across the hand.
	var lengths := [12.0, 16.0, 16.0, 13.0]  # How far each finger hangs below the palm.
	for i in range(4):  # Each of the four fingers ...
		var fx: float = cx + spots[i] * inner  # ... from the thumb side to the little finger.
		out += _mascot_finger(Vector2(fx, 330), Vector2(fx, 336.0 + lengths[i]))  # ... hangs straight down.
	out += _mascot_finger(Vector2(cx + 8.0 * inner, 322), Vector2(cx + 17.0 * inner, 334))  # The thumb, on the side towards the body.
	out += "<ellipse cx=\"%.1f\" cy=\"326\" rx=\"17\" ry=\"14\" fill=\"%s\" stroke=\"%s\" stroke-width=\"5\"/>" % [cx, MASCOT_SKIN, INK]  # The palm.
	return out  # Hand back the drawing.


# An open hand at `cx` with all five fingers spread wide, for waving (D-028). The thumb points
# towards the body (`inner` is 1 or -1); the fingers fan out from the palm.
func _mascot_hand_open(cx: float, inner: float) -> String:
	var palm := Vector2(cx, 332)  # The middle of the palm.
	var angles := [72.0, 32.0, 10.0, -12.0, -34.0]  # Each finger's angle from straight down, thumb first (degrees).
	var lengths := [15.0, 20.0, 22.0, 20.0, 16.0]  # How far each finger reaches beyond the palm.
	var out := ""  # The drawing, back to front.
	for i in range(5):  # Each finger, from the thumb to the little finger ...
		var turn := deg_to_rad(angles[i]) * inner  # ... turned towards or away from the body,
		var way := Vector2(sin(turn), cos(turn))  # ... pointing this way from the palm,
		out += _mascot_finger(palm + way * 8.0, palm + way * (14.0 + lengths[i]))  # ... from inside the palm to its tip.
	out += _circle(palm.x, palm.y, 16, MASCOT_SKIN, 5.0)  # The palm, covering the fingers' roots.
	return out  # Hand back the drawing.


# One finger from `start` to `tip`: a round-ended skin line inside a dark outline (D-028).
func _mascot_finger(start: Vector2, tip: Vector2) -> String:
	var line := "<line x1=\"%.1f\" y1=\"%.1f\" x2=\"%.1f\" y2=\"%.1f\" stroke=\"%s\" stroke-width=\"%.1f\" stroke-linecap=\"round\"/>"  # One line with round ends.
	var out := line % [start.x, start.y, tip.x, tip.y, INK, MASCOT_FINGER_INK]  # The dark outline.
	return out + line % [start.x, start.y, tip.x, tip.y, MASCOT_SKIN, MASCOT_FINGER_SKIN]  # The skin inside it.


# The head without its eyes, eyebrows or mouth: hair with a shine, ears, face and rosy cheeks (D-027).
func _mascot_head(is_ana: bool) -> String:
	var skin := MASCOT_SKIN  # Warm brown skin.
	var hair := MASCOT_HAIR  # Dark brown-black hair.
	var out := ""  # The drawing, back to front.
	if is_ana:  # Ana's long hair and two pigtails, behind her head.
		out += _circle(150, 120, 92, hair, 8.0)  # Hair behind the head.
		out += _circle(60, 150, 30, hair, 8.0) + _circle(240, 150, 30, hair, 8.0)  # Two pigtails.
	else:  # Migo's short hair, just above his head.
		out += _circle(150, 112, 85, hair, 8.0)  # Hair behind the head.
	out += _circle(68, 135, 16, skin, 7.0) + _circle(232, 135, 16, skin, 7.0)  # Ears.
	out += _circle(150, 125, 82, skin, 8.0)  # Face.
	if is_ana:  # Ana's fringe and a yellow hair clip.
		out += "<path d=\"M70 112 Q80 44 150 42 Q220 44 230 112 Q204 78 150 82 Q96 78 70 112 Z\" fill=\"%s\"/>" % hair  # Fringe.
		out += "<rect x=\"196\" y=\"70\" width=\"30\" height=\"14\" rx=\"7\" fill=\"%s\" stroke=\"%s\" stroke-width=\"4\" transform=\"rotate(-20 211 77)\"/>" % [YELLOW, INK]  # Clip.
	else:  # Migo's spiky fringe.
		out += "<path d=\"M68 112 Q70 40 150 38 Q230 40 232 112 Q214 88 196 96 Q182 74 164 90 Q150 70 136 90 Q118 74 104 96 Q86 88 68 112 Z\" fill=\"%s\"/>" % hair  # Fringe.
	out += "<path d=\"M96 62 Q114 46 138 42\" fill=\"none\" stroke=\"%s\" stroke-width=\"8\" stroke-linecap=\"round\" opacity=\"0.35\"/>" % WHITE  # Shine on the hair.
	out += "<circle cx=\"100\" cy=\"156\" r=\"13\" fill=\"%s\" opacity=\"0.45\"/><circle cx=\"200\" cy=\"156\" r=\"13\" fill=\"%s\" opacity=\"0.45\"/>" % [PINK, PINK]  # Rosy cheeks.
	return out  # Hand back the drawing.


# The eyes: open with a white shine, or `closed` as two happy curves for a blink (D-027).
func _mascot_eyes(closed: bool) -> String:
	if closed:  # Blinking: two curves.
		return "<path d=\"M110 132 Q120 140 130 132 M170 132 Q180 140 190 132\" fill=\"none\" stroke=\"%s\" stroke-width=\"6\" stroke-linecap=\"round\"/>" % INK  # Closed eyes.
	var out := "<ellipse cx=\"120\" cy=\"130\" rx=\"10\" ry=\"13\" fill=\"%s\"/><ellipse cx=\"180\" cy=\"130\" rx=\"10\" ry=\"13\" fill=\"%s\"/>" % [INK, INK]  # Open eyes.
	out += _circle(123, 125, 3.5, WHITE, 0.0) + _circle(183, 125, 3.5, WHITE, 0.0)  # Shine in the eyes.
	return out  # Hand back the drawing.


# The eyebrows, on their own so the game can lift them while the mascot talks (D-027).
func _mascot_brows() -> String:
	return "<path d=\"M106 108 Q120 100 134 108 M166 108 Q180 100 194 108\" fill=\"none\" stroke=\"%s\" stroke-width=\"5\" stroke-linecap=\"round\"/>" % INK  # Eyebrows.


# The mouth: a big smile, or `open` for talking (D-024).
func _mascot_mouth(is_ana: bool, open: bool) -> String:
	if open and is_ana:  # Ana talking: an open mouth with a tongue.
		var out := "<path d=\"M126 156 Q150 196 174 156 Z\" fill=\"#7A2E3B\" stroke=\"%s\" stroke-width=\"6\" stroke-linejoin=\"round\"/>" % INK  # Open mouth.
		return out + "<path d=\"M138 176 Q150 168 162 176 Q150 188 138 176 Z\" fill=\"%s\"/>" % PINK  # Tongue.
	if open:  # Migo talking: a plain dark open mouth, with no red or pink, so it does not look like lipstick.
		return "<path d=\"M128 156 Q150 190 172 156 Z\" fill=\"#3B2420\" stroke=\"%s\" stroke-width=\"6\" stroke-linejoin=\"round\"/>" % INK  # Open mouth.
	return "<path d=\"M126 158 Q150 182 174 158\" fill=\"none\" stroke=\"%s\" stroke-width=\"7\" stroke-linecap=\"round\"/>" % INK  # Smile.


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
