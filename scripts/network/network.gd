extends Node

const LOBBY_TYPE := Steam.LobbyType.LOBBY_TYPE_FRIENDS_ONLY
const MAX_MEMBERS = 4

signal peer_created()

func _ready() -> void:
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_join_requested)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func host_lobby() -> void:
	Steam.createLobby(LOBBY_TYPE, MAX_MEMBERS)

func join_lobby(lobby_id: int) -> void:
	Steam.joinLobby(lobby_id)

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result == Steam.RESULT_OK:
		var peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		
		peer_created.emit()
		
		print(lobby_id)
		
		multiplayer.multiplayer_peer = peer

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		if Steam.getLobbyOwner(lobby_id) == Steam.getSteamID():
			return
		
		var peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_client(Steam.getLobbyOwner(lobby_id))
		
		peer_created.emit()
		
		multiplayer.multiplayer_peer = peer

func _on_join_requested(lobby_id: int, _steam_id: int) -> void:
	Steam.joinLobby(lobby_id)
