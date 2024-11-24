extends Node


signal lobby_list_fetched
signal lobby_members_fetched
signal lobby_created
signal lobby_joined(owner_id: int)

const LOBBY_CMDLINE_ARG := "+connect_lobby"
var lobby_id: int = 0
var lobby_members: Array = []
var lobbies: Array = []
var players: Dictionary = {}
var is_host: bool = false
var lobby_max: int = 4


func _ready() -> void:
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.join_game_requested.connect(_on_join_game_requested)
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	multiplayer.connection_failed.connect(_on_multiplayer_connection_failed)
	check_command_line()

func check_command_line() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	var connect_lobby_idx := args.find(LOBBY_CMDLINE_ARG)
	if connect_lobby_idx < 0:
		return
	var cmdline_lobby_id := 0
	if args.size() > connect_lobby_idx + 2 and args[connect_lobby_idx+1].is_valid_int():
		cmdline_lobby_id = int(args[connect_lobby_idx+1])

	if cmdline_lobby_id == 0:
		return
	
	print("Command line lobby ID: %s" % cmdline_lobby_id)
	join_lobby(cmdline_lobby_id)


func create_lobby(p_lobby_type: Steam.LobbyType, p_max_members: int) -> void:
	# you're already in a lobby numbnuts
	if lobby_id != 0:
		return
	lobby_max = p_max_members
	Steam.createLobby(p_lobby_type, p_max_members)


func join_lobby(p_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % p_lobby_id)
	is_host = false
	Steam.joinLobby(p_lobby_id)


func get_lobby_members() -> void:
	lobby_members.clear()
	var num_members: int = Steam.getNumLobbyMembers(lobby_id)
	var lobby_owner: int = Steam.getLobbyOwner(lobby_id)
	
	for member in range(0, num_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		lobby_members.append({
				"steam_id": member_steam_id, 
				"steam_name": member_steam_name, 
				"is_owner": member_steam_id == lobby_owner,
		})
	is_host = lobby_owner == SteamGlobal.steam_id
	lobby_members_fetched.emit()


func find_lobby_member(p_steam_id: int) -> int:
	for lobby_member_idx in range(0, lobby_members.size()):
		var lobby_member: Dictionary = lobby_members[lobby_member_idx]
		if lobby_member.steam_id == p_steam_id:
			return lobby_member_idx
	return -1

func leave_lobby() -> void:
	# you're not in a lobby numbnuts
	if lobby_id == 0:
		return
	Steam.leaveLobby(lobby_id)
	lobby_id = 0
	
	lobby_members.clear()


func get_lobby_list_info() -> Array[LobbyInfo]:
	var res: Array[LobbyInfo] = []
	for lobby in lobbies:
		var lobby_info := LobbyInfo.new(Steam.getNumLobbyMembers(lobby), lobby)
		res.append(lobby_info)
	
	return res


func fetch_lobbies() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	print("fetching lobbies")
	Steam.requestLobbyList()


@rpc("call_local", "any_peer", "reliable")
func register_player(p_steam_id: int, p_num_players: int) -> void:
	print("Received %s players from client" % p_num_players)
	if p_num_players > 1:
		# decrease our lobby limit if we get multiple players connecting on one peer
		Steam.setLobbyMemberLimit(lobby_id, lobby_max - (p_num_players - 1))
	var id := multiplayer.get_remote_sender_id()
	GameState.add_remote_players(p_num_players, id)
	players[id] = p_steam_id
	client_register_player.rpc(GameState.players, p_steam_id, id)


@rpc("call_remote", "authority", "reliable")
func client_register_player(p_players_dict: Array[Dictionary], p_steam_id: int, p_peer_id: int) -> void:
	players[p_peer_id] = p_steam_id
	GameState.update_players(p_players_dict)


func unregister_player(p_peer_id: int):
	players.erase(p_peer_id)


func _on_multiplayer_peer_connected(id: int):
	if id == 1:
		#get_tree().get_first_node_in_group("main").set_multiplayer_authority(1)
		GameState.change_my_peer_id(multiplayer.get_unique_id())
		var local_active_players := GameState.players.filter(func(player_info): return player_info.is_active and player_info.peer_id == multiplayer.get_unique_id())
		print("Sending %s local actives to host" % local_active_players.size())
		register_player.rpc_id(id, SteamGlobal.steam_id, local_active_players.size())


func _on_multiplayer_peer_disconnected(id: int):
	unregister_player(id)


func _on_multiplayer_connection_failed():
	multiplayer.multiplayer_peer = null


func _on_lobby_created(p_connect: int, p_lobby_id: int) -> void:
	if p_connect != Steam.RESULT_OK:
		print("lobby failed to create? %s" % p_connect)
		return
	lobby_id = p_lobby_id
	print("Succesfully created a lobby: %s" % lobby_id)
	Steam.setLobbyJoinable(lobby_id, true)
	var set_relay: bool = Steam.allowP2PPacketRelay(true)
	print("Allowing Steam to be relay backup: %s" % set_relay)
	is_host = true
	Steam.setRichPresence("connect", str(p_lobby_id))
	var peer := SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	players[1] = SteamGlobal.steam_id
	lobby_created.emit()

 
func _on_lobby_join_requested(p_lobby_id: int, p_friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(p_friend_id)
	print("Joining %s's lobby..." % owner_name)
	join_lobby(p_lobby_id)
 

func _on_lobby_joined(p_lobby_id: int, _permissions: int, _locked: bool, p_response: int) -> void:
	if p_response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var fail_reason: String
		match p_response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."
		print("Failed to join lobby: %s" % fail_reason)
		return
	lobby_id = p_lobby_id
	#get_tree().get_first_node_in_group("main").change_to_scene(load("res://scenes/menus/multiplayer_lobby.tscn"))
	var owner_id := Steam.getLobbyOwner(p_lobby_id)
	if owner_id != SteamGlobal.steam_id:
		get_tree().get_first_node_in_group("main").remove_active_scene()
		var peer := SteamMultiplayerPeer.new()
		peer.create_client(owner_id, 0)
		multiplayer.set_multiplayer_peer(peer)
	lobby_joined.emit(owner_id)
	get_lobby_members()
	# TODO: force a scene transition somewhere to actually join the lobby


func _on_persona_change(p_steam_id: int, _flag: int) -> void:
	if lobby_id == 0:
		return
	print("A user (%s) had information change, updating the lobby list" % p_steam_id)
	get_lobby_members()


func _on_lobby_chat_update(p_lobby_id: int, p_change_id: int, p_making_change_id: int, p_chat_state: int) -> void:
	if p_lobby_id != lobby_id:
		print("bwuh, lobby chat update from %s which is not the lobby we're in (%s)" % [p_lobby_id, lobby_id])
	var changer_name: String = Steam.getFriendPersonaName(p_change_id)
	var changing_name: String = Steam.getFriendPersonaName(p_making_change_id)
	var output: String
	
	match p_chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED: output = "%s has joined the lobby." % changer_name
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT: output = "%s has left the lobby." % changer_name
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED: output = "%s has been kicked from the lobby by %s." % [changer_name, changing_name]
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED: output = "%s has been banned from the lobby by %s." % [changer_name, changing_name]
		_: output = "%s did something??" % changer_name
	print(output)
	
	get_lobby_members()


func _on_lobby_match_list(p_lobbies: Array) -> void:
	lobbies.clear()
	lobbies.append_array(p_lobbies)
	
	lobby_list_fetched.emit()


func _on_join_game_requested(_p_user_id: int, p_connect: String):
	if not p_connect.is_valid_int():
		print("Got a connect string (%s) that isn't a valid int" % p_connect)
		return
	var lobby_to_join_id: int = p_connect.to_int()
	join_lobby(lobby_to_join_id)

class LobbyInfo:
	var num_members: int
	var lobby_id: int
	# TODO: more info about our lobby
	func _init(p_num_members: int, p_lobby_id: int) -> void:
		self.num_members = p_num_members
		self.lobby_id = p_lobby_id


enum LobbyChatMessageType {
	CHAT,
	COMMAND
}
