extends OptionButton

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

func _ready() -> void:
	var config_resolution_setting = ConfigFileHandler.load_key_settings("video", "resolution")
	
	for resolution in COMMON_RESOLUTIONS:
		self.add_item(resolution)
	
	self.selected = COMMON_RESOLUTIONS.find(config_resolution_setting)


func _on_resolution_selected(index: int) -> void:
	var resolution = COMMON_RESOLUTIONS[index]
	
	var resolution_split = resolution.split("x")
	var resolution_vector = Vector2i(int(resolution_split[0]), int(resolution_split[1]))
	get_window().set_size(resolution_vector)
	#center_window()
	ConfigFileHandler.save_settings("video", "resolution", resolution)

func center_window() -> void:
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(screen_center - window_size / 2)
