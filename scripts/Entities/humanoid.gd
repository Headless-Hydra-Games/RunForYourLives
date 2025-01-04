class_name humanoid extends Entity

const RAY_LENGTH = 50

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
		var direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var forward = pivot.global_basis * Vector3(direction.x, 0, direction.y)
		var move_dir = forward.normalized()
		target_velocity = target_velocity.move_toward(move_dir * move_speed * direction.length(), move_acceleration * delta)
		if Input.is_action_pressed("jump"):
			target_velocity.y += jump_acceleration
	
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
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, pos)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if result:
		if result.collider:
			print("Colliding with %s" % result.collider.name)
