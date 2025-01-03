class_name Player extends Entity

@export var walk_speed = 5.0
@export var run_speed = 10.0
@export var move_acceleration = 50.0
@export var jump_acceleration = 4
@export var fall_acceleration = 9.8
@export var mouse_sensitivity = .01
@export var look_up_limit = 80
@export var look_down_limit = -80
@export var terminal_velocity = 53

@onready var camera = $Pivot/Camera3D
@onready var pivot = $Pivot
@onready var light = $Pivot/Camera3D/SpotLight3D
@onready var mesh = $Pivot/Human
@onready var state_machine := StateMachine.new($Pivot/Human/AnimationPlayer)

var player_tag: String

var target_velocity = Vector3.ZERO
var running = false

var walking_anim_id: int
var idol_anim_id: int

var paused = false

signal on_move(position: Vector3)

func _ready():
	walking_anim_id = state_machine.append_state("Walking")
	idol_anim_id = state_machine.append_state("Idol")

	if not is_multiplayer_authority(): return
	camera.current = true
	mesh.visible = false

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
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

func _input(event):
	if not is_multiplayer_authority(): return
	
	if !paused:
		if event is InputEventMouseMotion:
			pivot.global_rotate(Vector3.DOWN, event.relative.x * mouse_sensitivity)
			camera.rotate_object_local(Vector3.LEFT, event.relative.y * mouse_sensitivity)
			
			if camera.rotation_degrees.x > look_up_limit:
				camera.rotation_degrees.x = look_up_limit
			elif camera.rotation_degrees.x < look_down_limit:
				camera.rotation_degrees.x = look_down_limit
		
		if event.is_action_pressed("run"):
			running = true
		if event.is_action_released("run"):
			running = false
	
	if event.is_action_pressed("pause"):
		if paused:
			paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

@rpc("call_local")
func playAnimation(animation_id: int):
	state_machine.change_state(animation_id)

@rpc("call_local")
func stopAnimation():
	state_machine.stop()
