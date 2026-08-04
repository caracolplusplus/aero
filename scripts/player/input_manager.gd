class_name InputManager
extends Node

enum InputState {
	PRESSED,
	DOWN,
	RELEASED,
	UP
}

const SENSITIVITY: float = deg_to_rad(0.1)
const PITCH_LIMIT: float = deg_to_rad(89.9)

static var advanced_actions: Dictionary
static var advanced_motion: Vector3

@export var actions: Dictionary = {}
@export var motion: Vector3 = Vector3.ZERO

func _enter_tree() -> void:
	NetworkClient.set_authority(self)

func _ready() -> void:
	if not NetworkClient.is_authority(self):
		return
	
	_construct_actions()
	
	process_physics_priority = 100

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if NetworkClient.is_authority(self):
			_release_all_inputs()

func _unhandled_input(event: InputEvent) -> void:
	if not NetworkClient.is_authority(self):
		return
	
	match event.get_class():
		"InputEventMouseMotion":
			_poll_mouse_motion(event)
		"InputEventKey":
			_poll_keyboard_action(event)
		"InputEventMouseButton":
			_poll_mouse_action(event)
		"InputEventJoypadMotion":
			_poll_joystick_action(event)
		_:
			return
	
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not NetworkClient.is_authority(self):
		return
	
	_update_cursor_mode()

func _physics_process(_delta: float) -> void:
	if not NetworkClient.is_authority(self):
		return
	
	_advance_actions()
	_advance_motion()

func _construct_actions() -> void:
	var default_action = {
		"keycode": "",
		"state": InputState.RELEASED
	}
	
	var definitions = {
		"Forward": {"keycode": "W"},
		"Backward": {"keycode": "S"},
		"Left": {"keycode": "A"},
		"Right": {"keycode": "D"},
		"Up": {"keycode": "Z"},
		"Down": {"keycode": "C"},
		"Kick": {"keycode": "Space"},
		"Turbo": {"keycode": "Shift"},
		"Fire": {"keycode": "Left Mouse Button"},
		"Alternate": {"keycode": "Right Mouse Button"},
		"Reload": {"keycode": "R"},
		"Buy": {"keycode": "B"}
	}
	
	for action_name in definitions:
		var action = default_action.duplicate()
		action.keycode = definitions[action_name].keycode
		actions[action_name] = action
	
	for i in range(1, 5):
		var action = default_action.duplicate()
		action.keycode = str(i)
		actions["Item" + str(i)] = action

func _poll_mouse_motion(event: InputEventMouseMotion) -> void:
	var relative = event.screen_relative * SENSITIVITY
	
	motion.x += relative.y
	motion.x = clampf(motion.x, -PITCH_LIMIT, PITCH_LIMIT)
	
	motion.y -= relative.x

func _poll_keyboard_action(event: InputEventKey) -> void:
	var keycode = OS.get_keycode_string(event.keycode)
	
	if event.is_echo():
		return
	
	for action_name in actions:
		var action = actions[action_name]
		if action.keycode == keycode:
			action.state = InputState.PRESSED if event.is_pressed() else InputState.RELEASED
			return

func _poll_mouse_action(event: InputEventMouseButton) -> void:
	var keycode = _get_mouse_button_keycode(event.button_index)
	
	if keycode.is_empty() or event.is_echo():
		return
	
	for action_name in actions:
		var action = actions[action_name]
		if action.keycode == keycode:
			action.state = InputState.PRESSED if event.is_pressed() else InputState.RELEASED
			return

func _poll_joystick_action(_event: InputEventJoypadMotion) -> void:
	# TODO: Implement joystick input handling
	pass

func _get_mouse_button_keycode(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "Left Mouse Button"
		MOUSE_BUTTON_RIGHT:
			return "Right Mouse Button"
		MOUSE_BUTTON_MIDDLE:
			return "Middle Mouse Button"
	
	return ""

func _update_cursor_mode() -> void:
	if OS.is_debug_build() and Input.is_action_pressed("lock"):
		_cursor_unlock()
	else:
		_cursor_lock()

func _cursor_lock() -> void:
	var menus = get_tree().get_nodes_in_group("Menu")
	
	for menu in menus:
		if menu.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _cursor_unlock() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _advance_actions() -> void:
	advanced_actions = actions
	
	for action_name in actions:
		var action = actions[action_name]
		
		match action.state:
			InputState.PRESSED:
				action.state = InputState.DOWN
			InputState.RELEASED:
				action.state = InputState.UP

func _advance_motion() -> void:
	advanced_motion = motion

func _release_all_inputs() -> void:
	for action_name in actions:
		actions[action_name].state = InputState.RELEASED

func key_is_pressed(key: String) -> bool:
	if not actions.has(key):
		return false
	
	return actions[key].state == InputState.PRESSED

func key_is_down(key: String) -> bool:
	if not actions.has(key):
		return false
	
	var state = actions[key].state
	return state == InputState.PRESSED or state == InputState.DOWN

func key_is_released(key: String) -> bool:
	if not actions.has(key):
		return false
	
	return actions[key].state == InputState.RELEASED

func key_is_up(key: String) -> bool:
	if not actions.has(key):
		return false
	
	var state = actions[key].state
	return state == InputState.RELEASED or state == InputState.UP
