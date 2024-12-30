extends Level

const hallway = preload("res://Scenes/Maps/MapAssets/hallway.tscn")
const hallwayEnd = preload("res://Scenes/Maps/MapAssets/hallway_end.tscn")
const hallway3Way = preload("res://Scenes/Maps/MapAssets/hallway_junction_3_way.tscn")
const hallway4Way = preload("res://Scenes/Maps/MapAssets/hallway_junction_4_way.tscn")

const interval = 4
const north = PI
const south = 0
const east = PI/2
const west = PI * 3/2

enum Direction{NORTH, SOUTH, EAST, WEST}

@export var split_chance = 30.0
@export var max_halls_per_branch = 50
@export var max_branches = 100
@export var min_branches = 5

var current_branch_count = 0

func _ready():
	createAt(hallwayEnd, Vector3(0,0,0))
	generate(Vector3(0,0,1))

func get_direction_rotation(direction: Direction):
	match direction:
		Direction.NORTH:
			return north
		Direction.SOUTH:
			return south
		Direction.EAST:
			return east
		Direction.WEST:
			return west

func generate(pos: Vector3, total_halls_in_branch = 0, direction = Direction.NORTH):
	var scene = hallwayEnd
	var next_pos = pos
	match direction:
		Direction.NORTH:
			next_pos.z += 1
		Direction.SOUTH:
			next_pos.z -= 1
		Direction.EAST:
			next_pos.x -= 1
		Direction.WEST:
			next_pos.x += 1
	if total_halls_in_branch != max_halls_per_branch:
		if randf_range(0, 99) < split_chance and current_branch_count < max_branches:
			if randi_range(0,1) or current_branch_count > (max_branches - 2):
				current_branch_count += 1
				scene = hallway3Way
				generate(next_pos, total_halls_in_branch + 1, direction)
				next_pos = pos
				match direction:
					Direction.NORTH:
						next_pos.x -= 1
						generate(next_pos, 0, Direction.EAST)
					Direction.SOUTH:
						next_pos.x += 1
						generate(next_pos, 0, Direction.WEST)
					Direction.EAST:
						next_pos.z -= 1
						generate(next_pos, 0, Direction.SOUTH)
					Direction.WEST:
						next_pos.z += 1
						generate(next_pos, 0, Direction.NORTH)
			else:
				current_branch_count += 2
				scene = hallway4Way
				generate(next_pos, total_halls_in_branch + 1, direction)
				next_pos = pos
				match direction:
					Direction.NORTH:
						next_pos.x -= 1
						generate(next_pos, 0, Direction.EAST)
					Direction.SOUTH:
						next_pos.x += 1
						generate(next_pos, 0, Direction.WEST)
					Direction.EAST:
						next_pos.z -= 1
						generate(next_pos, 0, Direction.SOUTH)
					Direction.WEST:
						next_pos.z += 1
						generate(next_pos, 0, Direction.NORTH)
				next_pos = pos
				match direction:
					Direction.NORTH:
						next_pos.x += 1
						generate(next_pos, 0, Direction.WEST)
					Direction.SOUTH:
						next_pos.x -= 1
						generate(next_pos, 0, Direction.EAST)
					Direction.EAST:
						next_pos.z += 1
						generate(next_pos, 0, Direction.NORTH)
					Direction.WEST:
						next_pos.z -= 1
						generate(next_pos, 0, Direction.SOUTH)
		elif randf_range(0, 99) < 90 or current_branch_count < min_branches:
			scene = hallway
			generate(next_pos, total_halls_in_branch + 1, direction)
	
	createAt(scene, pos, get_direction_rotation(direction))

func createAt(scene: PackedScene, pos: Vector3, y_rotation = 0.0):
	var scene_instance = scene.instantiate()
	scene_instance.set_position(pos * interval)
	scene_instance.rotate_y(y_rotation)
	add_child(scene_instance)
