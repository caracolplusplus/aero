extends Node

var initialized: bool = false

@onready var relay_to_game: MultiplayerAPI = get_tree().get_multiplayer()
@onready var relay_to_master: MultiplayerAPI = SceneMultiplayer.new()
@onready var args = OS.get_cmdline_args()

func _ready():
	get_tree().set_multiplayer(relay_to_master, get_path())
	
	if "--server" in args and "--game" in args:
		var index = args.find("--port") + 1
		var port = args[index].to_int()
		_run_as_game(port)

func _run_as_game(port: int) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, NetworkUtils.MAX_PLAYERS + 1)
	
	if error == OK:
		relay_to_game.multiplayer_peer = peer
		print("[Network] Multiplayer game server created.")
	
	peer = ENetMultiplayerPeer.new()
	error = peer.create_client("localhost", NetworkUtils.SERVER_PORT)
	
	if error == OK:
		relay_to_master.multiplayer_peer = peer
		
		await relay_to_master.connected_to_server
		relay_to_master.server_disconnected.connect(get_tree().quit)
		
		initialized = true
		
		print("[Network] Multiplayer game relay created.")

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
