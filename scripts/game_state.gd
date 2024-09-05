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


func unregister_player(slot: int) -> void:
	players[slot].is_active = false
	active_players -= 1

func find_player_for_device(device_id: int) -> int:
	for i in range(0, players.size()):
		if players[i].devices.find(device_id) != -1:
			return i
	return -1

func set_state(p_state: State):
	current_state = p_state
	game_state_changed.emit()

enum State {
	MAIN_MENU,
	IN_GAME
}
