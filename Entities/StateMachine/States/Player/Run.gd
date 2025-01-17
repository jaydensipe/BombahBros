extends PlayerState

# Virtual function. Corresponds to the `_process()` callback.
func _update_process(_delta: float) -> void:
	pass

# Virtual function. Corresponds to the `_physics_process()` callback.
func _update_physics_process(_delta: float) -> void:
	do_animations.rpc()
	
	var dir = Input.get_axis("Left", "Right")
	if dir != 0:
		player.velocity.x = lerp(player.velocity.x, dir * player.speed, player.acceleration)
	else:
		assigned_state_machine.transfer_to("Idle")
		
	if Input.is_action_just_pressed("Jump"):
		assigned_state_machine.transfer_to("Air", {Jump = true})
		
@rpc("call_local")
func do_animations() -> void:
	if (player.velocity.x > 70.0 or player.velocity.x < -70):
		player.walk_particles.set_deferred("emitting", true)	
				
	player.anim_tree.set("parameters/Movement/IdleRunBlend/blend_amount", 1.0)
	player.anim_tree.set("parameters/Movement/RunningTimeScale/scale", player.velocity.x * 0.06)
	
@rpc("call_local")
func cleanup_animations() -> void:
	player.walk_particles.set_deferred("emitting", false)
	
func play_walk_sound() -> void:
	if (player.is_on_floor()):
		player.walk_audio.play()

# Virtual function. Called by the state machine upon changing the active state. The `msg` parameter
# is a dictionary with arbitrary data the state can use to initialize itself.
func enter(_msg := {}) -> void:
	pass

# Virtual function. Called by the state machine before changing the active state. Use this function
# to clean up the state.
func exit() -> void:
	cleanup_animations.rpc()
	
