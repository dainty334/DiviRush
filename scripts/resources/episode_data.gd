# One Episode's item bank: its name, its facts and its 5 Levels (D-008).
# The same 5 Levels are played at Easy, Medium and Hard; the Difficulty changes the bubbles and timer.
class_name EpisodeData  # Shows up in the Godot "New Resource" list.
extends Resource  # A data file Godot can save and edit in the Inspector.

@export var number: int = 1  # Episode number, 1 to 4.
@export var title: String = ""  # Name shown on screen, for example "Easy Facts".
@export var facts: String = ""  # The facts it covers, for example "÷1, ÷2, ÷5, ÷10".
@export var levels: Array[LevelData] = []  # The 5 Levels; empty until that Episode is built.


# Returns true when this Episode has playable Levels in its item bank.
func is_built() -> bool:
	return not levels.is_empty()  # An Episode with no Levels yet cannot be played.
