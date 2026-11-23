# Cuts the PNG sprite sheets in assets/sprites into single frames.
# Each sheet is one row of frames on a fixed grid; the frame size is in the file name,
# for example bubble_yellow_320x320_6f.png = 6 frames of 320 x 320 pixels.
class_name SpriteSheet  # Lets any script write SpriteSheet.bubble("yellow").
extends RefCounted  # Only its static functions are used.

const DIR := "res://assets/sprites/"  # Folder of the PNG sheets.

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
	return frames("icons_96x96_14f.png", Vector2i(96, 96), 14)  # Back, Stars, clock, lock, music, sound, vibration, play, help, gear, door (D-017), Trophy, chart (D-023).


# The title logo (one frame).
static func logo() -> Texture2D:
	return frames("logo_512x512_1f.png", Vector2i(512, 512), 1)[0]  # The only frame.


# The five parts of a student mascot from head to toe (D-024, D-026): "ana" or "migo".
# Frames follow Mascot.Part: body, left arm, right arm, head smiling, head talking.
static func mascot(who: String) -> Array[Texture2D]:
	return frames("mascot_%s_300x520_5f.png" % who, Vector2i(300, 520), 5)  # Each part on a whole-mascot frame.
