extends PanelContainer

@onready var lobbies: VBoxContainer = $MarginContainer/Menu/LobbyBrowser/Lobbies

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SteamLobbyGlobal.fetch_lobbies()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_pressed() -> void:
	# TODO: implement a scene manager and preload all these menus
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_host_pressed() -> void:
	pass # Replace with function body.


func _on_join_pressed() -> void:
	pass # Replace with function body.


func _on_refresh_pressed() -> void:
	# TODO: add some some loading grpahic or something so user knows game hasn't frozen up
	SteamLobbyGlobal.fetch_lobbies()


func _on_lobby_button_pressed(p_lobby_id: int) -> void:
	pass


func _on_lobby_list_fetched() -> void:
	for lobby in lobbies.get_children():
		lobbies.remove_child(lobby)
	
	for lobby_info in SteamLobbyGlobal.get_lobby_list_info():
		var lobby_button := Button.new()
		lobby_button.set_text("Lobby %s: %s players" % [lobby_info.lobby_id, lobby_info.num_members])
		lobby_button.pressed.connect(_on_lobby_button_pressed.bind(lobby_info.lobby_id))
		lobby_button.set_name("Lobby%s" % lobby_info.lobby_id)
		lobbies.add_child(lobby_button)
