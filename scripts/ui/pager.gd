# A row that turns pages (D-032): a left arrow, the page number such as "1 / 3", and a right arrow.
# The left arrow is grey on the first page and the right arrow on the last; they do not wrap around.
# A swipe left or right anywhere on the screen also turns the page. Used by the Trophies tab and
# the How to Play lessons.
class_name Pager  # Lets the screens and tests write Pager.new(3).
extends HBoxContainer  # Arrow, number, arrow, side by side.

signal page_changed(index: int)  # Sent when the page changes, with the new page (0 is the first).

const SWIPE_DISTANCE := 120.0  # How far a finger must slide sideways to turn the page, in pixels.
const ARROW_SIZE := Vector2(130, 120)  # Each arrow button, big enough for small fingers.

var page := 0  # The page showing now; 0 is the first.
var count := 1  # How many pages there are.
var _prev: Button  # The left arrow.
var _next: Button  # The right arrow.
var _label: Label  # The page number, for example "1 / 3".
var _press_at := Vector2.ZERO  # Where a finger went down, to measure a swipe.
var _pressing := false  # true while a finger is down.


# Makes the row for `page_count` pages, starting on the first.
func _init(page_count: int) -> void:
	count = maxi(page_count, 1)  # At least one page.
	alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	add_theme_constant_override("separation", 40)  # Space between the arrows and the number.
	_prev = _make_arrow(false)  # The left arrow.
	_prev.pressed.connect(previous)  # It goes back a page.
	add_child(_prev)  # On the left.
	_label = UiKit.label("", 60, Palette.WHITE, 14)  # The page number, white with a dark outline.
	_label.custom_minimum_size.x = 200.0  # Room for "10 / 10" without the arrows moving.
	add_child(_label)  # In the middle.
	_next = _make_arrow(true)  # The right arrow.
	_next.pressed.connect(next)  # It goes on a page.
	add_child(_next)  # On the right.
	_refresh()  # Show page 1.


# Makes one white arrow button; the right arrow is the back arrow turned around.
func _make_arrow(right: bool) -> Button:
	var arrow := UiKit.card_button(Palette.WHITE, ARROW_SIZE, 40)  # A white button.
	var picture := UiKit.icon(UiKit.Icon.BACK, 76)  # The arrow picture.
	picture.flip_h = right  # Point right for the right arrow.
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)  # Centred on the button.
	arrow.add_child(picture)  # Put it on the button.
	return arrow  # Hand back the button.


# Shows a page (0 is the first), kept between the first and the last, and tells the screen.
func show_page(index: int) -> void:
	page = clampi(index, 0, count - 1)  # Never before the first or after the last.
	_refresh()  # Update the number and the arrows.
	page_changed.emit(page)  # Tell the screen to show it.


# The right arrow: the next page, unless this is the last.
func next() -> void:
	if page < count - 1:  # Not the last page ...
		show_page(page + 1)  # ... so go on one.


# The left arrow: the page before, unless this is the first.
func previous() -> void:
	if page > 0:  # Not the first page ...
		show_page(page - 1)  # ... so go back one.


# Turns the page for a sideways swipe: to the left (negative) is the next page, to the right the one before.
func swipe(distance: float) -> void:
	if distance <= -SWIPE_DISTANCE:  # Far enough to the left ...
		next()  # ... next page.
	elif distance >= SWIPE_DISTANCE:  # Far enough to the right ...
		previous()  # ... page before.


# Returns the page number as shown, for example "2 / 3".
func label_text() -> String:
	return _label.text  # The words on the row.


# Shows the page number, and turns an arrow grey when there is no page that way.
func _refresh() -> void:
	_label.text = "%d / %d" % [page + 1, count]  # For example "1 / 3".
	_prev.disabled = page == 0  # Grey on the first page.
	_next.disabled = page == count - 1  # Grey on the last page.
	_prev.modulate.a = 0.5 if _prev.disabled else 1.0  # A grey arrow is also faded.
	_next.modulate.a = 0.5 if _next.disabled else 1.0  # The same for the right arrow.


# Watches every tap on the screen for a sideways swipe, while this row is showing.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():  # Hidden (another tab is open) ...
		return  # ... so no swipes.
	var mouse := event as InputEventMouseButton  # Taps arrive as mouse clicks.
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:  # Not a tap ...
		return  # ... so nothing to do.
	if mouse.pressed:  # A finger goes down ...
		_press_at = mouse.position  # ... remember where,
		_pressing = true  # ... and that it is down.
	elif _pressing:  # The finger comes up ...
		_pressing = false  # ... it is up,
		var moved := mouse.position - _press_at  # ... how far it slid,
		if absf(moved.x) > absf(moved.y) * 1.5:  # ... mostly sideways ...
			swipe(moved.x)  # ... turns the page if it slid far enough.
