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
	pass

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func show_all_games() -> void:
	var all_games = Database.games.values()
	_show_list(all_games)


func show_games_with_badges() -> void:
	var badge_games = Database.games.values()
	for index in range(badge_games.size() - 1, -1, -1):
		var game: SteamGameData = badge_games[index]
		if not game.has_cards:
			badge_games.remove(index)
	
	_show_list(badge_games)


func show_games_without_badges() -> void:
	var non_badge_games = Database.games.values()
	for index in range(non_badge_games.size() - 1, -1, -1):
		var game: SteamGameData = non_badge_games[index]
		if game.has_cards:
			non_badge_games.remove(index)
	
	_show_list(non_badge_games)

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _show_list(list: Array) -> void:
	text = ""
	list.sort_custom(CustomSorter, "sort_game_by_name")
	for index in list.size():
		var game: SteamGameData = list[index]
		
		text += game.title
		
		if game.is_free_game:
			text += "*(FREE)"
		
		if index < list.size()-1:
			text += "\n" 


### -----------------------------------------------------------------------------------------------
