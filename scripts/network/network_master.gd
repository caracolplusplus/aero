extends Node

var initialized: bool = false
var instances: Dictionary[int, NetworkUtils.Instance] = {}  # port -> Instance

@onready var relay_to_master: MultiplayerAPI = SceneMultiplayer.new()
@onready var args = OS.get_cmdline_args()

func _ready():
	get_tree().set_multiplayer(relay_to_master, get_path())
	
	if "--server" in args and "--master" in args:
		_setup_upnp()
		_run_as_master()

func _setup_upnp() -> void:
	var upnp = UPNP.new()
	var error = upnp.discover()
	
	if error == UPNP.UPNPResult.UPNP_RESULT_SUCCESS:
		var errors = []
		errors.append(upnp.add_port_mapping(NetworkUtils.SERVER_PORT, NetworkUtils.SERVER_PORT, "Master Server", "UDP"))
		
		for port in range(NetworkUtils.SERVER_PORT_START, NetworkUtils.SERVER_PORT_START + NetworkUtils.MAX_INSTANCES):
			errors.append(upnp.add_port_mapping(port, port, "Game Server", "UDP"))
			instances[port] = NetworkUtils.Instance.new()
		
		for e in errors:
			if e != UPNP.UPNPResult.UPNP_RESULT_SUCCESS:
				push_error("UPnP Error: ", e)
				return
		
		prints("[UPnP] Address:", upnp.get_gateway().query_external_address(), "Servers:", instances)

func _run_as_master() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(NetworkUtils.SERVER_PORT, NetworkUtils.MAX_INSTANCES * NetworkUtils.MAX_PLAYERS)
	
	if error == OK:
		relay_to_master.multiplayer_peer = peer
		relay_to_master.peer_disconnected.connect(destroy_instance)
		
		initialized = true
		
		print("[Network] Multiplayer master peer created.")

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
		
		instances[port] = NetworkUtils.Instance.new(pid, sender_id)
		
		relay_to_master.rpc(sender_id, NetworkClient, &"join_game", [port])
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
			
			instances[p_port] = NetworkUtils.Instance.new()
			
			return
