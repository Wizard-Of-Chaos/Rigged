extends Control

@onready var players_list: Control = %PlayersList
@onready var add_player_button: Button = %AddPlayerButton
@onready var start_button: Button = %Start
@onready var music: FmodEventEmitter2D = %Music



func _ready():
	var player_count: int = 1
	for player in GameState.players.filter(func(player): return player.is_active):
		var player_button := Button.new()
		player_button.text = "Player %s" % player_count
		player_count += 1
		players_list.add_child(player_button)
	start_button.grab_focus()
	GameState.new_player_registered.connect(_on_new_player_registered)
	music.play()
	

func _input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") and GameState.active_players < GameState.MAX_PLAYERS and GameState.find_player_for_device(event.device) == -1:
		GameState.register_player(GameState.active_players, [event.device])

func _on_start_pressed():
	#music.fade_out()
	get_tree().change_scene_to_file("res://scenes/environments/basic.tscn")
	
func _on_options_pressed():
	pass

func _on_quit_pressed():
	music.fade_out()
	get_tree().quit()

func _on_multiplayer_pressed():
	music.fade_out()
	get_tree().change_scene_to_file("res://scenes/menus/multiplayer.tscn")


func _on_new_player_registered(slot: int):
	var player_button := Button.new()
	player_button.text = "Player %s" % (slot+1)
	players_list.add_child(player_button)
	if GameState.active_players == 4:
		add_player_button.hide()
	elif add_player_button.hidden:
		add_player_button.show()
	music.fade_out()
