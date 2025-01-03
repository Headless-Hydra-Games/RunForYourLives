extends Level

@onready var grid_map = $GridMap

func _ready():
	grid_map.generate()
