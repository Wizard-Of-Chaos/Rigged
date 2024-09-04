extends Node


signal new_player_registered(slot: int)


var players: Array[Dictionary] = []
var active_players: int
const MAX_PLAYERS: int = 4
var current_state: State = State.MAIN_MENU

func _ready() -> void:
	for i in range(0, MAX_PLAYERS):
		players.append({
			"peer_id": 0,
			"devices": [],
			"is_active": false
		})
	players[0].is_active = true
	players[0].devices.append(0)
	active_players = 1

func register_player(slot: int, peer_id: int = 0, devices: Array[int] = []) -> void:
	players[slot] = {
		"peer_id": peer_id,
		"devices": devices,
		"is_active": true
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

enum State {
	MAIN_MENU,
	IN_GAME
}
