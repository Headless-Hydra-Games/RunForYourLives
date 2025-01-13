extends Node3D

class_name Level

@export var enemy_scenes: Array[PackedScene] = []
@export var nav_region: NavigationRegion3D

@onready var player_client_spawner = MultiplayerSpawner.new()
@onready var enemy_client_spawner = MultiplayerSpawner.new()

var loading = false
var client_count: int

func _ready():
	player_client_spawner.set_spawn_path(get_path())
	player_client_spawner.add_spawnable_scene("res://Scenes/Entities/player.tscn")
	add_child(player_client_spawner)
	print("Added player MultiplayerSpawner")
	
	if nav_region != null:
		enemy_client_spawner.set_spawn_path(nav_region.get_path())
	for enemy_scene in enemy_scenes:
		enemy_client_spawner.add_spawnable_scene(enemy_scene.resource_path)
	add_child(enemy_client_spawner)
	
	# call setup for the level for any custom ready functionality
	setup_level()

func setup_level():
	pass

func register_entity(_entity: Entity):
	pass

func spawn_enemy(enemy_index: int, pos: Vector3):
	var enemy = enemy_scenes[enemy_index].instantiate()
	enemy.set_position(pos)
	nav_region.add_child(enemy, true)

func is_loading():
	return loading
