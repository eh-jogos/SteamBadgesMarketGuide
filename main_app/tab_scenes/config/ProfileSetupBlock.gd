# Write your doc string for this file here
class_name ProfileSetup
extends VBoxContainer

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

onready var _confirm_id: Button = $IDBlock/IdLine/ConfirmId
onready var _line_edit_id: LineEdit = $IDBlock/IdLine/LineEdit
onready var _status_id: AnimationPlayer = $IDBlock/IDStatus

onready var _source_box: TextEdit = $SourceBlock/SourceBox
onready var _confirm_source: Button = $SourceBlock/ConfirmSource

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready() -> void:
	var current_id := Database.get_custom_url()
	if not current_id.empty():
		_status_id.play("success")
		_line_edit_id.text = current_id
	else:
		_status_id.play("RESET")
	
	
	if not Database.games.empty():
		var free_games := []
		var age_gated := []
		for app_id in Database.games:
			var game = Database.games[app_id] as SteamGameData
			if game.is_free_game:
				free_games.append(game.title)
			
			if game.is_age_gated:
				age_gated.append(game.title)
		
		print_debug(free_games)
		print_debug(age_gated)
	
#	OS.shell_open("https://steamcommunity.com/market/pricehistory/?appid=753&market_hash_name=225260-Eddie%27s%20Dad")

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _on_ConfirmId_pressed() -> void:
	_confirm_id.disabled = true
	var current_id := _line_edit_id.text
	if current_id.empty():
		_on_user_page_failed()
		return
	
	var request := UserProfileRequest.new()
	request.user_id = current_id
	request.connect("user_page_failed", self, "_on_user_page_failed")
	request.connect("user_page_success", self, "_on_user_page_success")
	add_child(request)


func _on_user_page_failed() -> void:
	_status_id.play("failed")
	_confirm_id.disabled = false


func _on_user_page_success(user_id: String) -> void:
	_status_id.play("success")
	_confirm_id.disabled = false
	Database.change_user(user_id)


func _on_ConfirmSource_pressed() -> void:
	_confirm_source.disabled = true
	if _source_box.text.empty():
		# Failed Feedback
		_confirm_source.disabled = false
		return
	
	var games_list := _get_games_list(_source_box.text)
	if games_list.empty():
		# Failed Feedbak
		pass
	else:
		Database.parse_games_list(games_list)
		Database.request_game_details()
		_confirm_source.disabled = false


func _get_games_list(html_raw: String) -> Array:
	var rgGames_start: = html_raw.find('&quot;rgGames&quot;:')
	var rgGames_end: = html_raw.find(",&quot;rgPerfectUnownedGames", rgGames_start)
	
	rgGames_start += '&quot;rgGames&quot;:'.length()
	var rgGames_raw := html_raw.substr(rgGames_start, rgGames_end - rgGames_start)
	rgGames_raw = rgGames_raw.replace("&quot;",'"')
	var games_list: Array = parse_json(rgGames_raw)
	return games_list


### -----------------------------------------------------------------------------------------------
