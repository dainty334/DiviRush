# The three Difficulties and what each one changes (D-008).
# A plain class with no scene, so tests can use it directly.
class_name Difficulty  # Lets any script write Difficulty.Kind.EASY.
extends RefCounted  # A light object that frees itself when no longer used.

enum Kind { EASY, MEDIUM, HARD }  # The three Difficulties, in unlock order.

const NAMES := ["Easy", "Medium", "Hard"]  # Names shown on screen, in Kind order.
const KEYS := ["easy", "medium", "hard"]  # Short names used in the save file.
const BUBBLES := [3, 4, 4]  # Answer bubbles per item (D-008).
const SECONDS := [15.0, 10.0, 7.0]  # Timer per item in seconds (D-008, starting values).


# Returns the name shown on screen, for example "Easy". Used by menus and the top bar.
static func name_of(kind: int) -> String:
	return NAMES[kind]  # Look up the name by position.


# Returns the short name used in save keys, for example "easy".
static func key_of(kind: int) -> String:
	return KEYS[kind]  # Look up the key by position.


# Returns how many answer bubbles an item shows at this Difficulty.
static func bubble_count(kind: int) -> int:
	return BUBBLES[kind]  # Easy 3, Medium 4, Hard 4.


# Returns the seconds the learner has for each item at this Difficulty.
static func time_limit(kind: int) -> float:
	return SECONDS[kind]  # Easy 15 s, Medium 10 s, Hard 7 s.
