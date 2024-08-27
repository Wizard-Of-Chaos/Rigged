extends PanelContainer

@onready var players: VBoxContainer = $MarginContainer/Menu/PlayersBackground/Players

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SteamLobbyGlobal.lobby_members_fetched.connect(_on_lobby_members_fetched)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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


func _on_leave_pressed() -> void:
	SteamLobbyGlobal.leave_lobby()
	get_tree().change_scene_to_file("res://multiplayer.tscn")


func _on_start_pressed() -> void:
	pass # Replace with function body.
