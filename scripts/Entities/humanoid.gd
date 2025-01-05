class_name humanoid extends Entity

const VIEW_DISTANCE = 5

@export var walk_speed = 5.0
@export var run_speed = 10.0
@export var move_acceleration = 50.0
@export var jump_acceleration = 4
@export var fall_acceleration = 9.8
@export var terminal_velocity = 53

@onready var pivot = $Pivot
@onready var mesh = $Pivot/Human
@onready var state_machine := StateMachine.new($Pivot/Human/AnimationPlayer)

var target_velocity = Vector3.ZERO
var running = false

var walking_anim_id: int
var idol_anim_id: int

var pursue = false
var move_to: Vector3

signal on_move(position: Vector3)

func _ready():
	if !multiplayer.is_server():
		return
	walking_anim_id = state_machine.append_state("Walking")
	idol_anim_id = state_machine.append_state("Idol")

func _physics_process(delta):
	if !multiplayer.is_server():
		return
	# account for gravity
	if !is_on_floor():
		target_velocity.y = clamp(target_velocity.y - fall_acceleration * delta, -terminal_velocity, jump_acceleration)
	else:
		var move_speed = run_speed if running else walk_speed
		if target_velocity.y < 0:
			target_velocity.y = 0
		
		pursue = pivot.global_position.distance_to(move_to) > .5
		if move_to.x != position.x || move_to.z != position.z:
			pivot.look_at(Vector3(move_to.x, position.y, move_to.z))
		var forward = pivot.global_basis * (Vector3.FORWARD if pursue else Vector3())
		var move_dir = forward.normalized()
		target_velocity = target_velocity.move_toward(move_dir * move_speed, move_acceleration * delta)
	
	if target_velocity != Vector3.ZERO:
		velocity = target_velocity
		playAnimation.rpc(walking_anim_id)
		move_and_slide()
		on_move.emit(position)
	else:
		playAnimation.rpc(idol_anim_id)

@rpc("call_local")
func playAnimation(animation_id: int):
	state_machine.change_state(animation_id)

@rpc("call_local")
func stopAnimation():
	state_machine.stop()

@rpc("call_local", "any_peer", "reliable")
func on_player_move(pos: Vector3):
	var direction_vector = pivot.global_position.direction_to(pos)
	if direction_vector.dot(pivot.global_basis * Vector3.FORWARD) > 0 && pivot.global_position.distance_to(pos) < VIEW_DISTANCE:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(global_position, pos)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result:
			if result.collider is Player:
				move_to = result.collider.global_position
				pursue = true
