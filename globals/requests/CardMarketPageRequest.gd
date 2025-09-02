# Write your doc string for this file here
class_name CardMarketPageRequest
extends HTTPRequest

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal item_nameid_acquired(price)
signal card_nameid_429
signal card_nameid_failed(should_change)

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const URL = "https://steamcommunity.com/market/listings/753/%s-%s"

#--- public variables - order: export > normal var > onready --------------------------------------

var app_id: int = 0
var title: String = ""

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed", self, "_on_request_completed")
	request_card_market_page()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func request_card_market_page() -> void:
	if app_id == 0 or title == "":
		push_error("App id and/or title can't be undefined! | app_id: %s | title: %s"%[
			app_id,
			title
		])
		queue_free()
		assert(false)
		return
	
	var url: = URL%[app_id, title.http_escape()]
	var error = request(url)
	if  error != OK:
		push_warning("Something went wrong with CardMarketPageRequest | Error: %s"%[error])
		emit_signal("card_nameid_failed", false)
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
	if result != OK or response_code != 200:
		var msg = {
			result = result,
			response_code = response_code,
			headers = headers,
			body = body.get_string_from_utf8(),
		}
		
		var datetime = OS.get_datetime()
		if response_code == 429 or response_code == 400:
			print("Expected Error | {response} | {hour}:{minute}:{second}".format({
					"response": response_code,
					"hour": "%02d"%[datetime.hour],
					"minute": "%02d"%[datetime.minute],
					"second": "%02d"%[datetime.second]
			}))
			emit_signal("card_nameid_429")
			queue_free()
		else:
			var url: = URL%[app_id, title]
			push_error("Request Response Error for %s | %s"%[url, msg])
			emit_signal("card_nameid_failed", false)
			queue_free()
		return
	
	var html_raw: String = body.get_string_from_utf8()
	
	var nameid_marker = 'Market_LoadOrderSpread('
	var nameid_begin = html_raw.find(nameid_marker)
	if nameid_begin != -1:
		nameid_begin += nameid_marker.length()
		var nameid_end = html_raw.find(');', nameid_begin)
		if nameid_end > -1:
			var nameid: String = html_raw.substr(nameid_begin, nameid_end - nameid_begin)
			nameid = nameid.strip_edges()
			emit_signal("item_nameid_acquired", int(nameid))
			queue_free()
		else:
			emit_signal("card_nameid_failed", false)
			queue_free()
	elif html_raw.find("There are no listings for this item.") != -1:
		emit_signal("card_nameid_failed", true)
		queue_free()
	else:
		push_error("Unknow response page: %s"%[html_raw])
		emit_signal("card_nameid_failed", false)
		queue_free()
#		assert(false)

### -----------------------------------------------------------------------------------------------
