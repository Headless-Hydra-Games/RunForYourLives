@tool
extends Node3D

class_name GridRoom

enum Direction{NORTH, SOUTH, EAST, WEST}
enum ConnectionType{NORTH_WALL, SOUTH_WALL, EAST_WALL, WEST_WALL, CEILING, FLOOR}
enum ConnectionStatus{OPEN, CONNECTED, CLOSED}

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
	ConnectionType.NORTH_WALL: ConnectionStatus.OPEN,
	ConnectionType.SOUTH_WALL: ConnectionStatus.OPEN,
	ConnectionType.EAST_WALL: ConnectionStatus.OPEN,
	ConnectionType.WEST_WALL: ConnectionStatus.OPEN,
	ConnectionType.CEILING: ConnectionStatus.OPEN,
	ConnectionType.FLOOR: ConnectionStatus.OPEN
}

func create_room(room_size: Vector3):
	var floor_instance = null
	if floor_scenes[floor_index] != null:
		floor_instance = floor_scenes[floor_index].instantiate()
	
	var ceiling = null
	if ceiling_scenes[ceiling_index] != null:
		ceiling = ceiling_scenes[ceiling_index].instantiate()
	
	var north_wall = null
	if wall_scenes[north_wall_index] != null:
		north_wall = wall_scenes[north_wall_index].instantiate()
		north_wall.set_position(Vector3(0.0, 0.0, -1 * (room_size.z/2.0 -0.05)))
	
	var south_wall = null
	if wall_scenes[south_wall_index] != null:
		south_wall = wall_scenes[south_wall_index].instantiate()
		south_wall.set_position(Vector3(0.0, 0.0, room_size.z/2.0 -0.05))
	
	var east_wall = null
	if wall_scenes[east_wall_index] != null:
		east_wall = wall_scenes[east_wall_index].instantiate()
		east_wall.rotate_y(PI/2)
		east_wall.set_position(Vector3(room_size.x/2.0 -0.05, 0.0, 0.0))
	
	var west_wall = null
	if  wall_scenes[west_wall_index] != null:
		west_wall = wall_scenes[west_wall_index].instantiate()
		west_wall.rotate_y(PI/2)
		west_wall.set_position(Vector3(-1 * (room_size.x/2.0 -0.05), 0.0, 0.0))
	
	add_room_part(floor_instance)
	add_room_part(ceiling)
	add_room_part(north_wall)
	add_room_part(south_wall)
	add_room_part(east_wall)
	add_room_part(west_wall)

func CreateConnection(type: ConnectionType, room_part_index: int):
	connections[type] = ConnectionStatus.CONNECTED
	match type:
		ConnectionType.NORTH_WALL:
			north_wall_index = room_part_index
		ConnectionType.SOUTH_WALL:
			south_wall_index = room_part_index
		ConnectionType.EAST_WALL:
			east_wall_index = room_part_index
		ConnectionType.WEST_WALL:
			west_wall_index = room_part_index
		ConnectionType.FLOOR:
			floor_index = room_part_index
		ConnectionType.CEILING:
			ceiling_index = room_part_index

func get_rand_room_part_index(connection_type: ConnectionType):
	var scene_count = 0
	match connection_type:
		ConnectionType.NORTH_WALL:
			scene_count = wall_scenes.size()
		ConnectionType.SOUTH_WALL:
			scene_count = wall_scenes.size()
		ConnectionType.EAST_WALL:
			scene_count = wall_scenes.size()
		ConnectionType.WEST_WALL:
			scene_count = wall_scenes.size()
		ConnectionType.FLOOR:
			scene_count = floor_scenes.size()
		ConnectionType.CEILING:
			scene_count = ceiling_scenes.size()
	
	# Subtract one from the scene count and add one to the random number
	# to ignore first scene which is not a connection
	return randi() % (scene_count - 1) + 1

func add_room_part(part: Node3D):
	if part != null:
		add_child(part)
