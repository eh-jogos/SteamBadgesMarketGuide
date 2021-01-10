# Write your doc string for this file here
extends Control

### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------

#--- enums ----------------------------------------------------------------------------------------

#--- constants ------------------------------------------------------------------------------------

#--- public variables - order: export > normal var > onready --------------------------------------

#--- private variables - order: export > normal var > onready -------------------------------------

onready var _tabs: TabContainer = $TabContainer
onready var _tab_config: MarginContainer = $TabContainer/Config
onready var _tab_card_guide: MarginContainer = $TabContainer/CardBuyGuide
onready var _tab_badge_list: MarginContainer = $TabContainer/GameBadgesList
onready var _tab_games_list: MarginContainer = $TabContainer/GamesList

### -----------------------------------------------------------------------------------------------


### Built in Engine Methods -----------------------------------------------------------------------

func _ready():
	if Database.get_custom_url() == "":
		_tabs.current_tab = _tab_config.get_index()
	else:
		_tabs.current_tab = _tab_card_guide.get_index()

### -----------------------------------------------------------------------------------------------


### Public Methods --------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------


### Private Methods -------------------------------------------------------------------------------

### -----------------------------------------------------------------------------------------------
