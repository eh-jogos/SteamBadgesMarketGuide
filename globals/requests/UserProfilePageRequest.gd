# Requests profile to validade username is correct and profile is public
class_name UserProfileRequest
extends HTTPRequest

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal user_page_success(p_user_id)
signal user_page_failed

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const URL = "https://steamcommunity.com/id/%s"

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

export var user_id := ""

export var should_log := false

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed", self, "_on_request_completed")
	request_user_profile()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func request_user_profile() -> void:
	if should_log:
		print_debug("requesting url: %s"%[URL%[user_id]])
	
	var error = request(URL%[user_id])
	if  error != OK:
		push_warning("Something went wrong with UserProfileRequest | Error: %s"%[error])
		assert(false)
		emit_signal("user_page_failed")
		queue_free()

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _on_request_completed(
			result: int, 
			response_code: int, 
			headers: PoolStringArray, 
			body: PoolByteArray
	) -> void:
	if result != OK and response_code != 200:
		var msg = {
			result = result,
			response_code = response_code,
			headers = headers,
			body = body.get_string_from_utf8(),
		}
		
		print_debug(JSON.print(msg, "  "))
		
		push_error("Request Response Error | result: %s | response_code: %s"%[result, response_code])
		assert(false)
		emit_signal("user_page_failed")
		queue_free()
	else:
		var html_raw: String = body.get_string_from_utf8()
		
		var is_success := html_raw.find("The specified profile could not be found") == -1
		if is_success:
			emit_signal("user_page_success", user_id)
		else:
			emit_signal("user_page_failed")
		
		if should_log:
			print_debug("User Profile Response arrived | is success: %s"%[is_success])
		
		queue_free()

### -----------------------------------------------------------------------------------------------
