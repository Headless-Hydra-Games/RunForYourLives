extends Node

class_name State

var id: int
var anim_name: String
var anim_player: AnimationPlayer

func _init(state_id: int, animation_name: String, animation_player: AnimationPlayer):
	id = state_id
	anim_name = animation_name
	anim_player = animation_player

func play():
	anim_player.play(anim_name)

func stop():
	anim_player.stop()
