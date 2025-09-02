# Write your doc string for this file here
class_name GameDetailsRequest
extends HTTPRequest

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal game_details_success(requested_game)
signal game_details_request_failed

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const URL = "https://store.steampowered.com/app/%s/"
const URL_REVIEW = "https://steamcommunity.com/id/%s/recommended/%s/"

#--- public variables - order: export > normal var > onready --------------------------------------

var requested_game: SteamGameData = null

var has_cards_exceptions: = {
	"ONE PIECE PIRATE WARRIORS 3": true,
	"Ori and the Will of the Wisps": true,
	"Brothers - A Tale of Two Sons": true,
	"Kind Words": true,
}

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed", self, "_on_request_completed")
	request_game_store_page()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func request_game_store_page() -> void:
	if requested_game == null:
		push_error("Undefined game in GameDetailsRequest")
		assert(false)
		return
	
	var error = request(URL%[requested_game.app_id])
	if  error != OK:
		push_warning("Something went wrong with GameDetailsRequest | Error: %s"%[error])
		emit_signal("game_details_request_failed")
		queue_free()
		assert(false)


func request_review_page() -> void:
	var error = request(URL_REVIEW%[Database.get_custom_url() ,requested_game.app_id])
	if  error != OK:
		push_warning("Something went wrong with GameDetailsRequest | Error: %s"%[error])
		emit_signal("game_details_request_failed")
		queue_free()
		assert(false)

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _handle_request_failure(result: int, 
			response_code: int, 
			headers: PoolStringArray, 
			body: PoolByteArray
	) -> void:
	var msg = {
		result = result,
		response_code = response_code,
		headers = headers,
		body = body.get_string_from_utf8(),
	}
	
	print(JSON.print(msg, "  "))
	
	push_error("Request Response Error | result: %s | response_code: %s"%[result, response_code])
	emit_signal("game_details_request_failed")
	queue_free()
	assert(false)


###### Steam Page Handling ------------------------------------------------------------------------

func _on_request_completed(
			result: int, 
			response_code: int, 
			headers: PoolStringArray, 
			body: PoolByteArray
	) -> void:
	if result != OK and response_code != 200:
		_handle_request_failure(result, response_code, headers, body)
		return
	
	var html_raw: String = body.get_string_from_utf8()
	
	if _is_game_store_page(html_raw):
		_handle_game_store_page_scrubbing(html_raw)
	elif _is_age_gate(html_raw):
		disconnect("request_completed", self, "_on_request_completed")
		push_warning("Could not get data for %s"%[requested_game])
	elif _is_main_store_page(html_raw):
		# warning-ignore:return_value_discarded
		Database.erase_game(requested_game)
		queue_free()
	else:
		push_error("Unexpected page returned | html_raw: %s"%[html_raw])
		emit_signal("game_details_request_failed")
		queue_free()
		assert(false)


func _is_game_store_page(html_raw: String) -> bool:
	var is_game_store: = html_raw.find('id=\"game_area_purchase\"') != -1
	return is_game_store


func _is_main_store_page(html_raw: String) -> bool:
	var is_main_store: = html_raw.find('class=\"home_page_content\"') != -1
	return is_main_store


func _is_age_gate(html_raw: String) -> bool:
	var is_age_gate: = html_raw.find('Please enter your birth date to continue:') != -1
	return is_age_gate


func _handle_game_store_page_scrubbing(html_raw: String) -> void:
	requested_game.is_dlc = html_raw.find('<h1>Downloadable Content<\/h1>') != -1
	
	if not requested_game.is_dlc:
		if has_cards_exceptions.has(requested_game.title):
			requested_game.has_cards = has_cards_exceptions[requested_game.title]
		else:
			requested_game.has_cards = html_raw.find('>Steam Trading Cards<') != -1
	
	requested_game.is_free_game = _get_is_free_status(html_raw)
	
	disconnect("request_completed", self, "_on_request_completed")
	# warning-ignore:return_value_discarded
	connect("request_completed", self, "_on_review_request_completed")
	request_review_page()


func _get_is_free_status(html_raw: String) -> bool:
	var is_free = false
	
	var free_game_start = html_raw.find('<div class=\"btn_addtocart\">')
	if free_game_start != -1:
		var free_game_end = html_raw.find('<\/div', free_game_start)
		var free_game_string = html_raw.substr(free_game_start, free_game_end - free_game_start)
		is_free = free_game_string.find("Play") != -1
	
	return is_free

###### End of Steam Page Handling -----------------------------------------------------------------

###### Steam Review Page Handling -----------------------------------------------------------------

func _on_review_request_completed(result: int, 
			response_code: int, 
			headers: PoolStringArray, 
			body: PoolByteArray
	) -> void:
	if result != OK and response_code != 200:
		_handle_request_failure(result, response_code, headers, body)
		return
	
	var html_raw: String = body.get_string_from_utf8()
	
	if _is_game_review_page(html_raw):
		requested_game.has_reviewed = true
		emit_signal("game_details_success", requested_game)
		queue_free()
	elif _is_reviews_list_page(html_raw):
		requested_game.has_reviewed = false
		emit_signal("game_details_success", requested_game)
		queue_free()
	else:
		request_review_page()
		
		if not _is_known_review_error(html_raw):
			push_error("Unexpected page returned | html_raw: %s"%[html_raw])
			assert(false)


func _is_known_review_error(html_raw: String) -> bool:
	var profile_error = html_raw.find("The specified profile could not be found.") == -1
	var request_error = html_raw\
			.find("We were unable to service your request. Please try again later.") != -1
	
	return profile_error or request_error


func _is_game_review_page(html_raw: String) -> bool:
	var is_game_review = html_raw.find('class=\"review_page_content\"') != -1
	return is_game_review


func _is_reviews_list_page(html_raw: String) -> bool:
	var is_reviews_list = html_raw.find('class=\"review_list\"') != -1
	return is_reviews_list

###### End of Steam Review Page Handling ----------------------------------------------------------

### -----------------------------------------------------------------------------------------------
