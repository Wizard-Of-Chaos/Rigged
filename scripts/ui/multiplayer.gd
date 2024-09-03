extends PanelContainer

@onready var lobbies: VBoxContainer = $MarginContainer/Menu/LobbyBrowser/Lobbies
@onready var join_button: Button = $MarginContainer/Menu/BottomRowButtons/Join
var _selected_lobby: int
# TODO: add a timer to auto refresh every X seconds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SteamLobbyGlobal.lobby_list_fetched.connect(_on_lobby_list_fetched)
	SteamLobbyGlobal.lobby_created.connect(_on_lobby_created)
	SteamLobbyGlobal.lobby_joined.connect(_on_lobby_joined)
	SteamLobbyGlobal.fetch_lobbies()


func _on_back_pressed() -> void:
	# TODO: implement a scene manager and preload all these menus
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_host_pressed() -> void:
	# TODO: add some loading graphic or something so user knows game hasn't frozen up
	# TODO: pop up a modal to let user customize some attributes of the lobby?
	SteamLobbyGlobal.create_lobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 4)


func _on_join_pressed() -> void:
	if _selected_lobby == 0:
		return
	SteamLobbyGlobal.join_lobby(_selected_lobby)


func _on_refresh_pressed() -> void:
	# TODO: add some some loading grpahic or something so user knows game hasn't frozen up
	SteamLobbyGlobal.fetch_lobbies()


func _on_lobby_button_pressed(p_lobby_id: int) -> void:
	_selected_lobby = p_lobby_id
	join_button.disabled = false


func _on_lobby_list_fetched() -> void:
	for lobby in lobbies.get_children():
		lobby.queue_free()
	
	var lobby_gone := true
	for lobby_info in SteamLobbyGlobal.get_lobby_list_info():
		if lobby_info.lobby_id == _selected_lobby:
			lobby_gone = false
		var lobby_button := Button.new()
		lobby_button.set_text("Lobby %s: %s player(s)" % [lobby_info.lobby_id, lobby_info.num_members])
		lobby_button.pressed.connect(_on_lobby_button_pressed.bind(lobby_info.lobby_id))
		lobby_button.set_name("Lobby%s" % lobby_info.lobby_id)
		lobbies.add_child(lobby_button)
	if lobby_gone:
		join_button.disabled = true

func _on_lobby_created() -> void:
	print("we created a lobby!")
	#get_tree().change_scene_to_file("res://multiplayer_lobby.tscn")


func _on_lobby_joined() -> void:
	get_tree().change_scene_to_file("res://multiplayer_lobby.tscn")
