extends HBoxContainer

var mouse_sensitivity_setting: float
func _ready() -> void:
	mouse_sensitivity_setting = ConfigFileHandler.load_key_settings("game", "mouse_sensitivity")
	$Slider.value = mouse_sensitivity_setting
	$Value.text = str("%.2f" % mouse_sensitivity_setting)

func _on_slider_value_changed(value: float) -> void:
	$Value.text = str("%.2f" % value)
	mouse_sensitivity_setting = value
	ConfigFileHandler.save_settings("game", "mouse_sensitivity", value)
