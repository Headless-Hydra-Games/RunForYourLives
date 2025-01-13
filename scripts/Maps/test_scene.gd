extends Level

var enemies: Array[Entity] = []

func setup_level():
	spawn_enemy(0, Vector3(0,1,7))

# override register_enitity
func register_entity(entity: Entity):
	if entity is Player:
		entity.on_move.connect(_on_player_move)
	else:
		enemies.append(entity)

func _on_player_move(pos: Vector3):
	for enemy in enemies:
		enemy.on_player_move.rpc(pos)
