# Write your doc string for this file here
class_name CardPriceRequest
extends HTTPRequest

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal card_price_acquired(price)
signal card_price_failed

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const URL = "https://steamcommunity.com/market/itemordershistogram"+\
		"?country=BR&language=english&currency=7&item_nameid=%s&two_factor=0"

#--- public variables - order: export > normal var > onready --------------------------------------

var item_nameid: int = 0
var item_name: String = ""

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed", self, "_on_request_completed")
	request_card_price()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func request_card_price() -> void:
	var url: = URL%[item_nameid]
	var error = request(url)
	if  error != OK:
		push_warning("Something went wrong with CardMarketPageRequest | Error: %s"%[error])
		emit_signal("card_price_failed")
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
		
		print(JSON.print(msg, "  "))
		
		push_error("Request Response Error | result: %s | response_code: %s"%[result, response_code])
		
		emit_signal("card_price_failed")
		queue_free()
		return
	
	var json_dict = parse_json(body.get_string_from_utf8())
	
	if json_dict is Dictionary and json_dict.has("sell_order_graph"):
		var price = json_dict["sell_order_graph"][0][0]
		emit_signal("card_price_acquired", price)
		queue_free()
	else:
		if json_dict.has("success") and json_dict["success"] != 16:
			push_error("Unknow response json: %s | for %s | from url: %s"%[
					json_dict, item_name, URL%[item_nameid]])
			
			breakpoint
		
		emit_signal("card_price_failed")
		queue_free()
		return

### -----------------------------------------------------------------------------------------------
