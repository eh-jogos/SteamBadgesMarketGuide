# Request to get a Games List that will be used to build SteamGameData Objects and populate
# the "games database"
class_name GamesListRequest
extends HTTPRequest

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal games_list_parsed(games_list_array)
signal games_list_failed

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const URL = "https://steamcommunity.com/id/%s/games/?tab=all&sort=name"

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

var _games_list: Array = []

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed", self, "_on_request_completed")
	request_games_list()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func request_games_list() -> void:
	var error = request(URL%[Database.get_custom_url()])
	if  error != OK:
		push_warning("Something went wrong with GamesListRequest | Error: %s"%[error])
		assert(false)
		emit_signal("games_list_failed")
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
		
		print(JSON.print(msg, "  "))
		
		push_error("Request Response Error | result: %s | response_code: %s"%[result, response_code])
		assert(false)
		emit_signal("games_list_failed")
		queue_free()
		return
	
	var html_raw: String = body.get_string_from_utf8()
	
	_handle_games_page_scrubbing(html_raw)
	
	emit_signal("games_list_parsed", _games_list)
	queue_free()


func _handle_games_page_scrubbing(html_raw: String) -> void:
	var rgGames_start: = html_raw.find('var rgGames = ')
	var rgGames_end: = html_raw.find(";", rgGames_start)
	
	rgGames_start += 'var rgGames = '.length()
	var rgGames_raw = html_raw.substr(rgGames_start, rgGames_end - rgGames_start)
	_games_list = parse_json(rgGames_raw)
	if _games_list == null:
		push_error("Something went wrong parsing the rgGames_raw: %s"%[rgGames_raw])
		assert(false)
		emit_signal("games_list_failed")
		queue_free()

### -----------------------------------------------------------------------------------------------
