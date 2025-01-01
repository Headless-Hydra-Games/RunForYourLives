@tool
extends Node3D

class_name GridRoom

enum Direction{NORTH, SOUTH, EAST, WEST}
enum ConnectionType{NORTH_WALL, SOUTH_WALL, EAST_WALL, WEST_WALL, CEILING, FLOOR}

@export var floor_scenes: Array[PackedScene]:
	set(v):
		for scene in v:
			if scene != null:
				if scene.instantiate() is not Floor:
					push_error("PackedScene is not of type Floor")
					return
		floor_scenes = v

@export var wall_scenes: Array[PackedScene]:
	set(v):
		for scene in v:
			if scene != null:
				if scene.instantiate() is not Wall:
					push_error("PackedScene is not of type Wall")
					return
		wall_scenes = v

@export var ceiling_scenes: Array[PackedScene]:
	set(v):
		for scene in v:
			if scene != null:
				if scene.instantiate() is not Ceiling:
					push_error("PackedScene is not of type Ceiling")
					return
		ceiling_scenes = v

var floor_index = 0
var ceiling_index = 0
var north_wall_index = 0
var south_wall_index = 0
var east_wall_index = 0
var west_wall_index = 0

var connections = {
	ConnectionType.NORTH_WALL: false,
	ConnectionType.SOUTH_WALL: false,
	ConnectionType.EAST_WALL: false,
	ConnectionType.WEST_WALL: false,
	ConnectionType.CEILING: false,
	ConnectionType.FLOOR: false
}

func _ready():
	var floor_instance = null
	if floor_index < floor_scenes.size():
		floor_instance = floor_scenes[floor_index].instantiate()
	
	var ceiling = null
	if ceiling_index < ceiling_scenes.size():
		ceiling = ceiling_scenes[ceiling_index].instantiate()
	
	var north_wall = null
	if north_wall_index < wall_scenes.size():
		north_wall = wall_scenes[north_wall_index].instantiate()
		north_wall.set_position(Vector3(0.0, 0.0, -1.95))
	
	var south_wall = null
	if south_wall_index < wall_scenes.size():
		south_wall = wall_scenes[south_wall_index].instantiate()
		south_wall.set_position(Vector3(0.0, 0.0, 1.95))
	
	var east_wall = null
	if east_wall_index < wall_scenes.size():
		east_wall = wall_scenes[east_wall_index].instantiate()
		east_wall.rotate_y(PI/2)
		east_wall.set_position(Vector3(1.95, 0.0, 0.0))
	
	var west_wall = null
	if west_wall_index < wall_scenes.size():
		west_wall = wall_scenes[west_wall_index].instantiate()
		west_wall.rotate_y(PI/2)
		west_wall.set_position(Vector3(-1.95, 0.0, 0.0))
	
	add_room_part(floor_instance)
	add_room_part(ceiling)
	add_room_part(north_wall)
	add_room_part(south_wall)
	add_room_part(east_wall)
	add_room_part(west_wall)

func CreateConnection(type: ConnectionType):
	connections[type] = true
	match type:
		ConnectionType.NORTH_WALL:
			north_wall_index += 1
		ConnectionType.SOUTH_WALL:
			south_wall_index += 1
		ConnectionType.EAST_WALL:
			east_wall_index += 1
		ConnectionType.WEST_WALL:
			west_wall_index += 1
		ConnectionType.FLOOR:
			floor_index = 1
		ConnectionType.CEILING:
			ceiling_index = 1

func add_room_part(part: Node3D):
	if part != null:
		add_child(part)
