# Tests for the screen backgrounds (D-020): the Main menu area, the selection screens and each
# Episode's world have their own sky and floating shapes, so the screens do not all look the same.
extends GutTest  # GUT gives this script its assert_* checks.

const SCREEN := "res://scenes/screens/%s.tscn"  # Screen scene paths.
const Look := SkyBackground.Look  # Short name for the looks.


# Opens a screen and returns the look of its background.
func _look_of(screen_name: String) -> int:
	var screen: Node = load(SCREEN % screen_name).instantiate()  # A new screen.
	add_child_autofree(screen)  # In the tree (this builds it), freed after the test.
	return screen.background.look  # Its background's look.


# The Main menu area keeps the blue bubble sky, and the selection screens have their own look.
func test_area_looks() -> void:
	for screen_name: String in ["start_screen", "how_to_play", "settings_screen", "trophies_screen", "records_screen"]:  # Main menu area ...
		assert_eq(_look_of(screen_name), Look.MENU, screen_name)  # ... blue sky with bubbles.
	assert_eq(_look_of("main_menu"), Look.CANDY)  # The Main menu has its own candy sky (D-022).
	Game.episode = 1  # Difficulty select needs an Episode.
	for screen_name: String in ["episode_select", "difficulty_select"]:  # Selection screens ...
		assert_eq(_look_of(screen_name), Look.SELECT, screen_name)  # ... teal sky with stars and ÷ signs.


# Each Episode's Level select, Play and Level end screens show that Episode's world.
func test_episode_worlds() -> void:
	var worlds := [Look.DAY, Look.MEADOW, Look.SUNSET, Look.NIGHT]  # Episodes 1 to 4.
	Game.last_result = {"correct": 9, "total": 10, "stars": 2, "score": 200, "time": 50.0, "passed": true, "new_best": false}  # For Level end.
	for episode in range(1, 5):  # Each Episode ...
		Game.episode = episode  # ... chosen,
		Game.difficulty = Difficulty.Kind.EASY  # ... on Easy,
		Game.level = 1  # ... Level 1.
		for screen_name: String in ["level_select", "play_screen", "level_end"]:  # Its three screens ...
			assert_eq(_look_of(screen_name), worlds[episode - 1], "%s, Episode %d" % [screen_name, episode])  # ... show its world.


# No two looks share their sky colours, and each look has its own floating shapes.
func test_every_look_is_different() -> void:
	var skies := {}  # Sky colours seen so far.
	var shapes := {}  # Shape lists seen so far.
	for look: int in SkyBackground.LOOKS:  # Each look ...
		var setup: Dictionary = SkyBackground.LOOKS[look]  # ... its settings,
		skies[[setup.top, setup.bottom]] = true  # ... adds its sky colours,
		shapes[str(setup.shapes)] = true  # ... and its shapes.
	assert_eq(skies.size(), SkyBackground.LOOKS.size())  # Seven looks, seven skies.
	assert_eq(shapes.size(), SkyBackground.LOOKS.size() - 1)  # Seven looks, six shape sets: the day sky has bubbles like the Start-up menu, under a sun.


# Bubbles float up and leaves fall down, as they would in real life.
func test_bubbles_rise_and_leaves_fall() -> void:
	var sky := SkyBackground.new(Look.MENU)  # A bubble sky.
	add_child_autofree(sky)  # In the tree, so it makes its shapes.
	var meadow := SkyBackground.new(Look.MEADOW)  # A meadow with leaves.
	add_child_autofree(meadow)  # In the tree.
	var bubble_y: float = sky._shapes[0].y  # Where the first bubble is.
	var leaf_y: float = meadow._shapes[0].y  # Where the first leaf is.
	sky._process(0.1)  # A tenth of a second passes.
	meadow._process(0.1)  # The same for the meadow.
	assert_lt(sky._shapes[0].y, bubble_y)  # The bubble went up.
	assert_gt(meadow._shapes[0].y, leaf_y)  # The leaf came down.
