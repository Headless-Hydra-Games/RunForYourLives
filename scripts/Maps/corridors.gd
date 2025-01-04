extends Level

@onready var grid_map = $GridMap

var enemies: Array[Entity] = []

func _ready():
	loading = true
	grid_map.client_count = client_count
	grid_map.generate()
	loading = false

# override register_enitity
func register_entity(entity: Entity):
	if entity is Player:
		entity.on_move.connect(_on_player_move)
	else:
		enemies.append(entity)

func _on_player_move(pos: Vector3):
	for enemy in enemies:
		enemy.on_player_move.rpc(pos)
