# Write your doc string for this file here
extends TextEdit

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	Database.connect("badge_data_completed", self, "_on_Database_badge_data_completed")
	test_order_by_badge_prices()
	pass

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func test_update_prices() -> void:
	for key in Database.badges.keys():
		var badge: SteamBadgeData = Database.badges[key]
		if badge.level < 5:
			badge.update_badge_data()
			badge.connect("badge_updated", self, "_on_badge_badge_updated", [badge])


func test_order_by_badge_prices() -> void:
	var all_badges: Array = Database.badges.values()
	all_badges.sort_custom(CustomSorter, "sort_by_lowest_next_level")
	for badge in all_badges:
		text += "%s \n"%[badge]

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _on_Database_badge_data_completed(badge: SteamBadgeData) -> void:
	text += str(badge)


func _on_SteamBadgesBuilder_badge_response(response_text):
	text = response_text


func _on_badge_badge_updated(badge: SteamBadgeData) -> void:
	text += "%s \n"%[badge]

### -----------------------------------------------------------------------------------------------
