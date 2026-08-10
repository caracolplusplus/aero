extends HBoxContainer

@export var bus_name: String
@export var config_volume_name: String

var bus_index: int

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	var saved_volume = ConfigFileHandler.load_key_settings("audio", config_volume_name)
	$Slider.value = saved_volume * 100
	$Value.text = str(int(saved_volume * 100))

func _on_slider_value_changed(value: float) -> void:
	$Value.text = str(int(value))
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))
	ConfigFileHandler.save_settings("audio", config_volume_name, value / 100.0)
