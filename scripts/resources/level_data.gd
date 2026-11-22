# The 10 items of one Level (D-007, D-010). Stored inside an Episode item bank.
class_name LevelData  # Shows up in the Godot "New Resource" list.
extends Resource  # A data file Godot can save and edit in the Inspector.

@export var number: int = 1  # Level number, 1 to 5.
@export var items: Array[DivisionItem] = []  # The 10 items played in this Level.
@export var label: String = ""  # Short text for the Level card, for example "Mix 1–5"; empty means "work it out from the items".
