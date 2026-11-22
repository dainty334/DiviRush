# Plays every Level of every Episode on every Difficulty with the real item banks, as an automatic
# run-through: every item offers the right bubbles, a perfect play passes, and passing opens the next Level.
extends GutTest  # GUT gives this script its assert_* checks.

const KINDS := [Difficulty.Kind.EASY, Difficulty.Kind.MEDIUM, Difficulty.Kind.HARD]  # The three Difficulties in unlock order.


# Makes a random number maker with a fixed seed, so the run-through is the same every time.
func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()  # A new random number maker.
	rng.seed = seed_value  # Fix its seed.
	return rng  # Hand it back.


# Every item of every Level shows as many different bubbles as its Difficulty needs, one of them the answer.
func test_every_item_offers_the_right_bubbles() -> void:
	for episode_number in range(1, Progress.EPISODE_COUNT + 1):  # Episodes 1 to 4.
		var episode: EpisodeData = Game.episode_data(episode_number)  # Its item bank.
		for kind: int in KINDS:  # Each Difficulty.
			for level: LevelData in episode.levels:  # Each Level.
				var run := LevelRun.new(level.items, kind, _rng(level.number))  # A play of this Level.
				var where := "E%d %s L%d" % [episode_number, Difficulty.name_of(kind), level.number]  # Names the case.
				while not run.is_finished():  # Each item in turn.
					var choices := run.choices()  # The bubble numbers.
					var answer := run.current_item().correct_answer()  # The right number.
					assert_eq(choices.size(), Difficulty.bubble_count(kind), where)  # 3 bubbles on Easy, 4 on Medium and Hard.
					assert_has(choices, answer, where)  # The answer is one of them.
					var unique := {}  # Each number once.
					for value in choices:  # Each bubble ...
						unique[value] = true  # ... adds its number.
					assert_eq(unique.size(), choices.size(), "%s: a number repeats in %s" % [where, str(choices)])  # No two bubbles alike.
					run.submit_answer(answer, 1.0)  # Tap the answer and go on.


# A perfect play of any Level earns 3 Stars and passes.
func test_perfect_play_passes_every_level() -> void:
	for episode_number in range(1, Progress.EPISODE_COUNT + 1):  # Episodes 1 to 4.
		for kind: int in KINDS:  # Each Difficulty.
			for level: LevelData in Game.episode_data(episode_number).levels:  # Each Level.
				var run := LevelRun.new(level.items, kind, _rng(1))  # A play of this Level.
				while not run.is_finished():  # Each item ...
					run.submit_answer(run.current_item().correct_answer(), 2.0)  # ... answered right.
				assert_eq(run.stars(), 3, "E%d %s L%d" % [episode_number, Difficulty.name_of(kind), level.number])  # 10 of 10 = 3 Stars.
				assert_true(run.passed())  # Passed.


# Passing every Level in order opens every Level of every Episode and Difficulty, one by one (D-008).
func test_passing_in_order_opens_everything() -> void:
	var progress := Progress.new()  # A fresh learner: only Episode 1 Easy Level 1 is open.
	for episode_number in range(1, Progress.EPISODE_COUNT + 1):  # Episodes 1 to 4.
		for kind: int in KINDS:  # Easy, then Medium, then Hard.
			for level in range(1, Progress.LEVEL_COUNT + 1):  # Levels 1 to 5.
				var where := "E%d %s L%d" % [episode_number, Difficulty.name_of(kind), level]  # Names the case.
				assert_true(progress.is_level_open(episode_number, kind, level), where)  # Open by now.
				progress.record(episode_number, kind, level, 3, 200, 50.0)  # Pass it.
