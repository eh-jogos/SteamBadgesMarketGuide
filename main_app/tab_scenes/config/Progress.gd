# Write your doc string for this file here
extends Label

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal initialization_finished

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

var _base_text: = ""
var _games_total: = 0
var _game_details_count: = 0
var _game_age_gated_count := 0
var _badge_total: = 0
var _badge_details_count: = 0
var _cards_total: = 0
var _card_prices_count: = 0

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	_base_text = text
	Database.connect("game_list_parsed", self, "_on_Database_game_list_parsed")
	Database.connect("game_removed_from_list", self, "_on_Database_game_removed_from_list")
	Database.connect("game_details_acquired", self, "_on_Database_game_details_acquired")
	Database.connect("game_details_age_gated", self, "_on_Database_game_details_age_gated")
	Database.connect("badge_data_completed", self, "_on_Database_badge_data_completed")
	# TODO - Update text and variables based on Database if there's any data there.

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _update_text() -> void:
	text = _base_text%[
		_game_details_count, 
		_games_total,
		_game_age_gated_count,
		_badge_details_count,
		_badge_total,
		]


func _on_Database_game_list_parsed() -> void:
	_games_total = Database.games.size()
	_update_text()


func _on_Database_game_removed_from_list() -> void:
	_games_total = Database.games.size() - _game_age_gated_count
	_update_text()


func _on_Database_game_details_acquired(game: SteamGameData) -> void:
	_game_details_count += 1
	
	if game.has_cards:
		_badge_total += 1
	
	_update_text()


func _on_Database_badge_data_completed(_badge: SteamBadgeData) -> void:
	_badge_details_count += 1
	
	if _badge_details_count >= _badge_total:
		emit_signal("initialization_finished")
	
	_update_text()


func _on_Database_game_details_age_gated() -> void:
	_games_total -= 1
	_game_age_gated_count += 1
	_update_text()

### -----------------------------------------------------------------------------------------------
