extends CharacterBody3D

class_name Entity

func _enter_tree():
	if self is Player:
		set_multiplayer_authority(str(name).to_int())
	
	var level = find_level()
	if level:
		level.register_entity(self)

func find_level():
	var parent = get_parent()
	while parent != get_tree().root:
		if parent is Level:
			return parent
		else:
			parent = parent.get_parent()
	return null
