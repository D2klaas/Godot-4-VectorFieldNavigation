extends RigidBody3D


var max_speed:float = 5 + randf_range(-2,2)
var vf_force:float = 80 + randf_range(-20,20)
var field:VFNField
var wiggle_force:float = 15
var vf_vec:Vector3
var just_teleported:bool = false
var occupied_field:VFNModField

func _ready():
	$Timer.wait_time = randf_range(0.5,1.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	## when a field is calculated
	if field:
		#comes later
#		occupied_field.add_value_from_world( global_position, 0.5 )
		#get the smoothed navigation vector for this position
		vf_vec = field.get_vector_smooth_world(global_position)*vf_force
		
		if vf_vec.length() > 0.1:# if vector points anywhere ... push in this direction
			vf_vec.y = -10
			apply_central_force( vf_vec )
		else: #if the vector is ZERO push randomly
			apply_impulse( Vector3(randf_range(-1,1), 0, randf_range(-1,1))*wiggle_force )
	
	if global_position.y < -100: #when falling from table ... reset
		global_position = Vector3(10,3,10)
	

func _integrate_forces(state):
	#limit the units speed
	state.linear_velocity = state.linear_velocity.limit_length( max_speed )


func _on_timer_timeout():
	# add some wiggily motion
	var v:Vector3
	v = vf_vec.normalized()
	var v2:Vector3
	v2.x = v.z
	v2.z = v.x
	v2 *= randf_range(-wiggle_force,wiggle_force)
	apply_impulse( v2 )
