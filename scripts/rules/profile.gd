# The learner's Profile (D-030): a Nickname and a Buddy, kept only in the save file on the learner's
# own phone. It is not an account: there is no password and nothing is sent online.
class_name Profile  # Lets the Save autoload, the screens and tests use Profile.
extends RefCounted  # A light object that frees itself when no longer used.

const MAX_LENGTH := 12  # The longest Nickname, so it fits the Profile pill on the Main menu.
const BUDDIES: Array[String] = ["Ana", "Migo", "Both"]  # The Buddy choices, in the order the picker shows them.
const BOTH := "Both"  # The Buddy that lets Ana and Migo take turns, as before D-030.

static var _not_allowed: RegEx  # Finds every sign that is not a letter, a number or a space; made once.

var nickname := ""  # The Nickname; empty until the Welcome screen is filled in.
var buddy := BOTH  # Which mascot shows on the Main menu: "Ana", "Migo" or "Both".
var featured := ""  # The id of the Featured Trophy the learner shows, or "" for None (D-031).


# Returns the text with every sign that is not a letter, a number or a space taken out, cut to
# 12 characters. Letters from any language count, so "Niño" and "José" stay as typed.
static func clean(text: String) -> String:
	if _not_allowed == null:  # Not made yet ...
		_not_allowed = RegEx.create_from_string("[^\\p{L}\\p{N} ]")  # ... any character that is not a letter, number or space.
	return _not_allowed.sub(text, "", true).left(MAX_LENGTH)  # Drop those signs, then keep the first 12 characters.


# Returns true when the text can be a Nickname: 1 to 12 allowed characters, not only spaces.
static func is_valid(text: String) -> bool:
	return clean(text) == text and text.strip_edges() != ""  # Nothing dropped or cut, and not empty.


# Returns true once the learner has given a Nickname, so the Welcome screen is not shown again.
func has_nickname() -> bool:
	return nickname != ""  # Any saved Nickname counts.


# Returns the mascots the Main menu shows, in turn order: one for Ana or Migo, both for "Both".
func mascots() -> Array[String]:
	return mascots_for(buddy)  # This Profile's Buddy.


# Returns the mascots of any Buddy choice: ["Ana"], ["Migo"], or ["Ana", "Migo"] for "Both".
static func mascots_for(choice: String) -> Array[String]:
	if choice == BOTH:  # Both chosen ...
		var both: Array[String] = []  # ... a list of the two names,
		both.assign(MascotLines.NAMES)  # ... Ana then Migo, as they took turns before (D-024).
		return both  # Hand back both.
	return [choice] as Array[String]  # Only the chosen one.
