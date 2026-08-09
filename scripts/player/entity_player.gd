class_name EntityPlayer
extends CharacterBody3D

enum Team {
	SOUTH,
	NORTH,
	SPECTATOR
}

signal player_died()
signal player_respawned()

var fsm: FSM

var _motion: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.ZERO

var _turbo_active: bool = false
var _kick_charge: float = 0.0
var _kick_cooldown: float = 0.0
var _kick_boost: float = 0.0

var replicated_position: Vector3

@export var input: InputManager

@export var team: Team = Team.SPECTATOR
@export var alive: bool = true
@export var base_health: float = 250.0

@export_group("References")
@export var display: Node3D
@export var pivot: Marker3D
@export var collider: CollisionShape3D

@export_group("Movement")
@export var turn_blend_factor: float = 0.75
@export var turn_blend_speed: float = 0.35
@export var direction_blend_factor: float = 0.75
@export var direction_blend_speed: float = 0.25
@export var speed_blend_factor: float = 0.75
@export var speed_blend_speed: float = 0.25
@export var turbo_drain_rate: float = 30.0
@export var turbo_min: float = 30.0

@export var min_speed: float = 4.5
@export var max_speed: float = 25.0
@export var idle_speed_weight: float = 0.55

@export var reflection_strength: float = 0.8

@export_group("Kick")
@export var kick_charge_speed: float = 20.0
@export var kick_min_speed: float = 45.0
@export var kick_max_speed: float = 75.0
@export var kick_stamina_drain_rate: float = 40.0

@onready var health: float = base_health
@onready var stamina: float = 100.0

var _default_state = FSM.State.new("Default", Callable(), _on_default_state)
var _spectator_state = FSM.State.new("Spectator", _on_spectator_enter, _on_default_state, _on_spectator_exit)
var _static_state = FSM.State.new("Static", Callable(), _on_static_state)
var _game_state = FSM.State.new("Game", Callable(), _on_game_state)
var _dead_state = FSM.State.new("Dead", _on_dead_enter, _on_default_state, _on_dead_exit)

func _ready() -> void:
	if not multiplayer.is_server():
		return
	
	fsm = FSM.new()
	fsm.transition_to(_game_state)
	
	GameManager.on_game_transition(_on_game_state_changed)

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		fsm.process_state(delta)
		
		replicated_position = position
	else:
		position = replicated_position

@rpc("any_peer", "call_local", "reliable")
func damage(amount: float) -> void:
	if not multiplayer.is_server():
		return
	
	if fsm.get_state() != "Game":
		return
	
	health -= amount
	
	if health <= 0.0:
		fsm.transition_to(_dead_state)

func _on_game_state_changed(state: String) -> void:
	var offset_range = 5.0
	var offset = Vector3(
		randf_range(-offset_range / 2, offset_range / 2),
		randf_range(-offset_range / 2, offset_range / 2),
		randf_range(-offset_range / 2, offset_range / 2)
	)
	
	match state:
		"None", "Setup", "MatchEnd":
			fsm.transition_to(_default_state)
		"Loadout":
			var player_id = name.trim_prefix("Player").to_int()
			
			if GameManager._team_north.has(player_id):
				team = Team.NORTH
				print("[Players] Joining team NORTH.")
				position = GameManager._spawn_north + offset
			elif GameManager._team_south.has(player_id):
				team = Team.SOUTH
				print("[Players] Joining team SOUTH.")
				position = GameManager._spawn_south + offset
			else:
				team = Team.SPECTATOR
				fsm.transition_to(_spectator_state)
				return
			
			fsm.transition_to(_static_state)
		"Playing":
			if team == Team.SPECTATOR:
				fsm.transition_to(_spectator_state)
			else:
				fsm.transition_to(_game_state)

func _on_spectator_enter() -> void:
	_hide_player()

func _on_spectator_exit() -> void:
	_show_player()

func _on_default_state(_delta: float) -> void:
	_move_self_by_pivot()
	_transform_pivot()
	_copy_pivot()

func _on_static_state(delta: float) -> void:
	_transform_pivot()
	_transform_self(delta)
	velocity = Vector3.ZERO

func _on_game_state(delta: float) -> void:
	_kick_recovery(delta)
	_kick_process(delta)
	_move_self_by_self(delta)
	_transform_pivot()
	_transform_self(delta)

func _on_dead_enter() -> void:
	player_died.emit()
	alive = false
	_hide_player()

func _on_dead_exit() -> void:
	player_respawned.emit()
	alive = true
	health = base_health
	stamina = 100.0
	_kick_charge = 0.0
	_kick_boost = 0.0
	_show_player()

func _hide_player() -> void:
	display.visible = false
	collider.disabled = true

func _show_player() -> void:
	display.visible = true
	collider.disabled = false

func _transform_pivot() -> void:
	pivot.position = position + EntityCamera.OFFSET
	pivot.basis = Basis.from_euler(input.motion)

func _transform_self(delta: float) -> void:
	_motion.y = input.motion.y
	_motion.x = input.motion.x
	
	var base = _motion
	var direction = Vector3.ZERO
	
	if input.key_is_down("Up"):
		base.x = InputManager.PITCH_LIMIT
	if input.key_is_down("Down"):
		base.x = -InputManager.PITCH_LIMIT
	
	if input.key_is_down("Forward"):
		direction.z += 1.0
	if input.key_is_down("Backward"):
		direction.z -= 1.0
	if input.key_is_down("Left"):
		direction.x += 1.0
	if input.key_is_down("Right"):
		direction.x -= 1.0
	
	if input.key_is_down("Kick") or _kick_boost > kick_max_speed / 2.0:
		direction.z = 1.0
	
	if direction != Vector3.ZERO:
		_direction = direction
	
	base.y += Vector3.BACK.signed_angle_to(_direction.normalized(), Vector3.UP)
	
	basis = Commons.blend(basis, Basis.from_euler(base), turn_blend_factor, turn_blend_speed, delta)

func _copy_pivot() -> void:
	basis = pivot.basis

func _move_self_by_pivot() -> void:
	var direction = Vector3.ZERO
	
	if input.key_is_down("Forward"):
		direction.z += 1.0
	if input.key_is_down("Backward"):
		direction.z -= 1.0
	if input.key_is_down("Left"):
		direction.x += 1.0
	if input.key_is_down("Right"):
		direction.x -= 1.0
	
	var speed = min_speed
	velocity = pivot.basis * direction * speed
	
	var collided = move_and_slide()
	var collision = get_last_slide_collision()
	
	if collided and collision:
		var object = collision.get_collider()
		
		if object is RigidBody3D:
			object.apply_impulse(velocity * object.mass, collision.get_position() - object.global_position)

func _move_self_by_self(delta: float) -> void:
	var direction = basis.z
	var speed = min_speed
	
	if input.key_is_pressed("Turbo") and stamina > turbo_min:
		_turbo_active = true
	elif input.key_is_released("Turbo"):
		_turbo_active = false
	
	if _turbo_active and stamina > 0.0:
		speed = max_speed
		stamina = move_toward(stamina, 0.0, delta * turbo_drain_rate)
	elif not input.key_is_down("Kick"):
		speed = lerp(min_speed, max_speed, idle_speed_weight)
	
	if _kick_boost > 0.0:
		var camera = get_tree().get_first_node_in_group("Camera").camera as Camera3D
		var forward = -camera.global_basis.z
		var target = camera.global_position + forward * 5.0
		direction = position.direction_to(target)
		
		speed = max(speed, _kick_boost)
		_kick_boost = move_toward(_kick_boost, 0.0, delta * kick_max_speed)
	
	if velocity.length() > 1.0 and direction.length() > 0.1:
		var current_dir = velocity.normalized()
		var angle_diff = current_dir.angle_to(direction)
		
		if angle_diff > 0.5:
			var drag = 1.0 - (angle_diff / PI) * 0.3
			speed *= drag
	
	direction = Commons.blend(velocity.normalized(), direction, direction_blend_factor, direction_blend_speed, delta)
	speed = Commons.blend(velocity.length(), speed, speed_blend_factor, speed_blend_speed, delta)
	
	velocity = direction * speed
	
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var object = collision.get_collider()
		
		if object is RigidBody3D:
			if object.is_in_group("Ball"):
				health = min(base_health, health + 15)
			
			object.apply_impulse(velocity * object.mass, collision.get_position() - object.global_position)
		
		velocity = velocity.length() * velocity.normalized().bounce(collision.get_normal()) * reflection_strength

func _kick_recovery(delta: float) -> void:
	if _kick_cooldown > 0.0:
		_kick_cooldown -= delta
	elif _kick_charge == 0.0 and not _turbo_active:
		stamina = move_toward(stamina, 100.0, delta * 15.0)

func _kick_process(delta: float) -> void:
	var kick_input = input.key_is_down("Kick")
	
	if kick_input and not _kick_cooldown > 0.0 and stamina > 0.0:
		var previous_charge = _kick_charge if not is_zero_approx(_kick_charge) else kick_min_speed
		_kick_charge = clampf(_kick_charge + kick_charge_speed * delta, kick_min_speed, kick_max_speed)
		
		var charge_gained = _kick_charge - previous_charge
		
		if charge_gained > 0.0 and _kick_charge != kick_max_speed:
			var stamina_cost = charge_gained * kick_stamina_drain_rate / (kick_max_speed - kick_min_speed)
			stamina = max(0.0, stamina - stamina_cost)
		
		if stamina == 0.0:
			_kick_execute()
	else:
		if _kick_charge > 0.0 and (not kick_input or stamina == 0.0):
			_kick_execute()
		elif _kick_cooldown > 0.0:
			_kick_charge = 0.0

func _kick_execute() -> void:
	_kick_boost = _kick_charge
	_kick_cooldown = 0.5
	_kick_charge = 0.0
