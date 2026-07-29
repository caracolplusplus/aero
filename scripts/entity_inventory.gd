class_name EntityInventory
extends Marker3D

signal item_selected(index: int)

var items: Array[Node] = []
var active_index: int = -1
var money: int = 0

@export var player: EntityPlayer

@export_group("Inventory")
@export var max_slots: int = 4
@export var starting_money: int = 800

@export_group("UI")
@export var control: Control
@export var balance_label: Label
@export var status_label: Label

@onready var world: WorldManager = get_tree().get_nodes_in_group("Manager")[1]

func _ready() -> void:
	if owner is EntityPlayer and owner.name == "Player" + NetworkManager.get_id():
		player = owner
	
	if NetworkManager.is_game_server():
		GameManager.on_game_transition(_on_game_state_changed)
	
		for i in range(max_slots):
			items.append(null)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	balance_label.text = "Current Balance: $" + str(money)

func _physics_process(_delta: float) -> void:
	if NetworkManager.is_game_server():
		for i in range(1, 5):
			if player.input.key_is_pressed("Item" + str(i)):
				select_item(i - 1)
				break
	
	if not is_instance_valid(player):
		control.visible = false
		return
	
	# TODO Change input to ESC
	
	if GameManager.get_state() != "Loadout":
		control.visible = false
	elif .key_is_pressed("Buy"):
		control.visible = not control.visible

func select_item(index: int) -> void:
	if index < 0 or index == active_index or index >= items.size() or items[index] == null:
		return
	
	for i in items:
		if i != null and i.has_method("_deactivate"):
			i._deactivate()
	
	active_index = index
	
	if items[active_index].has_method("_activate"):
		items[active_index]._activate()
	
	item_selected.emit(index)

func add_item(item: Node) -> void:
	if not NetworkManager.is_game_server():
		return
	
	for i in range(items.size()):
		if items[i] == null:
			items[i] = item
			
			if active_index == -1:
				select_item(i)
			return

func remove_item(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	
	if items[index] != null:
		player.world.clear_item(items[index])
		items[index] = null
		
		if active_index == index:
			active_index = -1
			
			for i in range(items.size()):
				if items[i] != null:
					select_item(i)
					break

func clear_items() -> void:
	for i in range(items.size()):
		if items[i] != null:
			player.world.clear_item(items[i])
			items[i] = null
	active_index = -1

func _on_game_state_changed(state: String) -> void:
	print("[Inventory] On game state changed.")
	
	match state:
		"Loadout":
			_reset_money_for_round()
			clear_items()
			_give_base_item()
		"Setup", "MatchEnd":
			clear_items()

func _reset_money_for_round() -> void:
	if not NetworkManager.is_game_server():
		return
	
	# TODO Change up later
	
	var round_number = GameManager._round_number
	money = starting_money + (round_number * 500)
	prints("[Inventory] Money:", money)

func _deactivate_items() -> void:
	if active_index != -1 and items[active_index] != null:
		if items[active_index].has_method("_deactivate"):
			items[active_index]._deactivate()
	active_index = -1

func _give_base_item() -> void:
	var item = player.world.spawn_item("Wand")
	
	items[0] = item
	
	select_item(0)

func buy_item(item_index: String, price: int, slot: int = -1) -> void:
	if not NetworkManager.is_game_server():
		return
	
	if GameManager._state != "Loadout":
		return
	
	if money < price:
		status_label.text = "Insufficient money. Need: " + str(price) + " Have: " + str(money)
		return
	
	var target_slot = slot
	if target_slot == -1 or target_slot >= items.size():
		target_slot = -1
		for i in range(items.size()):
			if items[i] == null:
				target_slot = i
				break
		
		if target_slot == -1:
			status_label.text = "No empty slots available"
			return
	
	if items[target_slot] != null:
		status_label.text = "Slot " + str(target_slot) + " is already occupied"
		return
	
	var item = player.world.spawn_item(item_index)
	
	if item == null:
		status_label.text = "Failed to spawn item: " + item_index
		return
	
	money -= price
	status_label.text = "Purchased " + item.label_name + " for " + str(price)
	
	items[target_slot] = item
	
	select_item(target_slot)
