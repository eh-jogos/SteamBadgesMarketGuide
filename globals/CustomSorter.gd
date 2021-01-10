# Write your doc string for this file here
class_name CustomSorter
extends Reference

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	pass

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

static func sort_by_lowest_next_level(a: SteamBadgeData, b: SteamBadgeData) -> bool:
	if not a.is_complete() and not b.is_complete():
		var a_price = a.get_price_for_next_badge()
		var b_price = b.get_price_for_next_badge()
		if a_price > 0 and b_price > 0:
			return a_price < b_price
		elif a_price > 0 and b_price == 0:
			return true
		elif a_price == 0 and b_price == 0:
			return a.level < b.level
		else:
			return false
	elif not a.is_complete() and b.is_complete():
		return true
	else:
		return false


static func sort_game_by_name(game_a: SteamGameData, game_b: SteamGameData) -> bool:
	return game_a.title.to_lower() < game_b.title.to_lower()

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------
