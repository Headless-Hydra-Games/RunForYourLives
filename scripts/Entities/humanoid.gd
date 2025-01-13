class_name humanoid extends Entity

const VIEW_DISTANCE = 8

@export var walk_speed = 5.0
@export var run_speed = 10.0
@export var move_acceleration = 50.0
@export var jump_acceleration = 4
@export var fall_acceleration = 9.8
@export var terminal_velocity = 53

@onready var nav_agent = $NavigationAgent3D
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
		
		if nav_agent.target_position.x != position.x || nav_agent.target_position.z != position.z:
			pivot.look_at(Vector3(nav_agent.target_position.x, position.y, nav_agent.target_position.z))
		var forward = Vector3() if nav_agent.is_navigation_finished() else nav_agent.get_next_path_position() - global_position
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
	# Get direction relative to self
	var direction_vector = pivot.global_position.direction_to(pos)
	
	# Check if player is within vision
	if direction_vector.dot(pivot.global_basis * Vector3.FORWARD) > 0 && \
	pivot.global_position.distance_to(pos) < VIEW_DISTANCE:
		# Check if obstacles are obscuring player
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(global_position, pos)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result:
			if result.collider is Player:
				nav_agent.target_position = result.collider.global_position
