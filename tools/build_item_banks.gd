# Builds the Episode item banks as .tres files, so Godot itself writes them.
# Run from the project folder with:
#   godot --headless --script res://tools/build_item_banks.gd
# Episode 1 gets its 5 Levels (D-010). Episodes 2-4 get only their name and facts for now,
# because their Level contents are built in a later slice.
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const OUT_DIR := "res://resources/episodes/"  # Where the item banks are saved.
const SEED := 2026  # Fixed seed, so running the tool again gives the same items.
const LEVEL_5_MIX := {1: 2, 2: 3, 5: 3, 10: 2}  # Level 5 review: divisor -> how many facts (D-010).

var rng := RandomNumberGenerator.new()  # Random number maker for Easy wrong answers and the Level 5 mix.
var near_rng := RandomNumberGenerator.new()  # A second maker for Medium and Hard, so adding them left Easy unchanged.


# Runs once when the tool starts: builds and saves all four Episodes, then quits.
func _init() -> void:
	rng.seed = SEED  # Same seed every run.
	near_rng.seed = SEED + 1  # Its own fixed seed, so Medium and Hard also repeat exactly.
	_save(_episode_one())  # Episode 1 with its Levels.
	_save(_episode_stub(2, "Middle Facts", "÷3, ÷4"))  # Episode 2: name only for now.
	_save(_episode_stub(3, "Hard Facts", "÷6, ÷7, ÷8, ÷9"))  # Episode 3: name only for now.
	_save(_episode_stub(4, "Fact Families", "÷1 to ÷10, missing numbers"))  # Episode 4: name only for now.
	quit()  # Close the tool when done.


# Builds Episode 1: Levels 1-4 use ÷1, ÷2, ÷5, ÷10 with quotients 1-10; Level 5 mixes them.
func _episode_one() -> EpisodeData:
	var episode := _episode_stub(1, "Easy Facts", "÷1, ÷2, ÷5, ÷10")  # Name and facts.
	var divisors := [1, 2, 5, 10]  # One divisor per Level 1-4.
	for i in range(divisors.size()):  # Levels 1 to 4.
		var level := LevelData.new()  # A new Level.
		level.number = i + 1  # Level number.
		for quotient in range(1, 11):  # Every fact for this divisor, 1 to 10.
			level.items.append(_make_item(divisors[i], quotient))  # Add the item.
		episode.levels.append(level)  # Add the Level to the Episode.
	episode.levels.append(_mixed_level(5))  # Level 5: mixed review.
	return episode  # Hand back the finished Episode.


# Builds a mixed review Level: a few facts from each divisor, with no fact repeated.
func _mixed_level(number: int) -> LevelData:
	var level := LevelData.new()  # A new Level.
	level.number = number  # Level number.
	for divisor in LEVEL_5_MIX:  # Each divisor in the mix.
		var quotients := range(1, 11)  # Quotients 1 to 10 to pick from.
		for n in range(LEVEL_5_MIX[divisor]):  # Pick this many facts.
			var pick := rng.randi_range(0, quotients.size() - 1)  # A random spot.
			level.items.append(_make_item(divisor, quotients[pick]))  # Add that fact.
			quotients.remove_at(pick)  # Do not pick it again.
	return level  # Hand back the Level.


# Makes one item: dividend = divisor x quotient, plus its wrong answers for every Difficulty.
func _make_item(divisor: int, quotient: int) -> DivisionItem:
	var item := DivisionItem.new()  # A new item.
	item.divisor = divisor  # The number it divides by.
	item.quotient = quotient  # The answer.
	item.dividend = divisor * quotient  # Always divides evenly and stays 100 or less (D-007).
	item.wrong_easy = WrongAnswers.far(quotient, 2, rng)  # 2 far wrong answers for 3 Easy bubbles.
	item.wrong_medium = WrongAnswers.near(quotient, 3, near_rng)  # 3 near wrong answers for 4 Medium bubbles (D-011).
	item.wrong_hard = WrongAnswers.look_alike(quotient, divisor, 3, near_rng)  # 3 look-alike answers for 4 Hard bubbles; the divisor is the fact family answer (D-011).
	return item  # Hand back the item.


# Makes an Episode with its number, name and facts, and no Levels yet.
func _episode_stub(number: int, title: String, facts: String) -> EpisodeData:
	var episode := EpisodeData.new()  # A new Episode.
	episode.number = number  # Episode number.
	episode.title = title  # Name shown on screen.
	episode.facts = facts  # Facts it covers.
	return episode  # Hand it back.


# Saves one Episode as res://resources/episodes/episode_N.tres and reports the result.
func _save(episode: EpisodeData) -> void:
	var path := OUT_DIR + "episode_%d.tres" % episode.number  # File name for this Episode.
	var error := ResourceSaver.save(episode, path)  # Godot writes the file.
	if error != OK:  # Saving failed ...
		push_error("Could not save %s (error %d)" % [path, error])  # ... so say so.
	else:  # Saving worked ...
		print("saved ", path)  # ... so report it.
