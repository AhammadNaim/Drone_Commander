extends Area2D
onready var global = get_node( "/root/global" )
onready var ControlNode = get_parent().get_parent()

var target_path = []
var vel = Vector2()

func _ready():
	yield( ControlNode, "start_level" )
	set_fixed_process( true )

const MAX_VELOCITY = 50
var time = 0


var state = 0

func _fixed_process( delta ):
	if state == 0:
		time += delta
		if time > 1.0:
			time -= 1.0
			check_drones()
		_move( delta )
	elif state == 1:
		ControlNode.ChargeDroneFuel()
		get_node( "anim" ).play( "destroy" )
		global.main.get_node( "SamplePlayer2" ).play( "fuel" )
		state = 2
	elif state == 2:
		if not get_node( "anim" ).is_playing():
			state = 3
	elif state == 3:
		set_pos( Vector2( rand_range( ControlNode.camera.get_limit(0), ControlNode.camera.get_limit(2) ), \
				rand_range( ControlNode.camera.get_limit(1), ControlNode.camera.get_limit(3) ) ) )
		get_node( "anim" ).play( "cycle" )
		state = 0
	return
	
	
func _move( delta ):
	if not target_path.empty():
		var target_pos = target_path[0]
		# Calculate forces
		var steering = Vector2( 0, 0 )
		# steering force
		var desired_velocity = target_pos - get_pos()
		var distance = desired_velocity.length()
		if distance < 64 and target_path.size() == 1:
			desired_velocity = desired_velocity.normalized() * MAX_VELOCITY * ( distance / 64 )
			steering = ( desired_velocity - vel ) * 10
		else:
			desired_velocity = desired_velocity.normalized() * MAX_VELOCITY
			steering = ( desired_velocity - vel ) * 1
		steering += Vector2( randf() * 50, randf() * 50 )
		# Calculate velocity
		vel += steering * delta
		var velmod2 = vel.length_squared()
		if velmod2 > ( MAX_VELOCITY * MAX_VELOCITY ):
			vel = vel / velmod2 * MAX_VELOCITY * MAX_VELOCITY
		# Move
		set_pos( get_pos() + vel * delta )
		# update path
		if distance < 64:
			target_path.pop_front()
	else:
		var p = Vector2( rand_range( ControlNode.camera.get_limit(0), ControlNode.camera.get_limit(2) ), \
				rand_range( ControlNode.camera.get_limit(1), ControlNode.camera.get_limit(3) ) )
		var new_path = ControlNode.ComputePath( get_pos(), p )
		for p in new_path:
			target_path.append( p )



func check_drones():
	var curpos = get_pos()
	for d in ControlNode.drones:
		if d.parent.Type == 1:
			continue
		if ( d.pos - curpos ).length_squared() < 64:
			state = 1
			return
			#ControlNode.ChargeDroneFuel()
			#get_node( "anim" ).play( "destroy" )
			#yield( get_node( "anim" ), "finished" )
			#set_pos( Vector2( rand_range( ControlNode.camera.get_limit(0), ControlNode.camera.get_limit(2) ), -20 ) )
			#get_node( "anim" ).play( "cycle" )
			#return
			#pass

