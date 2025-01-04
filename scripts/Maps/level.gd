extends Node3D

class_name Level

@export var enemy_scenes: Array[PackedScene] = []

var loading = false
var client_count: int

func register_entity(_enitity: Entity):
	pass

func spawn_enemy(enemy_index: int, pos: Vector3):
	var enemy = enemy_scenes[enemy_index].instantiate()
	enemy.set_position(pos)
	get_parent().add_child(enemy, true)

func is_loading():
	return loading
