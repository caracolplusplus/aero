extends CheckBox

func _ready() -> void:
	var fullscreen = ConfigFileHandler.load_key_settings("video", "fullscreen")
	button_pressed = fullscreen

func _on_toggled(toggled_on: bool) -> void:
	var game_window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(game_window_mode)
	ConfigFileHandler.save_settings("video", "fullscreen", toggled_on)
