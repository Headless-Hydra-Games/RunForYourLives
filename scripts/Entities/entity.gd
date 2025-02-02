extends CharacterBody3D

class_name Entity
enum EntitySize{LARGE, MEDIUM, SMALL}

var size_category: EntitySize = EntitySize.MEDIUM

const small_agent_radius = 0.25
const small_agent_height = 0.25
const medium_agent_radius = 0.25
const medium_agent_height = 1.75
const large_agent_radius = 1.0
const large_agent_height = 3.0

func _enter_tree():
	if self is Player:
		set_multiplayer_authority(str(name).to_int())
	
	set_size_category()
	
	var level = find_level()
	if level:
		level.register_entity(self)

func find_level() -> Level:
	var parent = get_parent()
	while parent != get_tree().root:
		if parent is Level:
			return parent
		else:
			parent = parent.get_parent()
	return null

func set_size_category() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if shape is CapsuleShape3D:
				if shape.radius <= small_agent_radius and shape.height <= small_agent_height:
					size_category = EntitySize.SMALL
				elif shape.radius <= medium_agent_radius and shape.height <= medium_agent_height:
					size_category = EntitySize.MEDIUM
				else:
					size_category = EntitySize.LARGE
			else:
				printerr("Invalid collision shape used for entity!")

func get_agent_height() -> float:
	var height = -1.0
	match size_category:
		EntitySize.SMALL:
			height = small_agent_height
		EntitySize.MEDIUM:
			height = medium_agent_height
		EntitySize.LARGE:
			height = large_agent_height
		_:
			printerr("Size category not found! No height to return")
	return height

func get_agent_radius() -> float:
	var radius = -1.0
	match size_category:
		EntitySize.SMALL:
			radius = small_agent_radius
		EntitySize.MEDIUM:
			radius = medium_agent_radius
		EntitySize.LARGE:
			radius = large_agent_radius
		_:
			printerr("Size category not found! No radius to return")
	return radius
