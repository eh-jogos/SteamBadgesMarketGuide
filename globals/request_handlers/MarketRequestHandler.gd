# Write your doc string for this file here
extends "res://globals/request_handlers/RequestHandler.gd"

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal cooldown_changed(seconds_left)

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

var last_time_left: = 0
var current_time_left: = 0

onready var _timer_cooldown: Timer = $"429Timer"

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	set_process(false)


func _process(_delta):
	current_time_left = _timer_cooldown.time_left
	
	if last_time_left == 0:
		last_time_left = current_time_left
	
	if current_time_left - last_time_left <= -1:
		last_time_left = current_time_left
		emit_signal("cooldown_changed", _timer_cooldown.time_left)

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func add_requests(requests_array: Array) -> void:
	var available_slots = clamp(
			max_simultaneous_requests - _slots.get_child_count(), 0, max_simultaneous_requests)
	
	if not _timer_cooldown.is_stopped() or not _timer.is_stopped():
		available_slots = 0
	
	var slot_range: int = int(min(available_slots, requests_array.size()))
	
	if requests_array.size() > max_simultaneous_requests:
		handle_error_429()
	else:
		_timer.start()
	
	for index in range(slot_range-1, -1, -1):
		var request = requests_array[index]
		_slots.add_child(request, true)
		requests_array.remove(index)
	
	if requests_array.size() > 0:
		_requests_queue += requests_array


func handle_error_429() -> void:
	if _timer_cooldown.is_stopped():
		_timer.stop()
		_timer_cooldown.start()
		set_process(true)

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _on_429Timer_timeout():
	set_process(false)
	current_time_left = 0
	last_time_left = 0
	emit_signal("cooldown_changed", 0)
	_continue_requesting()

### -----------------------------------------------------------------------------------------------
