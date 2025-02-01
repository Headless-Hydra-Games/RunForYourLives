extends Level

@onready var grid_map = $GridMap

var enemies: Array[Entity] = []

func _ready():
	super._ready()
	loading = true
	grid_map.generate(client_count)
	create_navigation_regions()
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
