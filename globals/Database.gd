# Write your doc string for this file here
extends Node

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

signal game_list_parsed
signal game_details_acquired(game)
signal game_removed_from_list
signal badge_data_completed(badge)

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const GAME_DATA_PATH = "user://game_data/"

#--- public variables - order: export > normal var > onready --------------------------------------

var user_data: UserData = UserData.new()
var games: Dictionary = {}
var badges: Dictionary = {}

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	_load_saved_gamedata()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func change_user(custom_url: String) -> void:
	user_data.steam_custom_url = custom_url
	user_data.save()
	games = {}
	badges = {}


func get_custom_url() -> String:
	return user_data.steam_custom_url


func request_games() -> void:
	var games_list: = GamesListRequest.new()
	# warning-ignore:return_value_discarded
	games_list.connect("games_list_failed", self, "_on_games_list_failed")
	# warning-ignore:return_value_discarded
	games_list.connect("games_list_parsed", self, "_on_games_list_parsed")
	
	RequestHandler.add_requests([games_list])


func erase_game(game: SteamGameData) -> void:
	print("Game unavailable, removing from list | %s "%[game])
	games.erase(game.app_id)
	
	if game.has_cards:
		breakpoint
	
	emit_signal("game_removed_from_list")


func request_game_details() -> void:
	var game_details_requests: = []
	for game in games.values():
		if game.has_gotten_details:
			emit_signal("game_details_acquired", game)
			print("%s already has details"%[game.app_id])
			if _should_request_badge(game):
				request_badge(game)
			elif game.has_cards:
				emit_signal("badge_data_completed", badges[game.app_id])
			continue
		
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


func request_badge(game: SteamGameData) -> void:
	var badge_request: = BadgeRequest.new()
	# warning-ignore:return_value_discarded
	badge_request.connect("badge_request_failed", self, "_on_badge_resquest_failed", [badge_request])
	# warning-ignore:return_value_discarded
	badge_request.connect("badge_found", self, "_on_badge_found")
	badge_request.requested_app_id = game.app_id
	RequestHandler.add_requests([badge_request])


func request_cards_nameid(game: SteamGameData) -> void:
	if not badges.has(game.app_id):
		return
	
	var badge: SteamBadgeData = badges[game.app_id] as SteamBadgeData
	for element in badge.cards:
		var card: SteamCardData = element as SteamCardData
		card.update_price()


func get_badges_by_price() -> Array:
	var all_badges: Array = Database.badges.values()
	all_badges.sort_custom(CustomSorter, "sort_by_lowest_next_level")
	return all_badges

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _load_saved_gamedata() -> void:
	if ResourceLoader.exists(UserData.SAVE_LOCATION):
		user_data = load(UserData.SAVE_LOCATION)
	
	var dir: = Directory.new()
	if dir.dir_exists(GAME_DATA_PATH):
		var error = dir.open(GAME_DATA_PATH)
		if error != OK:
			push_error("Something went wrong when opening %s | %s"%[GAME_DATA_PATH, error])
			return
	else:
		return
	
	# warning-ignore:return_value_discarded
	dir.list_dir_begin(true)
	var element = dir.get_next()
	while element != "":
		games[int(element)] = load("%s%s/%s.tres"%[GAME_DATA_PATH, element, element])
		
		if games[int(element)].has_cards:
			var badge_path = "%s%s/badge_data.tres"%[GAME_DATA_PATH, element]
			if ResourceLoader.exists(badge_path):
				badges[int(element)] = load(badge_path)
		
		element = dir.get_next()


func _on_games_list_failed() -> void:
	print("RETRY | GamesListRequest")
	request_games()


func _on_games_list_parsed(games_list: Array) -> void:
	for game in games_list:
		if games.has(int(game.appid)):
			print("already has %s | skipping"%[game.appid])
			continue
		
		var game_data: = SteamGameData.new()
		game_data.init_from_steam_dict(game)
		games[game_data.app_id] = game_data
		game_data.save()
	
	emit_signal("game_list_parsed")
	
	request_game_details()


func _on_badge_resquest_failed(request: BadgeRequest) -> void:
	print("RETRY | BadgeRequest | %s"%[request.requested_app_id])
	RequestHandler.add_requests([request])


func _on_badge_found(badge_data: SteamBadgeData) -> void:
	badges[badge_data.app_id] = badge_data
	badge_data.save()
	
	emit_signal("badge_data_completed", badge_data)


func _should_request_badge(game: SteamGameData) -> bool:
	return not badges.has(game.app_id) and game.has_cards


func _on_game_details_request_failed(request: GameDetailsRequest) -> void:
	print("RETRY | GameDetailsRequest | %s"%[request.requested_game])
	RequestHandler.add_requests([request])


func _on_game_details_success(game: SteamGameData) -> void:
	game.has_gotten_details = true
	game.save()
	
	emit_signal("game_details_acquired", game)
	
	if _should_request_badge(game):
		request_badge(game)

### -----------------------------------------------------------------------------------------------
