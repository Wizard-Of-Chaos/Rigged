extends Node


signal new_player_registered(slot: int)
signal game_state_changed

var players: Array[Dictionary] = []
var active_players: int
const MAX_PLAYERS: int = 4
var current_state: State = State.MAIN_MENU

func _ready() -> void:
	for i in range(0, MAX_PLAYERS):
		players.append({
			"peer_id": 1,
			"devices": [],
			"is_active": false,
			"player_node": null,
		})
	active_players = 0
	register_player(0, [0])

func register_player(slot: int, devices: Array[int] = [], peer_id: int = 1) -> void:
	players[slot] = {
		"peer_id": peer_id,
		"devices": devices,
		"is_active": true,
		"player_node": null,
	}
	active_players += 1
	new_player_registered.emit(slot)


func unregister_player(p_slot: int) -> void:
	players[p_slot].is_active = false
	players[p_slot].player_node = null
	active_players -= 1

func find_player_for_device(p_device_id: int) -> int:
	for i in range(0, players.size()):
		if players[i].devices.find(p_device_id) != -1:
			return i
	return -1

func set_state(p_state: State) -> void:
	current_state = p_state
	game_state_changed.emit()


func update_players(p_players: Array[Dictionary]):
	var local_active_players := players.filter(func(player_info): return player_info.is_active and player_info.peer_id == multiplayer.get_unique_id())
	var current_player_to_update := 0
	for player in p_players:
		# gotta make sure to copy over the local data
		if player.peer_id == multiplayer.get_unique_id():
			player.devices = local_active_players[current_player_to_update].devices
			player.player_node = local_active_players[current_player_to_update]
			current_player_to_update += 1
		else:
			player.devices = []
			player.player_node = null
	players = p_players


func add_remote_players(p_num_players: int, p_peer_id: int) -> void:
	assert(p_num_players + active_players <= MAX_PLAYERS)
	var players_to_register = p_num_players
	for i in range(MAX_PLAYERS):
		if not players[i].is_active:
			register_player(i, [], p_peer_id)
			players_to_register -= 1
			if players_to_register == 0:
				break

enum State {
	MAIN_MENU,
	IN_GAME
}
