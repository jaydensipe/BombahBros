extends Character
class_name Bot

# Instances
@onready var anim_tree: AnimationTree = $Animation/AnimationTree
@onready var state_machine: StateMachine = $StateMachine
@onready var action_state_machine: StateMachine = $ActionStateMachine
@onready var body: Sprite2D = $Body
@onready var head: Sprite2D = $Body/Head
@onready var bomb_throw_location: Marker2D = $Body/BombSpawnPoint
@onready var walk_particles: GPUParticles2D = $VFX/WalkParticles
@onready var walk_audio: AudioStreamPlayer2D = $VFX/WalkAudio
@onready var forward_wall_detector: RayCast2D = $AI/ForwardWallDetector
@onready var backward_wall_detector: RayCast2D = $AI/BackwardWallDetector
@onready var navigation_agent: NavigationAgent2D = $AI/NavigationAgent2D
@onready var bomb_throw_timer: Timer = $Timers/BombThrowTimer
@onready var attempted_travel_point: NavPoint = null

# Configuration
@export var max_delay_between_throws: float = 2.0

func _ready() -> void:
	material.set_shader_parameter("line_color", Color.BLUE)
	debug_options()
	
func _physics_process(delta) -> void:
	move_player(delta)
	
func pick_random_nav_mesh_point() -> NavPoint: 
	if (attempted_travel_point):
		attempted_travel_point.attempting_to_travel = false
		
	var picked = GlobalGameInformation.get_current_game_information().current_map_nav_mesh.pick_random() as NavPoint
	picked.attempting_to_travel = true
	
	attempted_travel_point = picked
	
	return picked

func move_player(delta) -> void:
	# Apply gravity
	velocity.y += gravity * delta
	
	# Moving
	flip_body()
	move_and_slide()
	
func set_state(state_machine_name: NodePath, target_state_name: String, msg: Dictionary = {}):
	var selected_state_machine = get_node(state_machine_name) as StateMachine
	assert (state_machine != null)
		
	selected_state_machine.transfer_to(target_state_name, msg)

func flip_body() -> void:
	head.look_at(GlobalGameInformation.get_current_player().current_player.global_position)

	var direction = sign(GlobalGameInformation.get_current_player().current_player.global_position.x - global_position.x)
	if direction < 0:
		body.scale.x = -1
		walk_particles.process_material.direction = Vector3(20, -3, 0)
	else:
		body.scale.x = 1
		walk_particles.process_material.direction = Vector3(-20, -3, 0)
		
func debug_options():
	if (!is_multiplayer_authority()): return
	
	GlobalDebugMananger.add_debug_item(self, "name", true)
	GlobalDebugMananger.add_debug_item(self, "health")
	GlobalDebugMananger.add_debug_item(self, "position")
	GlobalDebugMananger.add_debug_item(self, "velocity")
	GlobalDebugMananger.add_debug_item(self, "ammo_count")
	GlobalDebugMananger.add_debug_item(self, "lives")
	GlobalDebugMananger.add_debug_item(state_machine, "state")
	GlobalDebugMananger.add_debug_item(action_state_machine, "state")

