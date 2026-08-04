class_name FSM

class State:
	var id: String
	var on_enter: Callable
	var on_process: Callable
	var on_exit: Callable
	
	func _init(
		new_id: String = "",
		new_on_enter: Callable = Callable(),
		new_on_process: Callable = Callable(),
		new_on_exit: Callable = Callable()
	) -> void:
		id = new_id
		on_enter = new_on_enter
		on_process = new_on_process
		on_exit = new_on_exit

var _current_state: State = null

func get_state() -> String:
	return _current_state.id if _current_state else ""

func process_state(delta: float) -> void:
	if _current_state and _current_state.on_process.is_valid():
		_current_state.on_process.call(delta)

func transition_to(new_state: State) -> void:
	if _current_state and _current_state.on_exit.is_valid():
		_current_state.on_exit.call()
	
	_current_state = new_state
	
	if new_state and new_state.on_enter.is_valid():
		new_state.on_enter.call()
