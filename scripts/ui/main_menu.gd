extends Control

@onready var players_list: Control = %PlayersList
@onready var add_player_button: Button = %AddPlayerButton
@onready var start_button: Button = %Start
#@onready var music: FmodEventEmitter2D = %Music
@onready var audio_manager: FmodBankLoader = MasterBank


var _bank = "menu_music.bank"
var _menu_music ="event:/music/placeholder/mess_default"

func _ready():
	var player_count: int = 1
	for player in GameState.players.filter(func(player): return player.is_active):
		var player_button := Button.new()
		player_button.text = "Player %s" % player_count
		player_count += 1
		players_list.add_child(player_button)
	start_button.grab_focus()
	GameState.new_player_registered.connect(_on_new_player_registered)
	#only o
	audio_manager.play_song(_menu_music)
	#audio_manager.stop_song()
	#music.play()
	

func _input(event: InputEvent) -> void:
	if event.is_action("ui_cancel") and GameState.active_players < GameState.MAX_PLAYERS and GameState.find_player_for_device(event.device) == -1:
		GameState.register_player(GameState.active_players, [event.device])

func _on_start_pressed():
	audio_manager.fade_out_song()
	get_tree().change_scene_to_file("res://scenes/environments/basic.tscn")
	
func _on_options_pressed():
	pass

func _on_quit_pressed():
	#music.fade_out()
	get_tree().quit()

func _on_multiplayer_pressed():
	audio_manager.fade_out_song()
	get_tree().change_scene_to_file("res://scenes/menus/multiplayer.tscn")


func _on_new_player_registered(slot: int):
	var player_button := Button.new()
	player_button.text = "Player %s" % (slot+1)
	players_list.add_child(player_button)
	if GameState.active_players == 4:
		add_player_button.hide()
	elif add_player_button.hidden:
		add_player_button.show()
	#music.fade_out()
	
#func _on_exit_tree():
	#audio_manager
