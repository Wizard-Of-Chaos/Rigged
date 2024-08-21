extends Node

var APP_ID: int = 3174650

var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_app_id: int = 480
var steam_id: int = 0
var steam_username: String = ""

var player_one: int = -1
var inGameControlsHandle: int = -1
var movementHandle: int = -1
var cameraHandle: int = -1
var menuControlsHandle: int = -1
var jumpHandle: int = -1

func _ready() -> void:
	initialize_steam()

func _process(_delta: float) -> void:
	Steam.run_callbacks()
	var controllers := Steam.getConnectedControllers()
	
	if player_one == -1 and controllers.size() > 0:
		player_one = controllers[0]
		Steam.activateActionSet(player_one, inGameControlsHandle)

func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(true, APP_ID)
	print("Did Steam initialize?: %s" % initialize_response)

	if initialize_response.status > 0:
		# INFO: may want to support non-steam platforms or otherwise handle this more gracefully
		print("Failed to initialize Steam, shutting down: %s" % initialize_response.verbal)
		get_tree().quit()
	
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_online = Steam.loggedOn()
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	Steam.runFrame()
	inGameControlsHandle = Steam.getActionSetHandle("InGameControls")
	menuControlsHandle = Steam.getActionSetHandle("MenuControls")
	movementHandle = Steam.getAnalogActionHandle("Move")
	cameraHandle = Steam.getAnalogActionHandle("Camera")
	jumpHandle = Steam.getDigitalActionHandle("Jump")
