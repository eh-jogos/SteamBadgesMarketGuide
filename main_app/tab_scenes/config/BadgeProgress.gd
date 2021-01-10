# Write your doc string for this file here
extends Label

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const BASE_TEXT = "Scrubbing Card Name ids (%03d/%03d) \n" \
		+ "Getting Card Prices (%03d/%03d) \n" \
		+ "requests cooldown: %02d:%02d"

#--- public variables - order: export > normal var > onready --------------------------------------


#--- private variables - order: export > normal var > onready -------------------------------------

var _nameid_total: = 0
var _cards_total: = 0
var _card_prices_count: = 0
var _name_id_cooldown: = 0

var _nameids_list: = []

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	MarketRequestHandler.connect("cooldown_changed", self, 
			"_on_MarketRequestHandler_cooldown_changed")

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func request_price_update_for(badge: SteamBadgeData) -> void:
	_cards_total += badge.cards.size() + 1
	_nameid_total = _cards_total
	
	for index in badge.cards.size():
		var card: SteamCardData = badge.cards[index]
		if not card.is_connected("item_price_updated", self, "_on_card_item_price_updated"):
			card.connect("item_nameid_acquired", self, "_on_card_item_nameid_acquired")
			card.connect("item_price_updated", self, "_on_card_item_price_updated")
		card.update_price()
	
	if badge.booster_pack != null:
		var booster = badge.booster_pack as SteamBoosterPack
		if not booster.is_connected("item_price_updated", self, "_on_card_item_price_updated"):
			booster.connect("item_nameid_acquired", self, "_on_card_item_nameid_acquired")
			booster.connect("item_price_updated", self, "_on_card_item_price_updated")
		booster.update_price()

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _update_text() -> void:
	var seconds: = 0
	var minutes: = 0
	
	if _name_id_cooldown > 0:
		minutes = _name_id_cooldown / 60
		seconds = _name_id_cooldown % 60
	
	text = BASE_TEXT%[
		_nameids_list.size(),
		_nameid_total,
		_card_prices_count, 
		_cards_total,
		minutes,
		seconds
		]


func _on_card_item_nameid_acquired(nameid: int) -> void:
	if not _nameids_list.has(nameid):
		_nameids_list.append(nameid)
		_update_text()


func _on_card_item_price_updated() -> void:
	_card_prices_count += 1
	_update_text()


func _on_MarketRequestHandler_cooldown_changed(seconds_left: float) -> void:
	_name_id_cooldown = seconds_left
	_update_text()

### -----------------------------------------------------------------------------------------------
