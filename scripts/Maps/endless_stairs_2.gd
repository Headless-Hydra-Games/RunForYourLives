extends Level

@export var stair_spacing = 3

@onready var stairs = $stairs
@onready var label = $AspectRatioContainer/Label
@onready var stairs_collection = $StairsCollection

const stairs_depth = 2.54
const stairs_height = 2.03

var stair_total = stair_spacing * 2 + 1
var center_stair = 0

func _ready():
	if stairs == null:
		print("stairs missing")
	else:
		start_level(Vector3(0,0,0))

func add_stairs(pos: Vector3):
	var stairs_dup = stairs.duplicate()
	stairs_dup.set_position(pos)
	stairs_collection.add_child(stairs_dup)

func start_level(pos: Vector3):
	# Remove any existing stairs
	for current_stairs in stairs_collection.get_children():
		stairs_collection.remove_child(current_stairs)
		current_stairs.queue_free()
	if stairs_collection.get_child_count() > 0:
		printerr("Stairs not successfully removed")
	
	# Add stairs
	var relative_stair_pos = pos.z / stairs_depth
	if relative_stair_pos < 0:
		relative_stair_pos -= 1
	if relative_stair_pos != center_stair:
		center_stair = int(relative_stair_pos)
	var stairs_number = center_stair - stair_spacing
	while stairs_number < stair_total:
		var set_pos = Vector3(0, stairs_height * -stairs_number, stairs_depth * stairs_number)
		stairs_number += 1
		add_stairs(set_pos)

func update_stairs(pos: Vector3):
	var relative_stair_pos = pos.z / stairs_depth
	if relative_stair_pos < 0:
		relative_stair_pos -= 1
	if relative_stair_pos != center_stair:
		center_stair = int(relative_stair_pos)
		var stairs_number = center_stair - stair_spacing
		var stairs_set = stairs_collection.get_children()
		for stairs_index in range(stairs_set.size()):
			var set_pos = Vector3(0, stairs_height * -stairs_number, stairs_depth * stairs_number)
			if set_pos != stairs_set[stairs_index].get_position():
				stairs_collection.get_children()[stairs_index].set_position(set_pos)
			stairs_number += 1

# override register_enitity
func register_entity(entity: Entity):
	if entity is Player:
		entity.on_move.connect(_on_player_move)

func _on_player_move(pos: Vector3):
	update_stairs(pos)
