# Each Level's best results, and which Episodes, Difficulties and Levels are open (D-008, D-010).
# Openness is worked out from the best Stars, so the save file only needs the bests.
class_name Progress  # Lets the menus, Level end screen and tests use Progress.
extends RefCounted  # A light object that frees itself when no longer used.

const EPISODE_COUNT := 4  # DiviRush has four Episodes (D-008).
const LEVEL_COUNT := 5  # Each Difficulty has five Levels (D-008).
const NO_TIME := -1.0  # Means "no best time yet".

var bests: Dictionary = {}  # Level key -> { stars, score, time }.


# Returns the save key for one Level, for example "e1_easy_l3".
static func level_key(episode: int, difficulty: int, level: int) -> String:
	return "e%d_%s_l%d" % [episode, Difficulty.key_of(difficulty), level]  # Episode, Difficulty, Level.


# Returns a Level's bests. A Level never played gives 0 Stars, 0 points and no time.
func best(episode: int, difficulty: int, level: int) -> Dictionary:
	var empty := {"stars": 0, "score": 0, "time": NO_TIME}  # Values for a Level never played.
	var stored: Dictionary = bests.get(level_key(episode, difficulty, level), empty)  # The saved bests, or the empty ones.
	return stored.duplicate()  # A copy, so a caller cannot change the saved bests by mistake.


# Returns true when the Level has been passed at least once.
func is_passed(episode: int, difficulty: int, level: int) -> bool:
	return best(episode, difficulty, level).stars >= 1  # Passed means at least one Star.


# Returns the best Stars added up over the 5 Levels of one Difficulty (0 to 15).
# Shown on the Episode and Difficulty select cards.
func stars_in(episode: int, difficulty: int) -> int:
	var total := 0  # Running total.
	for level in range(1, LEVEL_COUNT + 1):  # Levels 1 to 5 ...
		total += best(episode, difficulty, level).stars  # ... add each Level's best Stars.
	return total  # Hand back the total.


# Returns true when an Episode can be chosen: its Easy is open.
func is_episode_open(episode: int) -> bool:
	return is_difficulty_open(episode, Difficulty.Kind.EASY)  # An Episode opens with its Easy.


# Returns true when a Difficulty inside an Episode is open (D-008 unlock rules).
func is_difficulty_open(episode: int, difficulty: int) -> bool:
	if episode < 1 or episode > EPISODE_COUNT:  # No such Episode ...
		return false  # ... is never open.
	match difficulty:  # Each Difficulty has its own rule.
		Difficulty.Kind.EASY:  # Easy opens ...
			return episode == 1 or is_passed(episode - 1, Difficulty.Kind.EASY, LEVEL_COUNT)  # ... at the start, or after the last Episode's Easy Level 5.
		Difficulty.Kind.MEDIUM:  # Medium opens ...
			return is_passed(episode, Difficulty.Kind.EASY, LEVEL_COUNT)  # ... after this Episode's Easy Level 5.
		Difficulty.Kind.HARD:  # Hard opens ...
			return is_passed(episode, Difficulty.Kind.MEDIUM, LEVEL_COUNT)  # ... after this Episode's Medium Level 5.
	return false  # Any other value is not a Difficulty.


# Returns true when a Level can be played (D-008).
func is_level_open(episode: int, difficulty: int, level: int) -> bool:
	if level < 1 or level > LEVEL_COUNT:  # No such Level ...
		return false  # ... is never open.
	if not is_difficulty_open(episode, difficulty):  # A locked Difficulty ...
		return false  # ... keeps all its Levels locked.
	return level == 1 or is_passed(episode, difficulty, level - 1)  # Level 1 is open; others need the one before passed.


# Saves one finished play's results if they beat the bests. Called at Level end.
# Returns { new_stars, new_score, new_time } so the screen can show "New best!".
func record(episode: int, difficulty: int, level: int, stars: int, score: int, time: float) -> Dictionary:
	var old := best(episode, difficulty, level)  # The bests before this play.
	var new_stars: bool = stars > old.stars  # More Stars than before?
	var new_score: bool = score > old.score  # More points than before?
	var new_time: bool = stars >= 1 and (old.time == NO_TIME or time < old.time)  # A faster passed play (D-010)?
	bests[level_key(episode, difficulty, level)] = {  # Store the combined bests.
		"stars": stars if new_stars else old.stars,  # Keep the higher Stars.
		"score": score if new_score else old.score,  # Keep the higher score.
		"time": time if new_time else old.time,  # Keep the shorter passed time.
	}  # End of the list.
	return {"new_stars": new_stars, "new_score": new_score, "new_time": new_time}  # Which bests are new.
