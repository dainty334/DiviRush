# What the student mascots, Ana and Migo, say on the Main menu (D-024): a greeting with their
# name, hints from the learner's own progress (Stars, the next Level to try, the next Trophy to aim
# for), and simple division tips. A plain class with no scene, so tests can check every line.
class_name MascotLines  # Lets the Main menu, the Mascot and tests use MascotLines.
extends RefCounted  # Only its constants and static functions are used.

const NAMES := ["Ana", "Migo"]  # The two mascots, who take turns: a girl and a boy (D-024).
const TIPS := [  # Short division tips, said after the progress hints.
	"Dividing is sharing equally!",  # What division means.
	"12 ÷ 3 = 4, because 3 × 4 = 12.",  # Division and times tables are a family.
	"Any number ÷ 1 is the same number!",  # Dividing by 1.
	"A number ÷ itself is always 1!",  # Dividing a number by itself.
	"Know your times tables to divide fast!",  # The best way to get quicker.
]  # End of the list.
const LETTERS_PER_SECOND := 30.0  # How fast a line is typed into the speech bubble.
const MOUTH_SECONDS := 0.12  # How long the mouth stays open or closed while talking.
const LINE_SECONDS := 6.0  # How long a finished line stays before the next one comes.


# Returns everything a mascot says, in order: its greeting, the progress hints, then the tips.
static func lines_for(mascot_name: String, progress: Progress, records: Records) -> Array[String]:
	var lines: Array[String] = ["Hi! I'm %s. Let's divide!" % mascot_name]  # The greeting, with the mascot's name.
	var stars := progress.total_stars()  # Stars earned so far.
	if stars == 0:  # Nothing played yet ...
		lines.append("Tap Play to start your first Level!")  # ... an invitation.
	else:  # Some Stars ...
		lines.append("You have %d %s. Great work!" % [stars, "Star" if stars == 1 else "Stars"])  # ... praise them.
	var next := next_level(progress)  # The next Level to try.
	if not next.is_empty():  # There is one ...
		lines.append("Try Episode %d %s Level %d next!" % [next.episode, Difficulty.name_of(next.difficulty), next.level])  # ... point to it.
	var trophy := next_trophy(records)  # The next Trophy to aim for.
	if trophy.is_empty():  # Every Trophy earned ...
		lines.append("You have every Trophy. Amazing!")  # ... cheer.
	else:  # Some left ...
		lines.append("Next Trophy: %s. %s!" % [trophy.name, trophy.goal])  # ... name the next one and its goal.
	for tip: String in TIPS:  # Then each tip.
		lines.append(tip)  # Add it.
	return lines  # Hand back the lines.


# Returns the first open Level not yet passed, going through the Episodes and Difficulties in order,
# as {episode, difficulty, level}; or an empty dictionary when every open Level is passed.
static func next_level(progress: Progress) -> Dictionary:
	for episode in range(1, Progress.EPISODE_COUNT + 1):  # Each Episode ...
		for difficulty: int in Difficulty.Kind.values():  # ... each Difficulty ...
			for level in range(1, Progress.LEVEL_COUNT + 1):  # ... each Level ...
				if progress.is_level_open(episode, difficulty, level) and not progress.is_passed(episode, difficulty, level):  # ... open but not passed?
					return {"episode": episode, "difficulty": difficulty, "level": level}  # That is the one.
	return {}  # Nothing left to try.


# Returns the first Trophy not yet earned (its id, name and goal), or an empty dictionary.
static func next_trophy(records: Records) -> Dictionary:
	for trophy: Dictionary in Trophies.ALL:  # Each Trophy, in order ...
		if not records.has_trophy(trophy.id):  # ... not earned yet?
			return trophy  # That is the one.
	return {}  # Every Trophy earned.
