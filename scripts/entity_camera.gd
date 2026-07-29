class_name EntityCamera
extends Marker3D

const OFFSET = Vector3(0.0, 0.35, 0.0)

@export var player: EntityPlayer

@export_group("References")
@export var camera: Camera3D

func _ready() -> void:
	if owner is EntityPlayer and owner.name == "Player" + NetworkManager.get_id():
		player = owner
		camera.current = true

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player):
		position = player.global_position + OFFSET
		basis = Basis.from_euler(InputManager.advanced_motion)
