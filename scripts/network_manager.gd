extends Node

class Instance:
	var pid: int
	var host: int
	
	func _init(p_pid: int = -1, p_host: int = -1) -> void:
		pid = p_pid
		host = p_host

const SERVER_ADDRESS = "127.0.0.1"
const SERVER_PORT = 7777
const SERVER_PORT_START = 7778

const MAX_INSTANCES = 4
const MAX_PLAYERS = 8

var instances: Dictionary[int, Instance] = {} # port -> Instance

@onready var relay_to_game: MultiplayerAPI = get_tree().get_multiplayer()
@onready var relay_to_master: MultiplayerAPI = SceneMultiplayer.new()

@onready var args = OS.get_cmdline_args()

func _ready():
	get_tree().set_multiplayer(relay_to_master, get_path())
	
	if "--server" in args:
		if "--master" in args:
			_setup_upnp()
			_run_as_master()
		elif "--game" in args:
			_run_as_game()
	else:
		_run_as_client()

func _process(_delta: float) -> void:
	if "--server" in args:
		return

func _setup_upnp() -> void:
	var upnp = UPNP.new()
	var error = upnp.discover()
	
	if error == UPNP.UPNPResult.UPNP_RESULT_SUCCESS:
		var errors = []
		errors.append(upnp.add_port_mapping(SERVER_PORT, SERVER_PORT, "Master Server", "UDP"))
		
		for port in range(SERVER_PORT_START, SERVER_PORT_START + MAX_INSTANCES):
			errors.append(upnp.add_port_mapping(port, port, "Game Server", "UDP"))
			
			instances[port] = Instance.new()
		for e in errors:
			if e != UPNP.UPNPResult.UPNP_RESULT_SUCCESS:
				push_error("UPnP Error: ", e)
				return
		
		prints("[UPnP] Address:", upnp.get_gateway().query_external_address(), "Servers:", instances)

func _run_as_master() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(SERVER_PORT, MAX_INSTANCES * MAX_PLAYERS)
	
	if error == OK:
		relay_to_master.multiplayer_peer = peer
		
		relay_to_master.peer_disconnected.connect(destroy_instance)
		
		print("[Network] Multiplayer master peer created.")

func _run_as_game() -> void:
	var index = args.find("--port") + 1
	var port = args[index].to_int()
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS + 1)
	
	if error == OK:
		relay_to_game.multiplayer_peer = peer
		
		print("[Network] Multiplayer game server created.")
	
	peer = ENetMultiplayerPeer.new()
	error = peer.create_client("localhost", SERVER_PORT)
	
	if error == OK:
		relay_to_master.multiplayer_peer = peer
		
		await relay_to_master.connected_to_server
		
		relay_to_master.server_disconnected.connect(get_tree().quit)
		
		print("[Network] Multiplayer game relay created.")

func _run_as_client() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(SERVER_ADDRESS, SERVER_PORT)
	
	if error == OK:
		print("[Network] Trying to connect.")
		
		relay_to_master.multiplayer_peer = peer
		
		await relay_to_master.connected_to_server
		
		print("[Network] Multiplayer client relay created.")

func on_master_connect(callable: Callable) -> void:
	relay_to_master.connected_to_server.connect(callable)

func on_game_connect(callable: Callable) -> void:
	relay_to_game.connected_to_server.connect(callable)

func on_game_peer(entry: Callable, exit: Callable) -> void:
	if entry.is_valid():
		relay_to_game.peer_connected.connect(entry)
	
	if exit.is_valid():
		relay_to_game.peer_connected.connect(exit)

func is_master_online() -> bool:
	return relay_to_master.multiplayer_peer.get_connection_status() == ENetMultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED

func is_game_online() -> bool:
	return relay_to_game.multiplayer_peer.get_connection_status() == ENetMultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED

func is_master_server() -> bool:
	return "--server" in args and "--master" in args and relay_to_master.is_server()

func is_game_server() -> bool:
	return "--server" in args and "--game" in args and relay_to_game.is_server()

func is_guest() -> bool:
	return not is_master_server() and not is_game_server()

func is_authority(node: Node) -> bool:
	return node.is_multiplayer_authority()

func get_id() -> String:
	return str(relay_to_game.get_unique_id())

func set_authority(node: Node) -> void:
	node.set_multiplayer_authority(node.name.to_int())

func create_request() -> void:
	if not is_master_online() or not is_guest():
		return
	
	relay_to_master.rpc(1, self, "create_instance")

func destroy_request() -> void:
	if not is_master_online() or not is_guest():
		return
	
	relay_to_master.rpc(1, self, "destroy_instance", [0])

@rpc("any_peer", "call_remote", "reliable")
func create_instance() -> void:
	if not relay_to_master.is_server() or not "--master" in args:
		return
	
	var sender_id = relay_to_master.get_remote_sender_id()
	var port = -1
	
	for p_port in instances:
		var instance = instances[p_port]
		
		if port == -1 and instance.pid == -1:
			port = p_port
		
		if instance.host == sender_id:
			return
	
	if port == -1:
		return
	
	var p_args = [
		"--server",
		"--game",
		"--port", str(port),
		"--headless",
		"--remote-debug", "tcp://127.0.0.1:6007"
	]
	
	var pid = OS.create_instance(p_args)
	if pid > 0:
		prints("[Network] Launched game instance:", pid, ", Port:" , port)
		
		instances[port] = Instance.new(pid, sender_id)
		
		relay_to_master.rpc(sender_id, self, &"join_game", [port])
	else:
		push_error("[Network] Failed to launch game instance:", port)

@rpc("any_peer", "call_remote", "reliable")
func destroy_instance(client_id: int) -> void:
	if not relay_to_master.is_server() or not "--master" in args:
		return
	
	var sender_id = relay_to_master.get_remote_sender_id()
	
	if sender_id == 0:
		sender_id = client_id
	
	for p_port in instances:
		var instance = instances[p_port]
		
		if instance.host == sender_id:
			OS.kill(instance.pid)
			
			prints("[Network] Killed game instance:", instance.pid)
			
			instances[p_port] = Instance.new()
			
			return

@rpc("authority", "call_remote", "reliable")
func join_game(port: int) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(SERVER_ADDRESS, port)
	
	if error == OK:
		relay_to_game.multiplayer_peer = peer
		
		await relay_to_game.connected_to_server
		
		print("[Network] Multiplayer client joined a game server.")
