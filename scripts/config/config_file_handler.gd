extends Node

# Add new settings here
const DEFAULT_SETTINGS := {
	"game": {
		"mouse_sensitivity": 1.0,
		"fov": 85
	},
	"video": {
		"fullscreen": true,
		"resolution": "1280x720"
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 1.0,
		"sfx_volume": 1.0
	},
	"input": {
		"forward": "W",
		"left": "A",
		"right": "D",
		"back": "S",
		"up": "Space",
		"down": "Ctrl",
		"dash": "Shift",
		"shoot": "mouse_1",
		"ads": "mouse_2",
		"slot1": "E",
		"slot2": "Q"
	}
}

const SETTINGS_FILE_PATH = "user://settings.ini"

var config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		# creates default config file with default values
		for section in DEFAULT_SETTINGS:
			for setting in DEFAULT_SETTINGS[section]:
				config.set_value(section, setting, DEFAULT_SETTINGS[section][setting])
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)

###### LOADING ######
func get_keybinding_name(input_event: InputEvent) -> String:
	if input_event is InputEventMouseButton:
		return "mouse_%s" % input_event.button_index
	
	return OS.get_keycode_string(input_event.keycode)

func convert_keybinding_str_to_input_event(input_name: String) -> Variant:
	var input_event
	if input_name.contains("mouse_"):
		input_event = InputEventMouseButton.new()
		input_event.button_index = int(input_name.split("_")[1])
	else:
		input_event = InputEventKey.new()
		input_event.keycode = OS.find_keycode_from_string(input_name)
	return input_event


func load_settings(section: String) -> Dictionary[String, Variant]:
	var settings: Dictionary[String, Variant] = {}
	for key: String in DEFAULT_SETTINGS[section]:
		if config.get_value(section, key) == null:
			config.set_value(section, key, DEFAULT_SETTINGS[section][key])
			config.save(SETTINGS_FILE_PATH)
		var config_value = config.get_value(section, key)
		var value = config_value if section != "input" else convert_keybinding_str_to_input_event(config_value)
		settings[key] = value
	return settings

func load_key_settings(section: String, key: String) -> Variant:
	if !config.has_section_key(section, key):
		config.set_value(section, key, DEFAULT_SETTINGS[section][key])
		config.save(SETTINGS_FILE_PATH)
	var config_value = config.get_value(section, key)
	var value = config_value if section != "input" else convert_keybinding_str_to_input_event(config_value)
	return value

###### SAVING ######

func save_settings(section: String, key: String, value: Variant) -> void:
	if section == "input":
		save_keybindings(key, value)
	else:
		config.set_value(section, key, value)
		config.save(SETTINGS_FILE_PATH)

func save_keybindings(key: String, event: InputEvent) -> void:
	var event_str
	if event is InputEventKey:
		event_str = OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		event_str = "mouse_%s" % event.button_index

	config.set_value("input", key, event_str)
	config.save(SETTINGS_FILE_PATH)
