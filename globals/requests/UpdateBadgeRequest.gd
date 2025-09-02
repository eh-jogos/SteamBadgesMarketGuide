# Write your doc string for this file here
class_name UpdateBadgeRequest
extends HTTPRequest

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal badge_updated
signal badge_update_failed

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
	
	var error = request(URL%[Database.get_custom_url(), requested_app_id])
	if  error != OK:
		push_warning("Something went wrong with BadgeReques | Error: %s"%[error])
		emit_signal("badge_update_failed")
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
		emit_signal("badge_update_failed")
		queue_free()
		assert(false)
		return
	
	var html_raw: String = body.get_string_from_utf8()
	html_raw = html_raw.replace("\t", "")
	
	if _is_gamecards_page(html_raw):
		_handle_gamecards_page_scrubbing(html_raw)
	elif _is_badges_list_page(html_raw):
		queue_free()
	else:
		emit_signal("badge_update_failed")
		queue_free()
		if html_raw.find("The specified profile could not be found.") == -1 \
				and html_raw.find("Failed loading profile data, please try again later.") == -1 :
			push_error("Unexpected page returned | html_raw: %s"%[html_raw])
			assert(false)


func _handle_gamecards_page_scrubbing(html_raw: String) -> void:
	var badge_data = Database.badges[requested_app_id]
	if badge_data == null:
		push_error("Impossible to retrieve badge with app_id: %s"%[requested_app_id])
		queue_free()
		assert(false)
		return
	
	var level_marker = html_raw.find('Level ')
	if level_marker != -1:
		var level_begin = level_marker + 'Level '.length()
		badge_data.level = int(html_raw.substr(level_begin, 1))
	
	var previous_title_end = 0
	for index in badge_data.cards.size():
		var card: SteamCardData = badge_data.cards[index]
		var sanitized_title = card.title.replace(" (Trading Card)", "")
		var search_term = '%s<div style=\"clear: right\"></div>'%[sanitized_title]
		var title_begin = html_raw.find(search_term, previous_title_end)
		
		if title_begin != -1:
			var sample_offset = 100
			var previous_sample = html_raw.substr(title_begin - sample_offset, sample_offset)
			var quantity_marker = '<div class=\"badge_card_set_text_qty\">'
			var quantity_begin = previous_sample.find(quantity_marker)
			if quantity_begin != -1:
				var quantity_raw = previous_sample.right(quantity_begin)
				quantity_raw = quantity_raw.replace(quantity_marker, "").strip_edges()
				var new_amount = int(quantity_raw.substr(1,1))
				card.amount = new_amount
			else:
				card.amount = 0
			
			previous_title_end  = html_raw.find('<div style=\"clear: right\">', title_begin)
		else:
			push_error("Couldn't find title: %s"%[sanitized_title])
			emit_signal("badge_update_failed")
			queue_free()
			assert(false)
		
		card.remaining = 5 - badge_data.level - card.amount
	
	if badge_data.booster_pack == null:
		var booster_pack: = SteamBoosterPack.new()
		booster_pack.init_from_badge_data(requested_app_id, Database.games[requested_app_id].title)
		badge_data.booster_pack = booster_pack
		badge_data.link_booster_pack = badge_data.BASE_MARKET_LINK + badge_data.BOOSTER_FILTER%[
			booster_pack.app_id,
			booster_pack.title
		]
	
	badge_data.save()
	emit_signal("badge_updated")
	queue_free()


func _is_badges_list_page(html_raw: String) -> bool:
	var is_badges_list: = html_raw.find('class=\"badges_sheet\"') != -1
	return is_badges_list


func _is_gamecards_page(html_raw: String) -> bool:
	var is_gamecards: = html_raw.find('class=\"badge_row depressed badge_gamecard_page\"') != -1
	return is_gamecards


### -----------------------------------------------------------------------------------------------
