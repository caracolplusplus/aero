extends Node

enum Result {
	SOUTH,
	NORTH,
	DRAW
}

signal state_changed(state: String)

var fsm: FSM = FSM.new()

var _state: String = ""
var _timer: float = 0.0

var _team_south: Array[int] = []
var _team_north: Array[int] = []

var _round_number: int = 0
var _round_results: Array[Result] = []
var _team_south_score: int = 0
var _team_north_score: int = 0

var _finished: bool = false
var _winner: Result = Result.DRAW

var _ball: RigidBody3D
var _ball_origin: Vector3
var _spawn_south: Vector3 = Vector3.ZERO
var _spawn_north: Vector3 = Vector3.ZERO

@export var label: Label

@export_group("Win Conditions")
@export var max_rounds_to_win: int = 5
@export var round_differential: int = 2

@export_group("Durations")
@export var setup_time: float = 5.0
@export var loadout_time: float = 10.0
@export var round_time: float = 120.0
@export var round_end_time: float = 5.0
@export var match_end_time: float = 8.0

var _setup_state := FSM.State.new("Setup", _on_setup_enter, _on_setup_process)
var _loadout_state := FSM.State.new("Loadout", _on_loadout_enter, _on_loadout_process)
var _playing_state := FSM.State.new("Playing", _on_playing_enter, _on_playing_process)
var _round_end_state := FSM.State.new("RoundEnd", _on_round_end_enter, _on_round_end_process)
var _match_end_state := FSM.State.new("MatchEnd", _on_match_end_enter, _on_match_end_process)

func _ready() -> void:
	pass
	# TODO Call register scene on stage changes

func _process(delta: float) -> void:
	_update_debug_label()
	
	if not NetworkGame.initialized:
		return
	
	fsm.process_state(delta)

func get_state() -> String:
	return fsm.get_state()

func on_game_transition(callable: Callable) -> void:
	state_changed.connect(callable)
	callable.call(_state)

func _transition_to(state: FSM.State) -> void:
	fsm.transition_to(state)
	_state = fsm.get_state()
	state_changed.emit(_state)

func _set_timer(total: float) -> void:
	_timer = total

func _countdown_timer(delta: float, callback: Callable = Callable()) -> void:
	if _timer > 0.0:
		_timer -= delta
		return
	
	_timer = 0.0
	
	if callback.is_valid():
		callback.call()

func _assign_team(player_id: int) -> void:
	if not NetworkGame.initialized:
		return
	
	if _team_south.size() > _team_north.size():
		_team_north.append(player_id)
	else:
		_team_south.append(player_id)

func _clear_teams() -> void:
	_team_south.clear()
	_team_north.clear()

func _register() -> void:
	if not NetworkGame.initialized:
		return
	
	_transition_to(null)
	_clear_teams()
	
	if not _initialize_ball():
		return
	
	if not _initialize_spawn_points():
		return
	
	if not _initialize_score_areas():
		return
	
	start_game()

func _initialize_ball() -> bool:
	_ball = get_tree().get_first_node_in_group("Ball")
	
	if not is_instance_valid(_ball) or not (_ball is RigidBody3D):
		push_error("[Game] Ball not found or invalid type")
		return false
	
	_ball_origin = _ball.global_position
	return true

func _initialize_spawn_points() -> bool:
	var origin_south = get_tree().get_first_node_in_group("SpawnSouth")
	var origin_north = get_tree().get_first_node_in_group("SpawnNorth")
	
	if not is_instance_valid(origin_south) or not is_instance_valid(origin_north):
		push_error("[Game] Spawn points not found")
		return false
	
	_spawn_south = origin_south.global_position
	_spawn_north = origin_north.global_position
	return true

func _initialize_score_areas() -> bool:
	var areas_south = get_tree().get_nodes_in_group("AreaSouth")
	var areas_north = get_tree().get_nodes_in_group("AreaNorth")
	
	if areas_south.is_empty() or areas_north.is_empty():
		push_error("[Game] Score areas not found")
		return false
	
	_connect_score_areas(areas_south, _on_area_south_body_entered)
	_connect_score_areas(areas_north, _on_area_north_body_entered)
	return true

func _connect_score_areas(areas: Array, callback: Callable) -> void:
	for area in areas:
		if area is Area3D:
			area.body_entered.connect(callback)

func start_game() -> void:
	_round_number = 0
	_round_results.clear()
	
	_team_south_score = 0
	_team_north_score = 0
	
	_finished = false
	_winner = Result.DRAW
	_timer = 0.0
	
	_transition_to(_setup_state)

func _end_round(result: Result) -> void:
	if fsm.get_state() != "Playing" or _finished:
		return
	
	_round_number += 1
	_round_results.append(result)
	
	match result:
		Result.SOUTH:
			_team_south_score += 1
		Result.NORTH:
			_team_north_score += 1
		Result.DRAW:
			pass
	
	_transition_to(_round_end_state)

func _check_match_over() -> void:
	var differential = abs(_team_south_score - _team_north_score)
	prints("[Game] Match differential:", differential)
	
	var over := false
	if _team_north_score >= max_rounds_to_win:
		over = differential >= round_differential
	if _team_south_score >= max_rounds_to_win:
		over = differential >= round_differential
	
	if over:
		_transition_to(_match_end_state)
	else:
		_transition_to(_loadout_state)

func _on_area_south_body_entered(body: Node) -> void:
	if body == _ball and fsm.get_state() == "Playing":
		_end_round(Result.SOUTH)
		_ball.freeze = true

func _on_area_north_body_entered(body: Node) -> void:
	if body == _ball and fsm.get_state() == "Playing":
		_end_round(Result.NORTH)
		_ball.freeze = true

func _set_ball_state(position: Vector3, linear_velocity: Vector3, angular_velocity: Vector3, freeze: bool) -> void:
	if not is_instance_valid(_ball):
		return
	
	_ball.global_position = position
	_ball.linear_velocity = linear_velocity
	_ball.angular_velocity = angular_velocity
	_ball.freeze = freeze

func _on_setup_enter() -> void:
	_set_timer(setup_time)

func _on_setup_process(delta: float) -> void:
	_countdown_timer(delta, _transition_to.bind(_loadout_state))

func _on_loadout_enter() -> void:
	_set_timer(loadout_time)
	_set_ball_state(_ball_origin, Vector3.ZERO, Vector3.ZERO, true)

func _on_loadout_process(delta: float) -> void:
	_countdown_timer(delta, _transition_to.bind(_playing_state))

func _on_playing_enter() -> void:
	_set_timer(round_time)
	_set_ball_state(_ball_origin, Vector3.ZERO, Vector3.ZERO, false)

func _on_playing_process(delta: float) -> void:
	_countdown_timer(delta, _end_round.bind(Result.DRAW))
	_check_team_alive()

func _check_team_alive() -> void:
	if _team_south.is_empty() or _team_north.is_empty():
		return
	
	var players := get_tree().get_nodes_in_group("Player")
	
	var team_south_alive := 0
	var team_north_alive := 0
	
	for player in players:
		if not (player is EntityPlayer):
			continue
		
		if player.alive:
			match player.team:
				EntityPlayer.Team.SOUTH:
					team_south_alive += 1
				EntityPlayer.Team.NORTH:
					team_north_alive += 1
	
	if team_south_alive <= 0:
		_end_round(Result.NORTH)
	elif team_north_alive <= 0:
		_end_round(Result.SOUTH)

func _on_round_end_enter() -> void:
	_set_timer(round_end_time)

func _on_round_end_process(delta: float) -> void:
	_countdown_timer(delta, _check_match_over)

func _on_match_end_enter() -> void:
	_finished = true
	_winner = Result.DRAW
	
	if _team_south_score > _team_north_score:
		_winner = Result.SOUTH
	elif _team_north_score > _team_south_score:
		_winner = Result.NORTH
	
	_set_timer(match_end_time)

func _on_match_end_process(delta: float) -> void:
	_countdown_timer(delta, _transition_to.bind(null))

func _update_debug_label() -> void:
	if not NetworkClient.is_game_online():
		label.text = "[Offline]"
		return
	
	var result_keys := Result.keys()
	var results_str := str(_round_results.map(func(element): return result_keys[element]))
	
	label.text = "[Game]\n" + \
		"State: %s\n" % _state + \
		"Timer: %.1f\n" % _timer + \
		"Round: %d\n" % _round_number + \
		"Results: %s\n" % results_str + \
		"Score South: %d\n" % _team_south_score + \
		"Score North: %d\n" % _team_north_score + \
		"Finished: %s\n" % ("Yes" if _finished else "No") + \
		"Winner: %s" % result_keys[_winner]
