# Cuts the PNG sprite sheets in assets/sprites into single frames.
# Each sheet is one row of frames on a fixed grid; the frame size is in the file name,
# for example bubble_yellow_320x320_6f.png = 6 frames of 320 x 320 pixels.
class_name SpriteSheet  # Lets any script write SpriteSheet.bubble("yellow").
extends RefCounted  # Only its static functions are used.

const DIR := "res://assets/sprites/"  # Folder of the PNG sheets.
const MASCOT_WAVE_ORIGIN := Vector2i(279, 270)  # Leave room for the sleeve where it joins the shirt.
const MASCOT_WAVE_SIZE := Vector2i(210, 330)  # Leave room for the extended arm and open hand.
const MASCOT_WAVE_COUNT := 19  # The number of steps from a relaxed elbow to a fully bent elbow.
const MASCOT_CUFF_OUTER := Vector2(239, 229)  # The outside end of the right sleeve hem in the art plan.
const MASCOT_CUFF_INNER := Vector2(208, 235)  # The end of the same hem nearest the shirt.
const MASCOT_FACE_CROP := Rect2(65, 0, 320, 320)  # The square around both heads, pigtails included, in a 450 x 780 frame (D-030).
const MASCOT_FACE_PARTS := [4, 5, 7, 8]  # Head, open eyes, eyebrows and smile: Mascot.Part numbers, written as plain numbers so the art tool can still load this file.

static var _cache: Dictionary = {}  # Sheets already cut, so each is cut only once.


# Returns the frames of one sheet. Called by the helper functions below.
static func frames(file_name: String, frame_size: Vector2i, count: int) -> Array[Texture2D]:
	if _cache.has(file_name):  # Already cut before ...
		return _cache[file_name]  # ... so reuse the frames.
	var sheet: Texture2D = load(DIR + file_name)  # The whole sheet picture.
	var list: Array[Texture2D] = []  # The frames to hand back.
	for i in range(count):  # Each frame, left to right.
		var frame := AtlasTexture.new()  # A window into the sheet.
		frame.atlas = sheet  # Look into this sheet ...
		frame.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)  # ... at frame number i.
		list.append(frame)  # Keep it.
	_cache[file_name] = list  # Remember for next time.
	return list  # Hand back all frames.


# The 6 frames of an answer bubble in one colour: "yellow", "green", "pink" or "red".
static func bubble(colour: String) -> Array[Texture2D]:
	return frames("bubble_%s_320x320_6f.png" % colour, Vector2i(320, 320), 6)  # Resting bubble, then 5 pop frames.


# The 6 frames of the sparkle burst for a correct answer.
static func sparkle() -> Array[Texture2D]:
	return frames("sparkle_160x160_6f.png", Vector2i(160, 160), 6)  # Grow, turn, fade.


# The 6 frames of the Level end Star: empty, filling, full.
static func star() -> Array[Texture2D]:
	return frames("star_200x200_6f.png", Vector2i(200, 200), 6)  # Frame 0 empty, frame 5 full.


# The 14 small icons; use UiKit.Icon to pick one.
static func icons() -> Array[Texture2D]:
	return frames("icons_96x96_15f.png", Vector2i(96, 96), 15)  # Back, Stars, clock, lock, music, sound, vibration, play, help, gear, door (D-017), Trophy, chart (D-023), pencil (D-030).


# The title logo (one frame).
static func logo() -> Texture2D:
	return frames("logo_512x512_1f.png", Vector2i(512, 512), 1)[0]  # The only frame.


# The ten parts of a student mascot from head to toe (D-024, D-026 to D-028): "ana" or "migo".
# Frames follow Mascot.Part: body, two arms, the waving arm, head, eyes open and closed, eyebrows,
# two mouths.
static func mascot(who: String) -> Array[Texture2D]:
	return frames("mascot_%s_450x780_10f.png" % who.to_lower(), Vector2i(450, 780), 10)  # Each part on a whole-mascot frame; file names are lower case, as Android needs.


# Returns a mascot's small face for the Profile (D-030): the head, open eyes, eyebrows and smile,
# each cut to the square around the head, to be stacked in this order.
static func mascot_face(who: String) -> Array[Texture2D]:
	var whole := mascot(who)  # The whole-mascot frames.
	var parts: Array[Texture2D] = []  # The cut face pictures.
	for part: int in MASCOT_FACE_PARTS:  # Back to front ...
		var source := whole[part] as AtlasTexture  # ... the part's frame in the sheet,
		var face := AtlasTexture.new()  # ... a smaller window into the same sheet,
		face.atlas = source.atlas  # ... looking at the same picture,
		face.region = Rect2(source.region.position + MASCOT_FACE_CROP.position, MASCOT_FACE_CROP.size)  # ... only around the head.
		parts.append(face)  # Keep it.
	return parts  # Hand back the four pictures.


# Returns the shared arm frames for a wave, in order from the least to the most bent elbow.
static func mascot_wave() -> Array[Texture2D]:
	var file_name := "mascot_wave_%dx%d_%df.png" % [MASCOT_WAVE_SIZE.x, MASCOT_WAVE_SIZE.y, MASCOT_WAVE_COUNT]  # The sheet name matches the art tool.
	return frames(file_name, MASCOT_WAVE_SIZE, MASCOT_WAVE_COUNT)  # Cut out each bent arm.
