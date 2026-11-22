# Builds the Episode item banks as .tres files, so Godot itself writes them.
# Run from the project folder with:
#   godot --headless --script res://tools/build_item_banks.gd
# Episodes 1 and 2 get their 5 Levels (D-010, D-011). Episodes 3 and 4 get only their name
# and facts for now, because their Level contents are built in a later slice.
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const OUT_DIR := "res://resources/episodes/"  # Where the item banks are saved.
const SEED := 2026  # Fixed seed, so running the tool again gives the same items.
const LEVEL_5_MIX := {1: 2, 2: 3, 5: 3, 10: 2}  # Episode 1 Level 5 review: divisor -> how many facts (D-010).
const EPISODE_2_MIX := {3: 5, 4: 5}  # Episode 2 Level 5 review: 5 ÷3 and 5 ÷4 facts (D-011).

var rng := RandomNumberGenerator.new()  # Random number maker for Easy wrong answers and the Level 5 mix.
var near_rng := RandomNumberGenerator.new()  # A second maker for Medium and Hard, so adding them left Easy unchanged.


# Runs once when the tool starts: builds and saves all four Episodes, then quits.
func _init() -> void:
	_save(_episode_one())  # Episode 1 with its Levels.
	_save(_episode_two())  # Episode 2 with its Levels.
	_save(_episode_stub(3, "Hard Facts", "÷6, ÷7, ÷8, ÷9"))  # Episode 3: name only for now.
	_save(_episode_stub(4, "Fact Families", "÷1 to ÷10, missing numbers"))  # Episode 4: name only for now.
	quit()  # Close the tool when done.


# Builds Episode 1: Levels 1-4 use ÷1, ÷2, ÷5, ÷10 with quotients 1-10; Level 5 mixes them.
func _episode_one() -> EpisodeData:
	rng.seed = SEED  # Episode 1's own seeds, so building other Episodes never changes it.
	near_rng.seed = SEED + 1  # Its own fixed seed for Medium and Hard.
	var episode := _episode_stub(1, "Easy Facts", "÷1, ÷2, ÷5, ÷10")  # Name and facts.
	var divisors := [1, 2, 5, 10]  # One divisor per Level 1-4.
	for i in range(divisors.size()):  # Levels 1 to 4.
		episode.levels.append(_table_level(i + 1, [divisors[i]], range(1, 11)))  # Every fact for this divisor, 1 to 10.
	episode.levels.append(_mixed_level(5, LEVEL_5_MIX))  # Level 5: mixed review.
	return episode  # Hand back the finished Episode.


# Builds Episode 2 (D-011): Level 1 = ÷3, Level 2 = ÷4, Level 3 = both with answers 1-5,
# Level 4 = both with answers 6-10, Level 5 = mixed review of 5 ÷3 and 5 ÷4 facts.
func _episode_two() -> EpisodeData:
	rng.seed = SEED + 2  # Episode 2's own seeds, so it never changes Episode 1.
	near_rng.seed = SEED + 3  # Its own fixed seed for Medium and Hard.
	var episode := _episode_stub(2, "Middle Facts", "÷3, ÷4")  # Name and facts.
	episode.levels.append(_table_level(1, [3], range(1, 11)))  # Level 1: ÷3, answers 1-10.
	episode.levels.append(_table_level(2, [4], range(1, 11)))  # Level 2: ÷4, answers 1-10.
	var low := _table_level(3, [3, 4], range(1, 6))  # Level 3: both tables, answers 1-5.
	low.label = "Mix 1–5"  # Card label, so it is not confused with Levels 4 and 5.
	episode.levels.append(low)  # Add it.
	var high := _table_level(4, [3, 4], range(6, 11))  # Level 4: both tables, answers 6-10.
	high.label = "Mix 6–10"  # Card label.
	episode.levels.append(high)  # Add it.
	episode.levels.append(_mixed_level(5, EPISODE_2_MIX))  # Level 5: mixed review.
	return episode  # Hand back the finished Episode.


# Builds a Level with every fact of the given divisors and quotients, divisor by divisor.
func _table_level(number: int, divisors: Array, quotients: Array) -> LevelData:
	var level := LevelData.new()  # A new Level.
	level.number = number  # Level number.
	for divisor: int in divisors:  # Each divisor ...
		for quotient: int in quotients:  # ... with each quotient ...
			level.items.append(_make_item(divisor, quotient))  # ... is one item.
	return level  # Hand back the Level.


# Builds a mixed review Level: a few facts from each divisor, with no fact repeated.
# `mix` maps each divisor to how many of its facts to pick, for example {3: 5, 4: 5}.
func _mixed_level(number: int, mix: Dictionary) -> LevelData:
	var level := LevelData.new()  # A new Level.
	level.number = number  # Level number.
	for divisor in mix:  # Each divisor in the mix.
		var quotients := range(1, 11)  # Quotients 1 to 10 to pick from.
		for n in range(mix[divisor]):  # Pick this many facts.
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
