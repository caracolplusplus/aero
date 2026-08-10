extends HBoxContainer

@export var input_name: String

var is_remapping: bool = false

func _ready() -> void:
	var config_input_key = ConfigFileHandler.load_key_settings("input", input_name)
	$Button.text = ConfigFileHandler.get_keybinding_name(config_input_key)

func _input(event: InputEvent) -> void:
	if is_remapping:
		ConfigFileHandler.save_keybindings(input_name, event)
		$Button.text = OS.get_keycode_string(event.keycode)
		is_remapping = false

func _on_rebind_button_pressed() -> void:
	is_remapping = true
	if is_remapping:
		# translate this later
		$Button.text = "[Press any key]"
