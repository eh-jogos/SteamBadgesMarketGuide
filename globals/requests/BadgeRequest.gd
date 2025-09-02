# Write your doc string for this file here
class_name BadgeRequest
extends HTTPRequest

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal badge_found(badge_data)
signal badge_request_failed

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const URL = "https://steamcommunity.com/id/%s/gamecards/%s/"

#--- public variables - order: export > normal var > onready --------------------------------------

var requested_app_id: int = 0

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed", self, "_on_request_completed")
	request_gamecards_page()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func request_gamecards_page() -> void:
	if requested_app_id == 0:
		push_error("Undefined app id in BadgeRequest")
		assert(false)
		return
	
	var error = request(URL%[Database.get_custom_url() ,requested_app_id])
	if  error != OK:
		push_warning("Something went wrong with BadgeReques | Error: %s"%[error])
		emit_signal("badge_request_failed")
		queue_free()
		assert(false)

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
		emit_signal("badge_request_failed")
		queue_free()
		assert(false)
		return
	
	var html_raw: String = body.get_string_from_utf8()
	
	if _is_gamecards_page(html_raw):
		_handle_gamecards_page_scrubbing(html_raw)
	elif _is_badges_list_page(html_raw):
		queue_free()
	elif html_raw.find("Failed loading profile data, please try again later.") != -1:
		push_error("too much traffic??")
		assert(false)
		queue_free()
	else:
		push_error("Unexpected page returned | html_raw: %s"%[html_raw])
		emit_signal("badge_request_failed")
		queue_free()
		assert(false)


func _handle_gamecards_page_scrubbing(html_raw: String) -> void:
	var badge_data = SteamBadgeData.new()
	badge_data.app_id = requested_app_id
	
	var level_marker = html_raw.find('Level ')
	if level_marker != -1:
		var level_begin = level_marker + 'Level '.length()
		badge_data.level = int(html_raw.substr(level_begin, 1))
	
	var cards_block = html_raw.split("badge_card_set_card")
	cards_block.remove(1)
	cards_block.remove(0)
	
	for block in cards_block:
		var card_data = SteamCardData.new()
		card_data.init_from_card_block(block, badge_data.level, badge_data.app_id)
		badge_data.cards.append(card_data)
	
	var booster_pack: = SteamBoosterPack.new()
	booster_pack.init_from_badge_data(requested_app_id, Database.games[requested_app_id].title)
	badge_data.booster_pack = booster_pack
	badge_data.link_booster_pack = badge_data.BASE_MARKET_LINK + badge_data.BOOSTER_FILTER%[
		booster_pack.app_id,
		booster_pack.title
	]
	
	emit_signal("badge_found", badge_data)
	queue_free()


func _is_badges_list_page(html_raw: String) -> bool:
	var is_badges_list: = html_raw.find('class=\"badges_sheet\"') != -1
	return is_badges_list


func _is_gamecards_page(html_raw: String) -> bool:
	var is_gamecards: = html_raw.find('class=\"badge_row depressed badge_gamecard_page\"') != -1
	return is_gamecards


### -----------------------------------------------------------------------------------------------
