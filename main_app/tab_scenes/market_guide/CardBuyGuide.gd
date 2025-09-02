# Write your doc string for this file here
extends MarginContainer

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

var _pending_badge_update_count: = 0
var _pending_badge_update_total: = 0

var _pending_incomplete_count: = 0
var _pending_incomplete_total: = 0

onready var _resources: ResourcePreloader = $ResourcePreloader
onready var _list: VBoxContainer = $Content/Scroll/List
onready var _button_update_all_badges: Button = $Content/Buttons/UpdateBadges
onready var _button_update_all_prices: Button = $Content/Buttons/UpdatePrices
onready var _button_check_for_new_badges: Button = $Content/Buttons/CheckNew

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	_populate_badges_buy_guide()
	if not Database.is_connected("game_details_acquired", self, 
			"_on_Database_game_details_acquired"):
		Database.connect("game_details_acquired", self, "_on_Database_game_details_acquired")

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _clear_badge_list() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


func _populate_badges_buy_guide() -> void:
	_clear_badge_list()
	var ordered_badges = Database.get_badges_by_price()
	for badge in ordered_badges:
		var guide = _resources.get_resource("BadgeGuide").instance()
		_list.add_child(guide)
		guide.badge_data = badge
		
		if not badge.is_connected("badge_updated", self, "_on_badge_updated"):
			# warning-ignore:return_value_discarded
			badge.connect("badge_updated", self, "_on_badge_updated")
		
		for index in badge.cards.size():
			var card: SteamCardData = badge.cards[index]
			if not card.is_connected("item_price_updated", self, "_on_item_price_updated"):
				# warning-ignore:return_value_discarded
				card.connect("item_price_updated", self, "_on_item_price_updated")


func _on_badge_updated() -> void:
	if _button_update_all_badges.disabled:
		_pending_badge_update_count += 1
		if _pending_badge_update_count >= _pending_badge_update_total:
			_button_update_all_badges.disabled = false
			_button_update_all_badges.text = "Update All Badges Data"
			_pending_badge_update_count = 0
			_pending_badge_update_total = 0
		else:
			_button_update_all_badges.text = "Updating Games (%03d/%03d)"%[
					_pending_badge_update_count,
					_pending_badge_update_total
			]
	
	_populate_badges_buy_guide()


func _on_Database_game_details_acquired(_game) -> void:
	if _button_check_for_new_badges.disabled:
		_pending_badge_update_count += 1
		if _pending_badge_update_count >= _pending_badge_update_total:
			_button_check_for_new_badges.disabled = false
			_button_check_for_new_badges.text = "Check for new badges"
			_pending_badge_update_count = 0
			_pending_badge_update_total = 0
		else:
			_button_check_for_new_badges.text = "Updating Games (%03d/%03d)"%[
					_pending_badge_update_count,
					_pending_badge_update_total
			]
	
	_populate_badges_buy_guide()


func _on_item_price_updated() -> void:
	if _button_update_all_prices.disabled:
		_pending_incomplete_count += 1
		if _pending_incomplete_count >= _pending_incomplete_total:
			_button_update_all_prices.disabled = false
			_button_update_all_prices.text = "Update All Badges Data"
			_pending_incomplete_count = 0
			_pending_incomplete_total = 0
			_populate_badges_buy_guide()
		else:
			_button_update_all_prices.text = "Updating Incomplete Prices (%03d/%03d)"%[
					_pending_incomplete_count,
					_pending_incomplete_total
			]

### -----------------------------------------------------------------------------------------------


func _on_UpdateBadges_pressed():
	_button_update_all_badges.disabled = true
	for key in Database.badges:
		var badge: SteamBadgeData = Database.badges[key]
		badge.update_badge_data()
	
	_pending_badge_update_total = Database.badges.size()
	_button_update_all_badges.text = "Updating Games (%03d/%03d)"%[
			_pending_badge_update_count,
			_pending_badge_update_total
	]


func _on_UpdatePrices_pressed():
	_button_update_all_prices.disabled = true
	
	for key in Database.badges:
		var badge: SteamBadgeData = Database.badges[key]
		for index in badge.cards.size():
			var card: SteamCardData = badge.cards[index]
			if card.remaining > 0:
				card.update_price()
				_pending_incomplete_total += 1
		
		if badge.booster_pack.price == 0:
			badge.booster_pack.update_price()
			_pending_incomplete_total += 1
	
	_button_update_all_prices.text = "Updating Incomplete Prices (%03d/%03d)"%[
			_pending_incomplete_count,
			_pending_incomplete_total
	]


func _on_CheckNew_pressed():
	_button_check_for_new_badges.disabled = true
	_pending_badge_update_total = Database.initialize_non_badge_game_details()
	
	_pending_badge_update_total = Database.badges.size()
	_button_check_for_new_badges.text = "Updating Games (%03d/%03d)"%[
			_pending_badge_update_count,
			_pending_badge_update_total
	]
