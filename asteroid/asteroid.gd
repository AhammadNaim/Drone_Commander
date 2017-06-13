extends KinematicBody2D

onready var ControlNode = get_parent().get_parent()

var target_path = []
var vel = Vector2()
var MAX_VELOCITY = 250
func _ready():
	yield( ControlNode, "start_level" )
	set_fixed_process( true )


var state = 0

func _fixed_process( delta ):
	if state == 0:
		_move( delta )
	elif state == 1:
		set_pos( Vector2( rand_range( ControlNode.camera.get_limit(0), ControlNode.camera.get_limit(2) ), \
				rand_range( ControlNode.camera.get_limit(1), ControlNode.camera.get_limit(3) ) ) )
		print( "new position: ", get_pos() )
		get_node( "anim" ).play( "cycle" )
		state = 0
	if ControlNode.level_finished: queue_free() #set_fixed_process( false )
	
	
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
		var startpos
		var endpos
		if randf() > 0.5:
			startpos = Vector2( -rand_range( 100, 2000 ), \
					round( rand_range( ControlNode.camera.get_limit(1), ControlNode.camera.get_limit(3) ) ) )
			endpos = Vector2( ControlNode.camera.get_limit(3) + 100, \
					round( rand_range( ControlNode.camera.get_limit(1), ControlNode.camera.get_limit(3) ) ) )
		else:
			startpos = Vector2( ControlNode.camera.get_limit(3) + rand_range( 100, 2000 ), \
					round( rand_range( ControlNode.camera.get_limit(1), ControlNode.camera.get_limit(3) ) ) )
			endpos = Vector2( -100, \
					round( rand_range( ControlNode.camera.get_limit(1), ControlNode.camera.get_limit(3) ) ) )
		var new_path = ControlNode.ComputePath( startpos, endpos )
		for p in new_path:
			target_path.append( p )
		MAX_VELOCITY = rand_range( 200, 300 )
		set_pos( startpos )



