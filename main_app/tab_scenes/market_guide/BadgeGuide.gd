# Write your doc string for this file here
extends VBoxContainer

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

var badge_data: SteamBadgeData setget _set_badge_data

#--- private variables - order: export > normal var > onready -------------------------------------

var _badge_link: String = ""
var _market_link: String = ""
var _booster_link: String = ""

onready var _level_title: Label = $LevelTitle
onready var _prices: Label = $Prices
onready var _cards: Label = $Cards
onready var _badge_button: Button = $Buttons/Badge
onready var _market_button: Button = $Buttons/Market
onready var _booster_button: Button = $Buttons/Booster

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	pass

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _refresh_fields():
	_level_title.text = "Level %s - %s - %s"%[badge_data.level, badge_data.title, badge_data.app_id]
	_prices.text = "To Next: R$ %.2f | To Max: R$ %.2f | Average Card Price: %.2f"%[
		badge_data.get_price_for_next_badge(),
		badge_data.get_price_for_level_five(),
		badge_data.get_average_card_price(),
	] + " | Booster Price: %.2f | Average Card Price in Booster: %.2f"%[
		badge_data.booster_pack.price,
		badge_data.booster_pack.get_average_card_value(),
	]
	
	_cards.text = ""
	for card in badge_data.cards:
		_cards.text += "%s \n"%[card]
	
	if badge_data.link_badge_page != "":
		_badge_link = badge_data.link_badge_page
		_badge_button.disabled = false
	else:
		_badge_button.disabled = true
	
	if badge_data.link_market != "":
		_market_link = badge_data.link_market
		_market_button.disabled = false
	else:
		_market_button.disabled = true
	
	if badge_data.link_booster_pack != "":
		_booster_link = badge_data.link_booster_pack
		_booster_button.disabled = false
	else:
		_booster_button.disabled = true


func _set_badge_data(value: SteamBadgeData) -> void:
	badge_data = value
	if badge_data != null:
		_refresh_fields()
		# warning-ignore:return_value_discarded
		badge_data.connect("badge_updated", self, "_on_badge_data_bage_updated")


func _on_badge_data_bage_updated() -> void:
	_refresh_fields()


func _on_Badge_pressed():
	if _badge_link != "":
		# warning-ignore:return_value_discarded
		OS.shell_open(_badge_link)
	else:
		push_warning("Undefined _badge_link")


func _on_Market_pressed():
	if _market_link != "":
		# warning-ignore:return_value_discarded
		OS.shell_open(_market_link)
	else:
		push_warning("Undefined _market_link")


func _on_Booster_pressed():
	if _booster_link != "":
		# warning-ignore:return_value_discarded
		OS.shell_open(_booster_link)
	else:
		push_warning("Undefined _booster_link")


func _on_UpdateBadge_pressed():
	badge_data.update_badge_data()


func _on_UpdatePrices_pressed():
	badge_data.update_card_prices()

### -----------------------------------------------------------------------------------------------
