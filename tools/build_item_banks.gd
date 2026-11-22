# Builds the Episode item banks as .tres files, so Godot itself writes them.
# Run from the project folder with:
#   godot --headless --script res://tools/build_item_banks.gd
# Every Episode gets its 5 Levels (D-010, D-011, D-012, D-013).
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const OUT_DIR := "res://resources/episodes/"  # Where the item banks are saved.
const SEED := 2026  # Fixed seed, so running the tool again gives the same items.
const LEVEL_5_MIX := {1: 2, 2: 3, 5: 3, 10: 2}  # Episode 1 Level 5 review: divisor -> how many facts (D-010).
const EPISODE_2_MIX := {3: 5, 4: 5}  # Episode 2 Level 5 review: 5 ÷3 and 5 ÷4 facts (D-011).
const EPISODE_3_MIX := {6: 2, 7: 3, 8: 3, 9: 2}  # Episode 3 Level 5 review: more ÷7 and ÷8, the hardest tables (D-012).
const Q := DivisionItem.Hidden.QUOTIENT  # Short name: 56 ÷ 8 = ?.
const D := DivisionItem.Hidden.DIVISOR  # Short name: 56 ÷ ☐ = 7.
const N := DivisionItem.Hidden.DIVIDEND  # Short name: ☐ ÷ 8 = 7.
const EPISODE_4_KINDS := [{Q: 10}, {D: 10}, {N: 10}, {D: 5, N: 5}, {Q: 2, D: 4, N: 4}]  # Hidden numbers in Episode 4 Levels 1-5 (D-013).
const EPISODE_4_LABELS := ["÷ ?", "÷ ☐", "☐ ÷", "Mix ☐", "Mix"]  # Episode 4 Level card labels (D-013 working values).

var rng := RandomNumberGenerator.new()  # Random number maker for Easy wrong answers and the Level 5 mix.
var near_rng := RandomNumberGenerator.new()  # A second maker for Medium and Hard, so adding them left Easy unchanged.


# Runs once when the tool starts: builds and saves all four Episodes, then quits.
func _init() -> void:
	_save(_episode_one())  # Episode 1 with its Levels.
	_save(_episode_two())  # Episode 2 with its Levels.
	_save(_episode_three())  # Episode 3 with its Levels.
	_save(_episode_four())  # Episode 4 with its Levels.
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


# Builds Episode 3 (D-012): Levels 1-4 use ÷6, ÷7, ÷8, ÷9 in counting order with quotients 1-10;
# Level 5 is a mixed review of 2 ÷6, 3 ÷7, 3 ÷8 and 2 ÷9 facts.
func _episode_three() -> EpisodeData:
	rng.seed = SEED + 4  # Episode 3's own seeds, so it never changes Episodes 1 and 2.
	near_rng.seed = SEED + 5  # Its own fixed seed for Medium and Hard.
	var episode := _episode_stub(3, "Hard Facts", "÷6, ÷7, ÷8, ÷9")  # Name and facts.
	var divisors := [6, 7, 8, 9]  # One divisor per Level 1-4.
	for i in range(divisors.size()):  # Levels 1 to 4.
		episode.levels.append(_table_level(i + 1, [divisors[i]], range(1, 11)))  # Every fact for this divisor, 1 to 10.
	episode.levels.append(_mixed_level(5, EPISODE_3_MIX))  # Level 5: mixed review.
	return episode  # Hand back the finished Episode.


# Builds Episode 4 (D-013): every Level has one fact from each table ÷1-÷10, no fact is used twice
# in the Episode, and each Level hides the numbers set in EPISODE_4_KINDS (L1 quotient, L2 divisor,
# L3 dividend, L4 divisor and dividend, L5 all three).
func _episode_four() -> EpisodeData:
	rng.seed = SEED + 6  # Episode 4's own seeds, so it never changes Episodes 1-3.
	near_rng.seed = SEED + 7  # Its own fixed seed for Medium and Hard.
	var episode := _episode_stub(4, "Fact Families", "÷1 to ÷10, missing numbers")  # Name and facts.
	var quotients_of := {}  # For each divisor: its quotients 1-10 in a random order.
	for divisor in range(1, 11):  # Every table ÷1 to ÷10.
		var quotients := range(1, 11)  # Quotients 1 to 10.
		_shuffle(quotients)  # Random order, so Level n takes the n-th one and no fact repeats.
		quotients_of[divisor] = quotients  # Keep the order for this table.
	for i in range(EPISODE_4_KINDS.size()):  # Levels 1 to 5.
		var kinds := _kinds_list(EPISODE_4_KINDS[i])  # The hidden kind for each of the 10 items.
		var level := LevelData.new()  # A new Level.
		level.number = i + 1  # Level number.
		level.label = EPISODE_4_LABELS[i]  # Its card label, since every Level mixes all ten tables.
		for divisor in range(1, 11):  # One fact from each table.
			level.items.append(_make_item(divisor, quotients_of[divisor][i], kinds[divisor - 1]))  # The Level's own quotient for this table.
		episode.levels.append(level)  # Add the Level.
	return episode  # Hand back the finished Episode.


# Turns a mix such as {D: 5, N: 5} into a shuffled list of 10 hidden kinds, one per item.
func _kinds_list(mix: Dictionary) -> Array:
	var kinds := []  # The list to fill.
	for kind in mix:  # Each hidden kind ...
		for n in range(mix[kind]):  # ... as many times as the mix says.
			kinds.append(kind)  # Add it.
	_shuffle(kinds)  # Random order, so a hidden kind is not tied to the same tables.
	return kinds  # Hand back the list.


# Shuffles a list in place with the tool's fixed-seed random maker, so rebuilding gives the same order.
# Array.shuffle() is not used because it ignores the seed.
func _shuffle(list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):  # From the last spot down to the second.
		var j := rng.randi_range(0, i)  # A random spot at or before it.
		var keep: Variant = list[i]  # Remember this spot's value.
		list[i] = list[j]  # Swap the two values ...
		list[j] = keep  # ... over.


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
# `hidden` says which number the learner must find; Episodes 1-3 always hide the quotient.
func _make_item(divisor: int, quotient: int, hidden: int = Q) -> DivisionItem:
	var item := DivisionItem.new()  # A new item.
	item.divisor = divisor  # The number it divides by.
	item.quotient = quotient  # The result.
	item.dividend = divisor * quotient  # Always divides evenly and stays 100 or less (D-007).
	item.hidden = hidden  # Which number is shown as ? or ☐.
	match hidden:  # Pick the wrong-answer rules for the hidden number.
		D:  # 56 ÷ ☐ = 7: the D-011 rules around the divisor; the quotient is the fact family answer (D-013).
			item.wrong_easy = WrongAnswers.far(divisor, 2, rng)  # 2 far wrong answers.
			item.wrong_medium = WrongAnswers.near(divisor, 3, near_rng)  # 3 near wrong answers.
			item.wrong_hard = WrongAnswers.look_alike(divisor, quotient, 3, near_rng)  # 3 look-alike answers, the quotient first.
		N:  # ☐ ÷ 8 = 7: multiples of the divisor up to 100 (D-013).
			item.wrong_easy = WrongAnswers.far_multiples(divisor, quotient, 2, rng)  # 2 far multiples.
			item.wrong_medium = WrongAnswers.near_multiples(divisor, quotient, 3, near_rng)  # 3 nearest multiples.
			item.wrong_hard = WrongAnswers.neighbour_facts(divisor, quotient, 3, near_rng)  # 3 neighbouring facts.
		_:  # 56 ÷ 8 = ?: the quotient is hidden.
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
