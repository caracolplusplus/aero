extends Control

const COMMON_RESOLUTIONS = [
	"3840x2160",
	"2560x1440",
	"1920x1080",
	"1366x768",
	"1280x720",
	"1440x900",
	"1600x900",
	"1024x600",
	"800x600"
]

var selected_resolution_idx
var config_resolution_setting

func _ready() -> void:
	config_resolution_setting = ConfigFileHandler.load_key_settings("video", "resolution")
	selected_resolution_idx = COMMON_RESOLUTIONS.find(config_resolution_setting)
	$Carousel/HBoxContainer/Label.text = COMMON_RESOLUTIONS[selected_resolution_idx]


func update_label_and_show_apply_button() -> void:
	var resolution_text = COMMON_RESOLUTIONS[selected_resolution_idx]
	$Carousel/HBoxContainer/Label.text = resolution_text
	if (resolution_text != config_resolution_setting):
		$Apply.show()
	else:
		$Apply.hide()
	

func _on_left_pressed() -> void:
	if (selected_resolution_idx > 0):
		selected_resolution_idx -= 1
	update_label_and_show_apply_button()


func _on_right_pressed() -> void:
	if (selected_resolution_idx < COMMON_RESOLUTIONS.size() - 1):
		selected_resolution_idx += 1
	update_label_and_show_apply_button()

func _on_apply_resolution() -> void:
	var resolution = COMMON_RESOLUTIONS[selected_resolution_idx]
	
	var resolution_split = resolution.split("x")
	var resolution_vector = Vector2i(int(resolution_split[0]), int(resolution_split[1]))
	get_window().set_size(resolution_vector)
	#center_window()
	ConfigFileHandler.save_settings("video", "resolution", resolution)
	config_resolution_setting = resolution
	
	$Apply.hide()

func center_window() -> void:
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(screen_center - window_size / 2)
