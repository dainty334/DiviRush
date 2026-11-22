# Makes wrong answers for the answer bubbles.
# Used by the item bank tool when it builds the .tres files, not during play.
class_name WrongAnswers  # Lets any script call WrongAnswers.far().
extends RefCounted  # A light object; only its static functions are used.

const FAR_GAP := 3  # Easy wrong answers are at least 3 away from the answer (D-010).
const LOWEST := 1  # Smallest number a bubble may show.
const HIGHEST := 20  # Largest number a bubble may show.


# Returns `count` different wrong answers that are far from `correct`, for Easy items.
# Example: for 56 ÷ 8 = 7 it may return 2 and 15.
static func far(correct: int, count: int, rng: RandomNumberGenerator) -> Array[int]:
	var pool: Array[int] = []  # Every number that is allowed.
	for value in range(LOWEST, HIGHEST + 1):  # Try each number from 1 to 20.
		if absi(value - correct) >= FAR_GAP:  # Keep only numbers far enough away.
			pool.append(value)  # Add it to the allowed list.
	var picked: Array[int] = []  # The wrong answers chosen so far.
	while picked.size() < count and not pool.is_empty():  # Until enough are chosen.
		var index := rng.randi_range(0, pool.size() - 1)  # Pick a random spot in the list.
		picked.append(pool[index])  # Take that number.
		pool.remove_at(index)  # Remove it so it is not picked twice.
	return picked  # Hand back the wrong answers.
