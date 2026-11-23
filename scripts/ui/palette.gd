# The DiviRush colours, from the approved style sample (D-009).
# Every screen takes its colours from here, so a colour changes in one place.
class_name Palette  # Lets any script write Palette.INK.
extends RefCounted  # Only its constants are used.

const SKY_TOP := Color("#4CC9F0")  # Light sky blue at the top of the background.
const SKY_BOTTOM := Color("#4361EE")  # Deep sky blue at the bottom of the background.
const INK := Color("#1B1B3A")  # Dark outline and text colour.
const YELLOW := Color("#FFD166")  # Sunny yellow for buttons and the score.
const PINK := Color("#EF476F")  # Bright pink for the streak badge and the low timer.
const GREEN := Color("#06D6A0")  # Green for correct answers and the full timer.
const RED := Color("#D62839")  # Deeper red for a wrong answer.
const WHITE := Color("#FFFFFF")  # White for cards.
const BLUE := Color("#4361EE")  # Blue text on white cards.
const LOCKED := Color("#B8C0D9")  # Grey-blue for locked cards and empty Stars.
const ORANGE := Color("#FFA94D")  # Warm orange for the Trophies tile on the Main menu (D-022).
