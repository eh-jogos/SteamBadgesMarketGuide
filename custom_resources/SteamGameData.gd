# Steam Game Object
# Format of Received Data, something more or less like
#{
#	"appid": 12900,
#	"name": "Audiosurf",
#	"playtime_forever": 224,
#	"img_icon_url": "ae6d0ac6d1dd5b23b961d9f32ea5a6c8d0305cf4",
#	"has_community_visible_stats": 1, # might not be included if gamne has no achievements or other stats
#	"playtime_windows_forever": 0,
#	"playtime_mac_forever": 0,
#	"playtime_linux_forever": 0,
#	"playtime_deck_forever": 0,
#	"rtime_last_played": 1321862400,
#	"capsule_filename": "library_600x900.jpg",
#	"has_workshop": 0,
#	"has_market": 0,
#	"has_dlc": 1,
#	"playtime_disconnected": 0
#},


class_name SteamGameData
extends Resource

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

const STORE_PAGE = "https://store.steampowered.com/app/%s"
const SAVE_FOLDER = "user://game_data/%s/"
const IMG_CDN = "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps"
const HEADER_IMG = IMG_CDN + "/%s/header.jpg"
const CAPSULE_IMG = IMG_CDN + "/%s/library_600x900.jpg"

#--- public variables - order: export > normal var > onready --------------------------------------

export var app_id: int = 0 setget _set_app_id
export var title: String = ""
export var is_free_game: bool = false
export var has_cards: bool = false
export var has_achievements: bool = false
export var has_reviewed: bool = false
export var total_hours: float = 0.0
export var last_played: int = 0
export var url_store: String = ""
export var url_logo: String = ""
export var logo: Texture = null setget , _get_logo
export var has_gotten_details: bool = false
export var is_age_gated := false

#--- private variables - order: export > normal var > onready -------------------------------------

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	pass


func _to_string() -> String:
	var print_string = \
	"""
	app_id = %s
	title = %s
	has_cards = %s | has_achievements = %s | has_reviewed = %s
	total_hours = %s | last_played = %s
	url_store = %s
	url_logo = %s
	"""%[
		app_id,
		title,
		has_cards,
		has_achievements,
		has_reviewed,
		total_hours,
		get_last_played_timestamp(),
		url_store,
		url_logo
	]
	
	return print_string

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

func save() -> void:
	var path = SAVE_FOLDER%[app_id]
	var dir: = Directory.new()
	if not dir.dir_exists(path):
		# warning-ignore:return_value_discarded
		dir.make_dir_recursive(path)
	
	# warning-ignore:return_value_discarded
	ResourceSaver.save(path + "%s.tres"%[app_id], self)


func init_from_steam_dict(dict: Dictionary) -> void:
	_set_app_id(dict.appid)
	title = dict.name
	url_logo = HEADER_IMG%[app_id]
	has_achievements = "has_community_visible_stats" in dict
	if dict.has("playtime_forever"):
		total_hours = float(dict.playtime_forever)
		last_played = dict.rtime_last_played


func get_last_played_timestamp() -> String:
	var timestamp: = "{year}-{month}-{day} {hour}:{minute}:{second}".format(
			OS.get_datetime_from_unix_time(last_played)
	)
	return timestamp

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

func _set_app_id(value: int) -> void:
	app_id = value
	
	if app_id > 0:
		url_store = STORE_PAGE%[app_id]


func _get_logo() -> Texture:
	return logo

### -----------------------------------------------------------------------------------------------
