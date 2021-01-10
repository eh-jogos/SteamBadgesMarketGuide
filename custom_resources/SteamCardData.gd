# Steam Card Object
class_name SteamCardData
extends Resource

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal item_nameid_acquired(nameid)
signal item_price_updated

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

export var app_id: int = 0 
export var item_nameid: int = 0
export var title: String = ""
export var amount: int = 0
export var remaining: int = 5
export var price: float = 0.0 

#--- private variables - order: export > normal var > onready -------------------------------------



### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	pass


func _to_string() -> String:
	return "%0.2f | %s | %s | %s | %s"%[price, amount, remaining, title, app_id]

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func init_from_card_block(block: String, level: int, id: int) -> void:
	app_id = id
	
	var begin_string = '<div class=\"badge_card_set_text ellipsis\">'
	var title_begin = block.find('<div class=\"badge_card_set_text ellipsis\">')
	title_begin += begin_string.length() if title_begin != -1 else 0
	var title_end = block.find('<div style="clear: right">', title_begin)
	
	var title_raw = block.substr(title_begin, title_end - title_begin)
	
	var quantity_marker = '<div class=\"badge_card_set_text_qty\">'
	var quantity_begin = title_raw.find(quantity_marker)
	if quantity_begin != -1:
		var quantity_raw = title_raw.split("<\/div>")
		title_raw = quantity_raw[1]
		quantity_raw = quantity_raw[0].replace(quantity_marker, "").strip_edges()
		amount = int(quantity_raw.substr(1,1))
	
	remaining -= level - amount
	title = title_raw.strip_edges()


func request_nameid() -> void:
	var nameid_request = _get_nameid_request()
	MarketRequestHandler.add_requests([nameid_request])


func update_price() -> void:
	if item_nameid == 0:
		request_nameid()
		return
	else:
		emit_signal("item_nameid_acquired", item_nameid)
	
	var price_request = _get_price_request()
	RequestHandler.add_requests([price_request])

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

###### item_nameid request ------------------------------------------------------------------------

func _get_nameid_request() -> CardMarketPageRequest:
	var nameid_request: = CardMarketPageRequest.new()
	nameid_request.app_id = app_id
	nameid_request.title = title
	# warning-ignore:return_value_discarded
	nameid_request.connect(
			"card_nameid_failed", self, "_on_nameid_request_card_nameid_failed")
	# warning-ignore:return_value_discarded
	nameid_request.connect(
			"item_nameid_acquired", self, "_on_nameid_request_item_nameid_acquired")
	# warning-ignore:return_value_discarded
	nameid_request.connect("card_nameid_429", self, "_on_nameid_request_card_nameid_429")
	
	return nameid_request


func _on_nameid_request_card_nameid_failed(should_change_name: = false) -> void:
	if should_change_name and title.find("(Trading Card)") == -1:
		title = "%s (Trading Card)"%[title]
		print("No listings found, possible name error." + \
			"Tentatively adding (Trading Card) to it | %s"%[title])
	
	request_nameid()


func _on_nameid_request_card_nameid_429() -> void:
	MarketRequestHandler.handle_error_429()
	request_nameid()


func _on_nameid_request_item_nameid_acquired(item_id: int) -> void:
	item_nameid = item_id
	Database.badges[app_id].save()
	emit_signal("item_nameid_acquired", item_id)
	print("%s | %s | %s"%[app_id, title, item_nameid])
	update_price()

###### END OF item_nameid request -----------------------------------------------------------------

###### price request ------------------------------------------------------------------------------

func _get_price_request() -> CardPriceRequest:
	var price_request: = CardPriceRequest.new()
	price_request.item_name = title
	price_request.item_nameid = item_nameid
	# warning-ignore:return_value_discarded
	price_request.connect("card_price_acquired", self, "_on_price_request_card_price_acquired")
	# warning-ignore:return_value_discarded
	price_request.connect("card_price_failed", self, "_on_price_request_card_price_failed")
	
	return price_request


func _on_price_request_card_price_failed() -> void:
	update_price()


func _on_price_request_card_price_acquired(acquired_price: float) -> void:
	price = acquired_price
	Database.badges[app_id].save()
	emit_signal("item_price_updated")
	print(self)

###### END OF price request -----------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------
