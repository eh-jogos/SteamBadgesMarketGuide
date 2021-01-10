# Write your doc string for this file here
extends MarginContainer

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const STEAM_PROFILE_URL = "https://steamcommunity.com/id"

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

onready var _url_line_edit: LineEdit = $Content/CustomUrl/LineEdit
onready var _button_initialize: Button = $Content/Inititalize
onready var _button_incomplete: Button = $Content/IncompleteBadgePrices
onready var _button_complete: Button = $Content/CompletedBadgePrices
onready var _label_invalid: Label = $Content/InvalidCustomUrl
onready var _label_progress: Label = $Content/InitializeProgress
onready var _label_nameid_warning: Label = $Content/WarningLabel2
onready var _label_incomplete: Label = $Content/IncompleteBadgeProgress
onready var _label_complete: Label = $Content/CompleteBadgeProgress

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	_label_invalid.hide()
	_label_progress.hide()
	_label_nameid_warning.hide()
	_label_complete.hide()
	_label_incomplete.hide()
	
	if Database.user_data.steam_custom_url != "":
		_url_line_edit.text = STEAM_PROFILE_URL + "/" + Database.get_custom_url()
		_button_initialize.show()
	else:
		_button_initialize.hide()
	
	if Database.games.size() > 0 and Database.badges.size() > 0:
		_button_complete.show()
		_button_incomplete.show()
		_label_nameid_warning.show()
	else:
		_button_incomplete.hide()
		_button_complete.hide()
	
	_label_progress.connect("initialization_finished", self, "_on_inilitalization_finished")

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _handle_steam_profile_url(url: String) -> void:
	if url.find(STEAM_PROFILE_URL) == -1:
		_label_invalid.show()
		return
	
	var custom_url = url.replace(STEAM_PROFILE_URL, "").replace("/", "")
	
	Database.change_user(custom_url)
	_button_initialize.show()

### -----------------------------------------------------------------------------------------------


func _on_LineEdit_text_entered(new_text: String) -> void:
	_handle_steam_profile_url(new_text)


func _on_Button_pressed() -> void:
	_handle_steam_profile_url(_url_line_edit.text)


func _on_LineEdit_text_changed(new_text):
	_label_invalid.hide()


func _on_Inititalize_pressed():
	Database.request_games()
	_label_progress.text = "Waiting for requests..."
	_label_progress.show()


func _on_IncompleteBadgePrices_pressed():
	for key in Database.badges:
		var badge: SteamBadgeData = Database.badges[key]
		if not badge.is_complete():
			_label_incomplete.request_price_update_for(badge)
	
	_label_incomplete.text = "Waiting for requests..."
	_label_incomplete.show()


func _on_CompletedBadgePrices_pressed():
	for key in Database.badges:
		var badge: SteamBadgeData = Database.badges[key]
		if badge.is_complete():
			_label_complete.request_price_update_for(badge)
	
	_label_complete.text = "Waiting for requests..."
	_label_complete.show()


func _on_inilitalization_finished() -> void:
	_button_complete.show()
	_button_incomplete.show()
	_label_nameid_warning.show()
