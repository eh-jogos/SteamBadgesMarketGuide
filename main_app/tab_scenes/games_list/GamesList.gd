# Write your doc string for this file here
extends MarginContainer

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

var _pending_update_count: = 0
var _total_to_update: = 0

onready var _update_button: Button = $Content/Buttons/UpdateAll
onready var _text_edit_all_games: TextEdit = $Content/Columns/GamesColumn/AllGames
onready var _text_edit_badge_games: TextEdit = $Content/Columns/BadgeColumn/BadgeGames
onready var _text_edit_non_badge_games: TextEdit = $Content/Columns/NoBadgeColumn/BadgelessGames

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	# warning-ignore:return_value_discarded
	connect("visibility_changed", self, "_on_visibility_changed")
	pass

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func print_all_lists() -> void:
	_text_edit_all_games.show_all_games()
	_text_edit_badge_games.show_games_with_badges()
	_text_edit_non_badge_games.show_games_without_badges()

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _on_visibility_changed() -> void:
	if visible:
		print_all_lists()

### -----------------------------------------------------------------------------------------------


func _on_UpdateAll_pressed():
	_update_button.disabled = true
	var game_details_requests: = []
	
	for key in Database.games:
		var game: SteamGameData = Database.games[key]
		
		var game_details_request: = GameDetailsRequest.new()
		game_details_request.requested_game = game
		game_details_requests.append(game_details_request)
		# warning-ignore:return_value_discarded
		game_details_request.connect(
				"game_details_request_failed", 
				self, 
				"_game_details_request_failed", 
				[game_details_request]
		)
		# warning-ignore:return_value_discarded
		game_details_request.connect("game_details_success", self, "_on_game_details_success")
	
	RequestHandler.add_requests(game_details_requests)
	
	_pending_update_count = game_details_requests.size()
	_total_to_update = _pending_update_count
	_update_button.text = "Updating Games (%03d/%03d)"%[
			_total_to_update - _pending_update_count,
			_total_to_update
	]


func _on_game_details_request_failed(request: GameDetailsRequest) -> void:
	print("RETRY | GameDetailsRequest | %s"%[request.requested_game])
#	RequestHandler.add_requests([request])


func _on_game_details_success(game: SteamGameData) -> void:
	game.has_gotten_details = true
	game.save()
	_pending_update_count -= 1
	
	if _pending_update_count <= 0:
		_update_button.text = "Update All Games Data"
		_update_button.disabled = false
		print_all_lists()
	else:
		_update_button.text = "Updating Games (%03d/%03d)"%[
				_total_to_update - _pending_update_count,
				_total_to_update
		]
	


func _on_RefreshLists_pressed():
	print_all_lists()
