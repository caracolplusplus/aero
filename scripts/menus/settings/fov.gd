extends HBoxContainer

var is_remapping = false

func _ready() -> void:
	var fov_value = ConfigFileHandler.load_key_settings("game", "fov")
	$Slider.value = fov_value
	$Value.text = str(int(fov_value))

func _on_slider_value_changed(value: float) -> void:
	$Value.text = str(int(value))
	ConfigFileHandler.save_settings("game", "fov", int(value))
