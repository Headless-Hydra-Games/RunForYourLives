@tool
extends Node

var level: Level
@export var level_scene: PackedScene:
	set(v):
		if v == null:
			level_scene = null
		else:
			var level_instance = v.instantiate()
			if level_instance is not Level:
				push_error("Resource is not of type Level")
			else:
				level_scene = v

const Player_instance = preload("res://Scenes/Entities/player.tscn")

func _ready():
	$MultiplayerManager.startBtn.pressed.connect(start_game.rpc)
	$MultiplayerManager.player_disconnected.connect(remove_player)

@rpc("call_local", "reliable")
func start_game():
	if multiplayer.get_remote_sender_id() == 1:
		level = level_scene.instantiate()
		level.client_count = $MultiplayerManager.player_list.size()
		add_child(level)
		while(level.is_loading()):
			pass
		spawn_player.rpc($MultiplayerManager.player_info)
		#level.label.text = "Player: " + $MultiplayerManager.player_info[$MultiplayerManager.player_attribute.NAME] 
		$MultiplayerManager.close_menu()

@rpc("call_local", "any_peer", "reliable")
func spawn_player(player_info: Dictionary):	
	if multiplayer.is_server():
		var player = Player_instance.instantiate()
		player.name = str(player_info[$MultiplayerManager.player_attribute.PEER_ID])
		add_child(player)

func remove_player(peer_id):
	var player_node = get_node_or_null(str(peer_id))
	if player_node:
		player_node.queue_free()
