# Write your doc string for this file here
extends Node

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

export var max_simultaneous_requests: int = 15

#--- private variables - order: export > normal var > onready -------------------------------------

var _requests_queue: Array = []

onready var _timer: Timer = $Timer
onready var _slots: Node = $Slots

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	pass

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func add_requests(requests_array: Array) -> void:
	var available_slots = max_simultaneous_requests - _slots.get_child_count()
	var slot_range: int = 0
	if requests_array.size() <= available_slots:
		slot_range = requests_array.size()
	else:
		slot_range = available_slots
		_timer.start()
	
	for index in range(slot_range-1, -1, -1):
		var request = requests_array[index]
		_slots.add_child(request, true)
		requests_array.remove(index)
	
	if requests_array.size() > 0:
		_requests_queue += requests_array


func get_queue_length() -> int:
	return _requests_queue.size()


func get_ongoing_requests_count() -> int:
	return _slots.get_child_count()

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _continue_requesting() -> void:
	if _requests_queue.size() > 0:
		var copy = _requests_queue.duplicate()
		_requests_queue.clear()
		add_requests(copy)


func _on_Timer_timeout():
	_continue_requesting()

### -----------------------------------------------------------------------------------------------
