# Steam Badge Object
class_name SteamBadgeData
extends Resource

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal badge_updated

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const BASE_MARKET_LINK = "https://steamcommunity.com/market/"
const GAME_FILTER = "search?appid=753&category_753_Game[]=tag_app_%s"
const CARDS_FILTER = "&category_753_cardborder[]=tag_cardborder_0&appid=753#p1_price_asc"
const BOOSTER_FILTER = "listings/753/%s-%s"
const BASE_BADGE_LINK = "https://steamcommunity.com/id/%s/gamecards/%s/"
const SAVE_FOLDER = "user://game_data/%s/"

#--- public variables - order: export > normal var > onready --------------------------------------

export var app_id: int = 0 setget _set_app_id
export var title: String = ""
export var level: int = 0
export var cards: Array
export var booster_pack: Resource
export var link_badge_page: String = ""
export var link_market: String = ""
export var link_booster_pack: String = ""

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	pass


func _to_string() -> String:
	var print_dict = {
		app_id = app_id,
		title = title,
		level = level,
		to_next_badge = get_price_for_next_badge(),
		to_max_level = get_price_for_level_five(),
		average_card = "%.2f"%[get_average_card_price()],
		cards = cards,
		link_badge_page = link_badge_page,
		link_market = link_market,
	}
	
	return JSON.print(print_dict, "  ")

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func save() -> void:
	var path = SAVE_FOLDER%[app_id]
	var dir: = Directory.new()
	if not dir.dir_exists(path):
		# warning-ignore:return_value_discarded
		dir.make_dir_recursive(path)
	
	# warning-ignore:return_value_discarded
	ResourceSaver.save(path + "badge_data.tres", self)


func update_badge_data() -> void:
	var update_request = UpdateBadgeRequest.new()
	update_request.requested_app_id = app_id
	update_request.connect("badge_update_failed", self, "_on_update_request_badge_update_failed")
	update_request.connect("badge_updated", self, "_on_update_request_badge_updated")
	RequestHandler.add_requests([update_request])


func update_card_prices() -> void:
	for index in cards.size():
		var card: SteamCardData = cards[index]
		card.update_price()
	
	booster_pack.update_price()


func get_price_for_next_badge() -> float:
	var price: float = 0.0
	
	var sum_per_reminaing: = {}
	
	if level < 5:
		for index in cards.size():
			var card: SteamCardData = cards[index]
			if card.remaining > 0:
				if not sum_per_reminaing.has(card.remaining):
					sum_per_reminaing[card.remaining] = 0
				sum_per_reminaing[card.remaining] += card.price
	
	if not sum_per_reminaing.empty():
		var max_remaining = sum_per_reminaing.keys().max()
		price = sum_per_reminaing[max_remaining]
	
	return price


func get_price_for_level_five() -> float:
	var price: float = 0.0
	
	if level < 5:
		for index in cards.size():
			var card: SteamCardData = cards[index]
			price += card.price * card.remaining
	
	return price


func get_average_card_price() -> float:
	var avg_of_cards: float = 0.0
	
	for card in cards:
		avg_of_cards += card.price
	
	avg_of_cards /= cards.size()
	
	return avg_of_cards


func is_complete() -> bool:
	var is_complete: = false
	
	if level == 5:
		is_complete = true
	else:
		var is_waiting_to_craft: = true
		for index in cards.size():
			var card: SteamCardData = cards[index]
			if card.remaining > 0:
				is_waiting_to_craft = false
				break
		is_complete = is_waiting_to_craft
	
	return is_complete

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _set_app_id(value: int) -> void:
	app_id = value
	
	if app_id > 0:
		title = Database.games[app_id].title
		link_badge_page = BASE_BADGE_LINK%[Database.get_custom_url() ,app_id]
		link_market = BASE_MARKET_LINK + GAME_FILTER%[app_id] + CARDS_FILTER


func _on_update_request_badge_update_failed() -> void:
	update_badge_data()


func _on_update_request_badge_updated() -> void:
	emit_signal("badge_updated")

### -----------------------------------------------------------------------------------------------
