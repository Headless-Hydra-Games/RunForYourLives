@tool
extends Node

class RoomMsg:
	
	func _init(room_scene_index: int = 0):
		room_index = room_scene_index
	
	var room_index = 0
	
	var position = Vector3(0, 0, 0)
	
	var connections = {
		GridRoom.ConnectionType.NORTH_WALL: [GridRoom.ConnectionStatus.OPEN, 0],
		GridRoom.ConnectionType.SOUTH_WALL: [GridRoom.ConnectionStatus.OPEN, 0],
		GridRoom.ConnectionType.EAST_WALL: [GridRoom.ConnectionStatus.OPEN, 0],
		GridRoom.ConnectionType.WEST_WALL: [GridRoom.ConnectionStatus.OPEN, 0],
		GridRoom.ConnectionType.CEILING: [GridRoom.ConnectionStatus.OPEN, 0],
		GridRoom.ConnectionType.FLOOR: [GridRoom.ConnectionStatus.OPEN, 0]
	}

@export var map_size = Vector3(10, 10, 10)
@export var room_size = Vector3(6, 2.6, 6)
@export_range(1, 100) var max_rooms: int = 20
@export_range(0, 100) var stair_occurrence: int = 10
@export_range(0, 100) var enemy_spawn_rate: int = 30

@export var room_scenes: Array[PackedScene] = []:
	set(v):
		for scene in v:
			if scene != null:
				if scene.instantiate() is not GridRoom:
					push_error("PackedScene is not of type GridRoom")
					return
		room_scenes = v

var client_respones: int = 0
var client_count: int

func generate():
	if multiplayer.is_server():
		var room_msgs = generate_rooms()
		for msg in room_msgs:
			SendRoomMsg(msg)
		while client_respones < (room_msgs.size() * client_count):
			await get_tree().create_timer(1).timeout

func SendRoomMsg(msg: RoomMsg):
	var data = {}
	data["scene_index"] = msg.room_index
	data["position_x"] = msg.position.x
	data["position_y"] = msg.position.y
	data["position_z"] = msg.position.z
	for connection in msg.connections:
		data[connection] = msg.connections[connection]
	create_room.rpc(data)

@rpc("call_local", "reliable")
func create_room(data: Dictionary):
	if multiplayer.get_remote_sender_id() == 1:
		var room = room_scenes[data["scene_index"]].instantiate()
		room.set_position(Vector3(data["position_x"], data["position_y"], data["position_z"]))
		for connection in room.connections:
			if data[connection][0] == GridRoom.ConnectionStatus.CONNECTED:
				room.CreateConnection(connection, data[connection][1])
			else:
				room.connections[connection] = data[connection][0]
		room.create_room(room_size)
		add_child(room)
		create_room_response.rpc()

@rpc("call_local", "any_peer")
func create_room_response():
	if multiplayer.is_server():
		client_respones += 1

func generate_rooms():
		var room_msgs: Array[RoomMsg] = []
		var starting_room = RoomMsg.new()
		starting_room.connections[GridRoom.ConnectionType.CEILING] = [GridRoom.ConnectionStatus.CLOSED, 0]
		starting_room.connections[GridRoom.ConnectionType.FLOOR] = [GridRoom.ConnectionStatus.CLOSED, 0]
		room_msgs.append(starting_room)
		recursive_room_creation(starting_room, room_msgs)
		return room_msgs

func recursive_room_creation(current_room: RoomMsg, room_msgs: Array[RoomMsg]):
	if room_msgs.size() >= max_rooms:
		return
	
	var connection = get_random_connection(get_valid_connections(current_room.connections))
	var new_pos = update_pos(current_room.position, connection)
	#var connection_index = current_room.get_rand_room_part_index(connection)
	var connection_index = room_scenes[current_room.room_index].instantiate().get_rand_room_part_index(connection)
	
	var next_room: RoomMsg
	
	# check if room exists at position. 
	# if so add a connection to that room otherwise add a new room
	var room_index = get_room_index_at(new_pos, room_msgs)
	if room_index > -1:
		# connect to room
		current_room.connections[connection] = [GridRoom.ConnectionStatus.CONNECTED, connection_index]
		room_msgs[room_index].connections[get_opposite_connection(connection)] = [GridRoom.ConnectionStatus.CONNECTED, connection_index]
		next_room = room_msgs[get_rand_valid_room_index(room_msgs)]
	else:
		# if new position is not in bounds set connection to closed so it will 
		# not register as a valid connection. Otherwise create new room
		if !in_map_bounds(new_pos):
			current_room.connections[connection] = [GridRoom.ConnectionStatus.CLOSED, 0]
			next_room = room_msgs[get_rand_valid_room_index(room_msgs)]
		else:
			# create new room
			var new_room = create_new_room_at(randi() % room_scenes.size(), new_pos)
			current_room.connections[connection] = [GridRoom.ConnectionStatus.CONNECTED, connection_index]
			new_room.connections[get_opposite_connection(connection)] = [GridRoom.ConnectionStatus.CONNECTED, connection_index]
			room_msgs.append(new_room)
			next_room = new_room
			if randi() % 100 < enemy_spawn_rate:
				get_parent().get_parent().spawn_enemy(0, new_pos)
	recursive_room_creation(next_room, room_msgs)

func has_open_connections(connections: Dictionary):
	for connection in connections:
		if connections[connection][0] == GridRoom.ConnectionStatus.OPEN:
			return true

func get_random_connection(connections: Array[GridRoom.ConnectionType]):
	var non_stair_connections: Array[GridRoom.ConnectionType]
	var stair_connections: Array[GridRoom.ConnectionType]
	
	for connection in connections:
		if connection == GridRoom.ConnectionType.FLOOR || connection == GridRoom.ConnectionType.CEILING:
			stair_connections.append(connection)
		else:
			non_stair_connections.append(connection)
	
	var stair_connection_count = stair_connections.size()
	var non_stair_connection_count = non_stair_connections.size()
	
	if stair_connection_count > 0:
		if (randi() % 100) < stair_occurrence || non_stair_connection_count == 0:
			return stair_connections[randi() % stair_connection_count]
	
	if non_stair_connection_count > 0:
		return non_stair_connections[randi() % non_stair_connection_count]
	
	return -1

func get_valid_connections(connections: Dictionary):
	var valid_connections: Array[GridRoom.ConnectionType]
	for connection in connections:
		if connections[connection][0] == GridRoom.ConnectionStatus.OPEN:
			valid_connections.append(connection)
	
	return valid_connections

func get_rand_valid_room_index(rooms: Array[RoomMsg]):
	var valid_room_indices: Array[int]
	var index = 0
	for room in rooms:
		if has_open_connections(room.connections):
			valid_room_indices.append(index)
		index += 1
	
	var valid_count = valid_room_indices.size()
	if valid_count:
		return valid_room_indices[randi() % valid_count]

func update_pos(pos: Vector3, connection_type: GridRoom.ConnectionType):
	match connection_type:
		GridRoom.ConnectionType.NORTH_WALL:
			pos.z -= room_size.z
		GridRoom.ConnectionType.SOUTH_WALL:
			pos.z += room_size.z
		GridRoom.ConnectionType.EAST_WALL:
			pos.x += room_size.x
		GridRoom.ConnectionType.WEST_WALL:
			pos.x -= room_size.x
		GridRoom.ConnectionType.CEILING:
			pos.y += room_size.y
		GridRoom.ConnectionType.FLOOR:
			pos.y -= room_size.y
	return pos

func get_room_index_at(pos: Vector3, rooms: Array[RoomMsg]):
	var index = 0
	for room in rooms:
		if room.position == pos:
			return index
		index += 1
	return -1

func create_new_room_at(room_index: int, pos: Vector3):
	var new_room_msg = RoomMsg.new(room_index)
	new_room_msg.position = pos
	return new_room_msg

func get_opposite_connection(connection_type: GridRoom.ConnectionType):
	match connection_type:
		GridRoom.ConnectionType.NORTH_WALL:
			return GridRoom.ConnectionType.SOUTH_WALL
		GridRoom.ConnectionType.SOUTH_WALL:
			return GridRoom.ConnectionType.NORTH_WALL
		GridRoom.ConnectionType.EAST_WALL:
			return GridRoom.ConnectionType.WEST_WALL
		GridRoom.ConnectionType.WEST_WALL:
			return GridRoom.ConnectionType.EAST_WALL
		GridRoom.ConnectionType.FLOOR:
			return GridRoom.ConnectionType.CEILING
		GridRoom.ConnectionType.CEILING:
			return GridRoom.ConnectionType.FLOOR

func in_map_bounds(pos: Vector3):
	var lower_bounds = -1.0 * (map_size/2.0) * room_size
	var upper_bounds = map_size/2.0 * room_size
	if pos.x < lower_bounds.x || pos.x > upper_bounds.x:
		return false
	elif pos.y < lower_bounds.y || pos.y > upper_bounds.y:
		return false
	elif pos.z < lower_bounds.z || pos.z > upper_bounds.z:
		return false
	else:
		return true
