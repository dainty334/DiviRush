# The twelve Trophies and their goals (D-023): rewards for progress, accuracy and practice, never
# for speed, like the Stars. A Trophy is earned once and kept. A plain class with no scene, so tests
# can check every goal.
class_name Trophies  # Lets the Save autoload, the screens and tests write Trophies.award(...).
extends RefCounted  # Only its constants and static functions are used.

const ALL := [  # Every Trophy, in the order the Trophies screen shows them: id, name and goal.
	{"id": "first_star", "name": "First Star", "goal": "Earn your first Star"},  # The first Star.
	{"id": "perfect_10", "name": "Perfect 10", "goal": "Get 10 of 10 in a Level"},  # Three Stars once.
	{"id": "on_a_roll", "name": "On a Roll", "goal": "Get 5 right in a row"},  # A streak of 5.
	{"id": "easy_facts", "name": "Easy Facts", "goal": "Pass Episode 1 Easy Level 5"},  # Episode 1 Easy done.
	{"id": "middle_facts", "name": "Middle Facts", "goal": "Pass Episode 2 Easy Level 5"},  # Episode 2 Easy done.
	{"id": "hard_facts", "name": "Hard Facts", "goal": "Pass Episode 3 Easy Level 5"},  # Episode 3 Easy done.
	{"id": "fact_families", "name": "Fact Families", "goal": "Pass Episode 4 Easy Level 5"},  # Episode 4 Easy done.
	{"id": "medium_ready", "name": "Medium Ready", "goal": "Pass a Medium Level"},  # Any Medium pass.
	{"id": "hard_hero", "name": "Hard Hero", "goal": "Pass a Hard Level"},  # Any Hard pass.
	{"id": "star_collector", "name": "Star Collector", "goal": "Earn 50 Stars"},  # 50 Stars.
	{"id": "practice_pro", "name": "Practice Pro", "goal": "Play 25 Levels"},  # 25 plays.
	{"id": "division_champion", "name": "Division Champion", "goal": "Earn all 180 Stars"},  # Every Star.
]  # End of the list.
const STREAK_GOAL := 5  # "On a Roll": 5 correct in a row.
const STAR_GOAL := 50  # "Star Collector": 50 Stars.
const PLAY_GOAL := 25  # "Practice Pro": 25 Levels played.


# Gives every Trophy whose goal is now met and that was not earned before. Returns the ids of the
# new ones, so the Level end screen can show them. Called after each play and when the game starts.
static func award(progress: Progress, records: Records) -> Array[String]:
	var new_ones: Array[String] = []  # Trophies earned just now.
	for trophy: Dictionary in ALL:  # Each Trophy, in order ...
		var id: String = trophy.id  # ... its id,
		if not records.has_trophy(id) and is_goal_met(id, progress, records):  # ... not earned yet, but its goal is met ...
			records.trophies.append(id)  # ... is kept,
			new_ones.append(id)  # ... and reported as new.
	return new_ones  # Hand back the new Trophies.


# Returns true when a Trophy's goal is met by the bests and records.
static func is_goal_met(id: String, progress: Progress, records: Records) -> bool:
	match id:  # Each Trophy has its own goal.
		"first_star":  # At least one Star.
			return progress.total_stars() >= 1  # Any Star counts.
		"perfect_10":  # 10 of 10 in some Level.
			return _any_level(progress, func(best: Dictionary) -> bool: return best.stars >= 3)  # Three Stars = 10 of 10.
		"on_a_roll":  # A streak of 5.
			return records.best_streak >= STREAK_GOAL  # The longest streak so far.
		"easy_facts":  # Episode 1 Easy Level 5.
			return progress.is_passed(1, Difficulty.Kind.EASY, Progress.LEVEL_COUNT)  # Passed.
		"middle_facts":  # Episode 2 Easy Level 5.
			return progress.is_passed(2, Difficulty.Kind.EASY, Progress.LEVEL_COUNT)  # Passed.
		"hard_facts":  # Episode 3 Easy Level 5.
			return progress.is_passed(3, Difficulty.Kind.EASY, Progress.LEVEL_COUNT)  # Passed.
		"fact_families":  # Episode 4 Easy Level 5.
			return progress.is_passed(4, Difficulty.Kind.EASY, Progress.LEVEL_COUNT)  # Passed.
		"medium_ready":  # Any Medium Level.
			return _any_passed_in(progress, Difficulty.Kind.MEDIUM)  # One pass is enough.
		"hard_hero":  # Any Hard Level.
			return _any_passed_in(progress, Difficulty.Kind.HARD)  # One pass is enough.
		"star_collector":  # 50 Stars.
			return progress.total_stars() >= STAR_GOAL  # Stars over all Levels.
		"practice_pro":  # 25 Levels played.
			return records.levels_played >= PLAY_GOAL  # Plays, passed or not.
		"division_champion":  # Every Star.
			return progress.total_stars() >= Progress.MAX_STARS  # All 180.
	return false  # An unknown id is never earned.


# Returns a Trophy's name from its id, for the Level end banner.
static func name_of(id: String) -> String:
	for trophy: Dictionary in ALL:  # Look through the list ...
		if trophy.id == id:  # ... for this id,
			return trophy.name  # ... and hand back its name.
	return id  # Not found: show the id itself.


# Returns true when any one Level of a Difficulty, in any Episode, has been passed.
static func _any_passed_in(progress: Progress, difficulty: int) -> bool:
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		for level in range(1, Progress.LEVEL_COUNT + 1):  # ... each Level ...
			if progress.is_passed(episode, difficulty, level):  # ... passed?
				return true  # One is enough.
	return false  # None passed.


# Returns true when the test is true for the bests of any one Level in the game.
static func _any_level(progress: Progress, test: Callable) -> bool:
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		for difficulty: int in Difficulty.Kind.values():  # ... each Difficulty ...
			for level in range(1, Progress.LEVEL_COUNT + 1):  # ... each Level ...
				if test.call(progress.best(episode, difficulty, level)):  # ... does it pass the test?
					return true  # One is enough.
	return false  # None did.
