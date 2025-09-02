# Write your doc string for this file here
class_name ProfileSetup
extends VBoxContainer

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

onready var _confirm_id: Button = $IDBlock/IdLine/ConfirmId
onready var _line_edit_id: LineEdit = $IDBlock/IdLine/LineEdit
onready var _status_id: AnimationPlayer = $IDBlock/IDStatus

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready() -> void:
	var current_id := Database.get_custom_url()
	if not current_id.empty():
		_status_id.play("success")
		_line_edit_id.text = current_id
	else:
		_status_id.play("RESET")

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _on_ConfirmId_pressed() -> void:
	_confirm_id.disabled = true
	var current_id := _line_edit_id.text
	if current_id.empty():
		_on_user_page_failed()
		return
	
	var request := UserProfileRequest.new()
	request.user_id = current_id
	request.connect("user_page_failed", self, "_on_user_page_failed")
	request.connect("user_page_success", self, "_on_user_page_success")
	add_child(request)


func _on_user_page_failed() -> void:
	_status_id.play("failed")
	_confirm_id.disabled = false


func _on_user_page_success(user_id: String) -> void:
	_status_id.play("success")
	_confirm_id.disabled = false
	Database.change_user(user_id)


### -----------------------------------------------------------------------------------------------
