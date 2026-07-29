class_name WorldManager
extends MultiplayerSpawner

var stage: Node

@export var input_scene: int
@export var player_scene: int
@export var stage_scenes: Dictionary[String, int]

@onready var world = get_node(spawn_path)
@onready var args = OS.get_cmdline_args()

func _ready() -> void:
	if NetworkManager.is_game_server():
		NetworkManager.on_master_connect(_spawn_stage.bind("Sandbox"))
		
		NetworkManager.on_game_peer(_spawn_player, Callable())

func _get_packed_scene(scene_index: int) -> PackedScene:
	var scene_path = get_spawnable_scene(scene_index)
	return load(scene_path)

func _spawn_stage(stage_index: String) -> void:
	if not NetworkManager.is_game_server() or not stage_index in stage_scenes:
		return
	
	if is_instance_valid(stage):
		stage.queue_free()
	
	stage = _get_packed_scene(stage_scenes[stage_index]).instantiate()
	
	get_node(spawn_path).add_child(stage)

func _spawn_player(player_id: int) -> void:
	if not NetworkManager.is_game_server():
		return
	
	var input = _get_packed_scene(input_scene).instantiate() as InputManager
	var player = _get_packed_scene(player_scene).instantiate() as EntityPlayer
	
	player.input = input
	
	input.name = str(player_id)
	player.name = "Player" + str(player_id)
	
	get_node(spawn_path).add_child(input)
	get_node(spawn_path).add_child(player, true)

func spawn_item(item_index: String) -> Node:
	return null

func clear_item(item: Node) -> void:
	pass
