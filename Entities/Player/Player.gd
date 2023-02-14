extends CharacterBody2D
class_name Player

# Player configuration
var health: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var vel: Vector2 = Vector2.ZERO
@export var throw_power: float = MAX_THROW_POWER
@export var speed: int = 150
@export var jump_height: int = -300
@export_range(0.0, 1.0) var friction: float = 0.1
@export_range(0.0 , 1.0) var acceleration: float = 0.25
@export_range(0.0 , 1.0) var air_acceleration: float = 0.05
@export var player_state: PLAYER_STATES = PLAYER_STATES.IDLE

const MAX_THROW_POWER = 150.0
enum PLAYER_STATES {IDLE, IN_AIR, ON_GROUND, THROWING}

# Instances
@onready var anim_tree = $Animation/AnimationTree
@onready var anim_state_machine: AnimationNodeStateMachinePlayback = $Animation/AnimationTree.get("parameters/playback")
@onready var body = $Body
@onready var head = $Body/Head
@onready var bomb_throw_location = $Body/BombSpawnPoint
@onready var walk_particles = $VFX/WalkParticles
@onready var aim_line = $VFX/AimLine

# Signals
signal taken_damage(damage_dealt)

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _process(delta):
	if (not is_multiplayer_authority()): return
	
	display_aim_line(delta)
	
func _physics_process(delta) -> void:
	if (not is_multiplayer_authority()): return
	
	move_player(delta)
	hold_throw()
	
func move_player(delta) -> void:
	# Floor detection
	if !is_on_floor():
		set_player_state.rpc(PLAYER_STATES.IN_AIR)
	else: 
		set_player_state.rpc(PLAYER_STATES.ON_GROUND)
		
	# Apply gravity
	velocity.y += gravity * delta
	vel.x = velocity.x
	flip_body()
	
	# Moving
	var dir = Input.get_axis("Left", "Right")
	
	if (player_state == PLAYER_STATES.IN_AIR):
		velocity.x = lerp(velocity.x, dir * speed, air_acceleration)
	elif dir != 0:
		velocity.x = lerp(velocity.x, dir * speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction)
		set_player_state.rpc(PLAYER_STATES.IDLE)
	
	move_and_slide()
	
	# Jumping
	if Input.is_action_just_pressed("Jump") and (player_state == PLAYER_STATES.ON_GROUND or player_state == PLAYER_STATES.IDLE):
		set_player_state.rpc(PLAYER_STATES.IN_AIR)
		velocity.y = jump_height

@rpc("any_peer", "call_local")
func take_damage(damage_dealt: float, damage_pos: Vector2) -> void:
	health += damage_dealt
	velocity += damage_pos * (-1 * health)

func hold_throw() -> void:
	if (Input.is_action_just_released("Hold_Attack")):
		GlobalSignals.signal_throw_bomb(bomb_throw_location.global_position, get_global_mouse_position(), throw_power)
		throw_power = MAX_THROW_POWER
		
	if (Input.is_action_pressed("Hold_Attack")):
		set_player_state.rpc(PLAYER_STATES.THROWING)
		
func flip_body() -> void:
	head.look_at(get_global_mouse_position())
	
	var direction = sign(get_global_mouse_position().x - global_position.x)
	if direction < 0:
		body.scale.x = -1
		walk_particles.process_material.direction = Vector3(20, -3, 0)
	else:
		body.scale.x = 1
		walk_particles.process_material.direction = Vector3(-20, -3, 0)
		
func display_aim_line(delta) -> void:
	if (player_state == PLAYER_STATES.THROWING):
		aim_line.show()
		update_trajectory(delta)
	else:
		aim_line.clear_points()
		
func update_trajectory(delta) -> void:
	aim_line.clear_points()
	
	var max_points = 250
	var pos = bomb_throw_location.position
	var arc_height = get_local_mouse_position().y - bomb_throw_location.position.y - throw_power
	
	arc_height = min(arc_height, -32)
	var local_vel = PhysicsUtil.calculate_arc_velocity(pos, get_local_mouse_position(), arc_height)
	for i in max_points:
		aim_line.add_point(pos)
		local_vel.y += gravity * delta
		pos += local_vel * delta
		
@rpc("call_local")
func set_player_state(new_state):	
	match new_state:
		PLAYER_STATES.IDLE: 
			walk_particles.set_deferred("emitting", false)	
			
			anim_state_machine.travel("Idle")
		PLAYER_STATES.IN_AIR: 
			walk_particles.set_deferred("emitting", false)	
			
			anim_tree.set("parameters/RunningAndSpinning/RunSpinBlend/blend_amount", 0.0)
		PLAYER_STATES.ON_GROUND: 
			walk_particles.set_deferred("emitting", true)	
			
			anim_state_machine.travel("RunningAndSpinning")
			anim_tree.set("parameters/RunningAndSpinning/RunTimeScale/scale", vel.x * 0.06)
			anim_tree.set("parameters/RunningAndSpinning/RunSpinBlend/blend_amount", 0.0)				
		PLAYER_STATES.THROWING: 
			throw_power = clampf(throw_power - 2.0, 0.0, MAX_THROW_POWER)
			anim_state_machine.travel("RunningAndSpinning")	
			anim_tree.set("parameters/RunningAndSpinning/SpinTimeScale/scale", (MAX_THROW_POWER + 1 - throw_power) * 0.1)
			anim_tree.set("parameters/RunningAndSpinning/RunSpinBlend/blend_amount", 1.0)	
		_:
			pass
			
	player_state = new_state
	
