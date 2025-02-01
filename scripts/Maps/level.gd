extends Node3D

class_name Level

class Agent_Size:
	var category: Entity.EntitySize
	var radius: float
	var height: float

@export var enemy_scenes: Array[PackedScene] = []
@export var nav_mesh_geometry_node: Node

@onready var player_client_spawner = MultiplayerSpawner.new()
@onready var enemy_client_spawner = MultiplayerSpawner.new()

var loading = false
var client_count: int

var agent_sizes: Array[Agent_Size] = []

func _ready():
	# setup player client spawner
	player_client_spawner.set_spawn_path(get_path())
	player_client_spawner.add_spawnable_scene("res://Scenes/Entities/player.tscn")
	add_child(player_client_spawner)
	print("Added player MultiplayerSpawner")
	
	# setup enemy client spawner
	enemy_client_spawner.set_spawn_path(get_path())
	for enemy_scene in enemy_scenes:
		enemy_client_spawner.add_spawnable_scene(enemy_scene.resource_path)
		
		if multiplayer.is_server():
			# Get all applicable sizes
			var enemy = enemy_scene.instantiate()
			add_agent_size(enemy.size_category, enemy.get_agent_radius(), enemy.get_agent_height())
			enemy.queue_free()
	add_child(enemy_client_spawner)

func add_agent_size(size: Entity.EntitySize, radius: float, height: float) -> void:
	# check if agent size already exists
	for agent_size in agent_sizes:
		if agent_size.category == size:
			return
	
	# Add agent size
	var agent_size = Agent_Size.new()
	agent_size.category = size
	agent_size.radius = radius
	agent_size.height = height
	agent_sizes.append(agent_size)

func create_navigation_regions() -> void:
	if !multiplayer.is_server():
		return
	if nav_mesh_geometry_node == null:
		printerr("No mesh to parse for navigation!")
		return
	
	var parsed = false
	var source_geometry_data: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	
	for agent_size in agent_sizes:
		var navigation_mesh: NavigationMesh = NavigationMesh.new()
		navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		# Get radius as a mulitple of cell_size
		var radius = navigation_mesh.cell_size * int(agent_size.radius / navigation_mesh.cell_size)
		# round up by cell_size
		if agent_size.radius > radius:
			radius += navigation_mesh.cell_size
		
		# Get height as a multiple of cell_height
		var height = navigation_mesh.cell_height * int(agent_size.height / navigation_mesh.cell_height)
		# round up by cell_height
		if agent_size.height > height:
			height += navigation_mesh.cell_height
			
		navigation_mesh.agent_radius = radius
		navigation_mesh.agent_height = height
		
		if !parsed:
			NavigationServer3D.parse_source_geometry_data(navigation_mesh, source_geometry_data, nav_mesh_geometry_node)
			parsed = true
		
		NavigationServer3D.bake_from_source_geometry_data(navigation_mesh, source_geometry_data)
		#var navigation_map: RID = NavigationServer3D.map_create()
		#NavigationServer3D.map_set_active(navigation_map, true)
		print("Total maps: %d" % NavigationServer3D.get_maps().size())
		var navigation_map: RID = NavigationServer3D.get_maps()[0]
		var navigation_region: RID = NavigationServer3D.region_create()
		var layers = NavigationServer3D.region_get_navigation_layers(navigation_region)
		# disable default layer
		NavigationServer3D.region_set_navigation_layers(navigation_region, layers & ~(1 << 1))
		#enable layer based on size
		NavigationServer3D.region_set_navigation_layers(navigation_region, layers | (1 << agent_size.category))
		print("Region nav layer %d" % layers)
		NavigationServer3D.region_set_map(navigation_region, navigation_map)
		NavigationServer3D.region_set_navigation_mesh(navigation_region, navigation_mesh)

func register_entity(_entity: Entity):
	pass

func spawn_enemy(enemy_index: int, pos: Vector3):
	var enemy = enemy_scenes[enemy_index].instantiate()
	enemy.set_position(pos)
	add_child(enemy, true)

func is_loading():
	return loading
