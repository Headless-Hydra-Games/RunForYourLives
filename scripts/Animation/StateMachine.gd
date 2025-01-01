extends Node

class_name StateMachine

var states: Array[State]
var current_state_id = -1
var anim_player: AnimationPlayer

func _init(animation_player: AnimationPlayer):
	anim_player = animation_player

func append_state(animation_name: String):
	var state = State.new(states.size(), animation_name, anim_player)
	states.append(state)
	return state.id

func change_state(id: int):
	if current_state_id != id and id < states.size():
		states[id].play()
		current_state_id = id

func play():
	states[current_state_id].play()

func stop():
	states[current_state_id].stop()
