extends Node

var initialized: bool = false

@onready var relay_to_master: MultiplayerAPI = SceneMultiplayer.new()
@onready var relay_to_game: MultiplayerAPI = get_tree().get_multiplayer()
@onready var args = OS.get_cmdline_args()

func _ready():
	get_tree().set_multiplayer(relay_to_master, get_path())
	
	if not "--server" in args:
		_run_as_client()

func _run_as_client() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(NetworkUtils.SERVER_ADDRESS, NetworkUtils.SERVER_PORT)
	
	if error == OK:
		print("[Network] Trying to connect.")
		
		relay_to_master.multiplayer_peer = peer
		await relay_to_master.connected_to_server
		
		initialized = true
		
		print("[Network] Multiplayer client relay created.")

@rpc("authority", "call_remote", "reliable")
func join_game(port: int) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(NetworkUtils.SERVER_ADDRESS, port)
	
	if error == OK:
		relay_to_game.multiplayer_peer = peer
		await relay_to_game.connected_to_server
		print("[Network] Multiplayer client joined a game server.")

func create_request() -> void:
	if not NetworkUtils.is_online(relay_to_master):
		return
	
	relay_to_master.rpc(1, NetworkMaster, &"create_instance")

func destroy_request() -> void:
	if not NetworkUtils.is_online(relay_to_master):
		return
	
	relay_to_master.rpc(1, NetworkMaster, &"destroy_instance", [0])

func on_master_connect(callable: Callable) -> void:
	NetworkUtils.on_connect(relay_to_master, callable)

func on_game_connect(callable: Callable) -> void:
	NetworkUtils.on_connect(relay_to_game, callable)

func on_game_peer(entry: Callable, exit: Callable) -> void:
	NetworkUtils.on_peer(relay_to_game, entry, exit)

func is_master_online() -> bool:
	return NetworkUtils.is_online(relay_to_master)

func is_game_online() -> bool:
	return NetworkUtils.is_online(relay_to_game)

func get_id() -> String:
	return str(NetworkUtils.get_unique_id(relay_to_game))

func is_authority(node: Node) -> bool:
	return NetworkUtils.is_authority(node)

func set_authority(node: Node) -> void:
	NetworkUtils.set_authority(node)
