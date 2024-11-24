extends PanelContainer

@onready var players: VBoxContainer = $MarginContainer/Menu/PlayersBackground/Players
@onready var startButton: Button = $MarginContainer/Menu/BottomRowButtons/Start

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SteamLobbyGlobal.lobby_members_fetched.connect(_on_lobby_members_fetched)
	startButton.disabled = not SteamLobbyGlobal.is_host


func _on_lobby_members_fetched() -> void:
	# TODO: maybe reuse the old labels? Possibly unnecesarry optimization
	for player in players.get_children():
		player.queue_free()
	for lobby_member in SteamLobbyGlobal.lobby_members:
		var member_label := RichTextLabel.new()
		member_label.text = lobby_member.steam_name
		member_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		member_label.fit_content = true
		players.add_child(member_label)
	
	startButton.disabled = not SteamLobbyGlobal.is_host


func _on_leave_pressed() -> void:
	SteamLobbyGlobal.leave_lobby()
	get_tree().get_first_node_in_group("main").change_to_scene(load("res://scenes/menus/multiplayer.tscn"))
	#get_tree().change_scene_to_file("res://scenes/menus/multiplayer.tscn")


func _on_start_pressed() -> void:
	# clients should not be here
	assert(multiplayer.is_server())
	get_tree().get_first_node_in_group("main").change_to_scene(load("res://scenes/environments/basic.tscn"))

	#start_game.rpc()

#@rpc("call_local", "any_peer", "reliable")
#func start_game():
#	get_tree().change_scene_to_file("res://scenes/environments/basic.tscn")
