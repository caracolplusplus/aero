class_name NetworkUtils
extends RefCounted

const SERVER_ADDRESS = "127.0.0.1"
const SERVER_PORT = 7777
const SERVER_PORT_START = 7778

const MAX_INSTANCES = 4
const MAX_PLAYERS = 8

class Instance:
	var pid: int
	var host: int
	
	func _init(p_pid: int = -1, p_host: int = -1) -> void:
		pid = p_pid
		host = p_host

static func is_online(multiplayer_api: MultiplayerAPI) -> bool:
	var peer = multiplayer_api.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == ENetMultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED

static func is_server(multiplayer_api: MultiplayerAPI) -> bool:
	return multiplayer_api.is_server()

static func on_connect(multiplayer_api: MultiplayerAPI, callable: Callable) -> void:
	multiplayer_api.connected_to_server.connect(callable)

static func on_peer(multiplayer_api: MultiplayerAPI, entry: Callable, exit: Callable) -> void:
	if entry.is_valid():
		multiplayer_api.peer_connected.connect(entry)
	if exit.is_valid():
		multiplayer_api.peer_disconnected.connect(exit)

static func get_unique_id(multiplayer_api: MultiplayerAPI) -> int:
	return multiplayer_api.get_unique_id()

static func is_authority(node: Node) -> bool:
	return node.is_multiplayer_authority()

static func set_authority(node: Node) -> void:
	node.set_multiplayer_authority(node.name.to_int())
