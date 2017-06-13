

const LASER_RANGE = 150
const MAX_VELOCITY = 250
const GravConst = 10000

signal dead_drone
signal drone_collided
signal firing

var type
var parent
var texture
var pos = Vector2()
var vel = Vector2()
var steering = Vector2()
var area = RID()
var state = 0
var fire_state = 0
var time = 0
var frame = [ 0, 0 ]
var energy = 11
var fuel = 11
var target_path = []
var ControlNode
var planets = []
var modulate_color = Color( 1, 1, 1 )
var evt_time = 0
var evt_max = 5
var isevt = false
var sp1
var sp2
var on_camera = false

class FireSM:
	var state = 0
	var time = 0.0
	var timeinterval = 1.0
	var start_point = null
	var end_point = null
	var direction = null
	var target = null
	var frame = 0
var can_be_hit = true
var fire = FireSM.new()
var applied_forces = []



func process( delta ):
	if state == 0:
		_state_move( delta )
	elif state == 1:
		# started colliding
		# update frames
		time += delta
		if time > 0.1:
			time -= 0.1
			frame[1] += 1
			if frame[1] == 4:
				frame[1] = 3
				state = 2
	elif state == 2:
		# finished colliding
		Physics2DServer.free_rid( area )
		emit_signal( "dead_drone", self )
	
	# special events
	if isevt:
		evt_time += delta
		if evt_time >= evt_max:
			evt_time = 0
			isevt = false
			modulate_color = Color( 1, 1, 1 )





func _state_move( delta ):
	# set target position
	if target_path.empty():
		return
	var target_pos = target_path[0]
	# Calculate forces
	var f = Vector2( 0, 0 )
	# plannets
	for p in planets:
		var r = p.get_pos() - pos
		var rl2 = r.length_squared()
		#if rl2 > 25:
		f += r.normalized() / rl2 * p.mass * GravConst
	for a in applied_forces:
		f += a
	applied_forces = []
	# steering force
	var desired_velocity = target_pos - pos
	var distance = desired_velocity.length()
	if distance < 64 and target_path.size() == 1:
		desired_velocity = desired_velocity.normalized() * MAX_VELOCITY * ( distance / 64 )
		steering = ( desired_velocity - vel ) * 10
	else:
		desired_velocity = desired_velocity.normalized() * MAX_VELOCITY
		steering = ( desired_velocity - vel ) * 1
	if steering.length() > 3500:
		steering = steering.normalized() * 3500
	fuel -= 0.002 * steering.length() * delta
	if fuel <= 0:
		can_be_hit = false
		state = 1
		frame = [ 8, 0 ]
	f += steering
	# Calculate velocity
	vel += f * delta
	var velmod2 = vel.length_squared()
	if velmod2 > ( MAX_VELOCITY * MAX_VELOCITY ):
		vel = vel / velmod2 * MAX_VELOCITY * MAX_VELOCITY
	# Move
	set_pos( pos + vel * delta )
	# update path
	if distance < 64:
		if target_path.size() > 1:
			target_path.pop_front()
	
	# update frame
	time += delta
	if time > 0.1:
		time -= 0.1
		frame[0] = int( fmod( 180 - rad2deg( steering.angle() ) + 22.5, 360 ) / 45 )
		frame[1] = ( frame[1] + 1 ) % 4
	
	process_fire( delta )


func set_pos( p ):
	pos = p
	var mat = Matrix32()
	mat.o = pos
	Physics2DServer.area_set_transform( area, mat )

func set_target_path( path ):
	target_path = []
	for p in path:
		target_path.append( p )




func process_fire( delta ):
	# Firing state machine
	if fire.state == 0:
		fire.time += delta
		if fire.time >= fire.timeinterval:
			fire.time -= fire.timeinterval
			fire.timeinterval = rand_range( 0.25, 0.75 )
			var aux = ControlNode.CheckSpaceForEnemies( self, steering.normalized() )
			if aux != null:
				fire.state = 1
				fire.target = aux
	elif fire.state == 1:
		applied_forces.append( steering.normalized() * 10000 )
		fire.direction = ( fire.target.pos - pos ).normalized()
		fire.start_point = pos + fire.direction * 2 # TODO: Align this
		fire.end_point = fire.target.pos
		fire.time = 0
		fire.frame = 0
		fire.state = 2
		fire.target.hit()
		sp1.play( "drone_fire" )
		#emit_signal( "firing" )
	elif fire.state == 2:
		#print( "firing" )
		fire.time += delta
		if fire.time >= 0.05:
			fire.time -= 0.05
			if fire.frame < 3: fire.frame += 1
			fire.start_point += fire.direction * 80
			var diff = fire.end_point - fire.start_point
			if sign( diff.x ) != sign( fire.direction.x ):
				fire.start_point = fire.end_point
			if sign( diff.x ) != sign( fire.direction.x ) and fire.frame == 3:
				fire.state = 3
	elif fire.state == 3:
		#print( "finished firing" )
		fire.time = 0
		fire.state = 0
	return



func hit():
	if can_be_hit:
		#emit_signal( "is_hit" )
		energy -= 1
		if energy <= 0:
			if on_camera:
				sp2.play( "explosion" )
			can_be_hit = false
			state = 1
			frame = [ 8, 0 ]




func _on_collide( a, b, c, d, e ):
	if a == Physics2DServer.AREA_BODY_REMOVED:
		return
	if state != 1:
		emit_signal( "drone_collided", self )
	if on_camera:
		sp2.play( "explosion" )
	state = 1
	frame = [ 8, 0 ]
