extends Control
onready var global = get_node( "/root/global" )

signal player_move_to
signal player_dead
signal ai_dead
signal start_level

onready var camera = get_node( "player/camera" )
# camera.shake( 0.3, 10, 7 )

const click_scn = preload( "res://mouse/mouse_click.tscn" )
const Drone = preload( "res://drone/drone.gd" )



var drone_texture_rects = []
var laserhit_texture = preload( "res://drone/laserhit.png" )
var laserhit_texture_rects = []
var energybar = preload( "res://drone/energybar.png" )
const drone_laser_color = Color( 1, 1, 1 )
const ai_laser_color = Color( 1, 0, 1 )
const energy_color = Color( 1, 1, 1 )
const fuel_color = Color( 1, 0, 1 )
var laser_colors = [ drone_laser_color, ai_laser_color ]


var player = null
var ais = []
var drones = []
onready var planetgroup = get_node( "planetgroup" )
var planets = []



export( String, MULTILINE ) var nxt_level
export( String, MULTILINE ) var songname = ""

func _ready():
	if not songname.empty():
		global.main.change_song( songname, true )
	# create texture rectangles
	for y in range( 9 ):
		drone_texture_rects.append( [] )
		for x in range( 4 ):
			drone_texture_rects[-1].append( Rect2( 16 * Vector2( x, y ), Vector2( 16, 16 ) ) )
	# prepare laser hit textures
	for y in range( 4 ):
		laserhit_texture_rects.append( Rect2( y * Vector2( 0, 32 ), Vector2( 32, 32 ) ) )
	
	#get_tree().set_pause( true )
	yield( get_node( "anouncelayer/anounce" ), "click" )
	emit_signal( "start_level" )
	set_process( true )




func _on_level_input_event( ev, target_pos = get_global_mouse_pos() ):
	if ev.is_action_pressed( "left_click" ):
		emit_signal( "player_move_to", target_pos )
		var c = click_scn.instance()
		c.set_pos( target_pos )
		add_child( c )
	


func RegisterPlayer( n ):
	player = n
func RegisterAI( n ):
	ais.append( n )

func CreateDrone( parent, pos ):
	var d = Drone.new()
	var dronetype
	if parent == player:
		dronetype = 0
		d.texture = preload( "res://drone/drone.png" )
	else:
		dronetype = 1
		d.texture = preload( "res://drone/aidrone.png" )
	d.type = dronetype
	d.parent = parent
	if global == null:
		global = get_node( "/root/global" )
	d.sp1 = global.main.get_node( "SamplePlayer" )
	d.sp2 = global.main.get_node( "SamplePlayer2" )
	d.time = 0
	d.frame = [ 0, 0 ]
	d.area = Physics2DServer.area_create()
	Physics2DServer.area_set_space( d.area, get_world_2d().get_space() )
	var shape = Physics2DServer.shape_create( Physics2DServer.SHAPE_CIRCLE )
	Physics2DServer.shape_set_data( shape, 2 ) # Radius
	Physics2DServer.area_add_shape( d.area, shape )
	Physics2DServer.area_set_monitor_callback( d.area, d, "_on_collide" )
	d.set_pos( pos )
	d.ControlNode = self
	if planets.empty():
		planets = get_node( "planetgroup" ).get_children()
	d.planets = planets
	d.connect( "dead_drone", self, "_on_dead_drone" )
	d.connect( "firing", self, "_on_firing" )
	d.connect( "drone_collided", self, "_on_drone_collided" )
	drones.append( d )





func _process( delta ):
	if level_finished: return
	for d in drones:
		d.process( delta )
	update()


func _draw():
	var vt = camera.get_viewport_transform()
	var minx = -vt.o.x
	var maxx = minx + 768
	var miny = -vt.o.y
	var maxy = miny + 450
	
	for d in drones:
		if d.pos.x < minx or d.pos.x > maxx or d.pos.y < miny or d.pos.y > maxy:
			d.on_camera = false
			continue
		d.on_camera = true
		draw_texture_rect_region( d.texture, \
			Rect2( d.pos - Vector2( 8, 8 ), Vector2( 16, 16 ) ), drone_texture_rects[d.frame[0]][d.frame[1]], d.modulate_color )
		# energy
		draw_texture_rect_region( energybar, Rect2( d.pos + Vector2( -6, -10 ), Vector2( d.energy, 2 ) ), \
			Rect2( Vector2( 0, 0 ), Vector2( d.energy, 1 ) ), energy_color )
		# fuel
		draw_texture_rect_region( energybar, Rect2( d.pos + Vector2( -6, -8 ), Vector2( d.fuel, 2 ) ), \
			Rect2( Vector2( 0, 0 ), Vector2( d.fuel, 1 ) ), fuel_color )
	for d in drones:
		# laser
		if d.fire.state == 2:
			draw_line( d.fire.start_point, d.fire.end_point, laser_colors[ d.parent.Type ] )
			draw_texture_rect_region( laserhit_texture, \
				Rect2( d.fire.end_point - Vector2( 16, 16 ), Vector2( 32, 32 ) ), laserhit_texture_rects[d.fire.frame] )
	
	#debug
	#for d in drones:
	#	if d.parent.Type == 0:
	#		for idx in range( d.target_path.size() ):
	#			draw_circle( d.target_path[idx], 3, Color( 1, 0, 0, 0.5 ) )
	#			if idx == 0:
	#				draw_line( d.pos, d.target_path[idx], Color( 1, 0, 0, 0.5 ) )
	#			else:
	#				draw_line( d.target_path[idx-1], d.target_path[idx], Color( 1, 0, 0, 0.5 ) )

export( String, MULTILINE ) var complete_msg = "Wave\nComplete"
var level_finished = false
func _on_dead_drone( d ):
	if level_finished: return
	var parent = d.parent
	
	var dcount = GetDroneCount( parent )
	if dcount > 1:
		drones.remove( drones.find( d ) )
		d.parent.formation.SetFormation( d.parent.formation.type, dcount )
	else:
		if parent.Type == 0:
			# end game
			level_finished = true
			#set_process( false )
			
			var an = preload( "res://anounce/anounce.tscn" ).instance()
			an.msg = "Game\nOver"
			
			#get_node( "anouncelayer/Timer" ).start()
			#yield( get_node( "anouncelayer/Timer" ), "timeout" )
			get_node( "anouncelayer" ).add_child( an )
			
			get_tree().set_pause( true )
			yield( an, "click" )
			
			global.gamestate.player_pos = player.get_pos()
			global.gamestate.player_count = GetDroneCount( player )
			global.main.change_map( "res://intro/intro.tscn" )
		else:
			drones.remove( drones.find( d ) )
			# de-register ai
			emit_signal( "ai_dead", parent )
			ais.remove( ais.find( parent ) )
			if ais.empty():
				# win game
				level_finished = true
				var an = preload( "res://anounce/anounce.tscn" ).instance()
				an.msg = complete_msg
				
				#get_node( "anouncelayer/Timer" ).start()
				#yield( get_node( "anouncelayer/Timer" ), "timeout" )
				get_node( "anouncelayer" ).add_child( an )
				#get_tree().set_pause( true )
				yield( an, "click" )
				
				global.gamestate.player_pos = player.get_pos()
				global.gamestate.player_count = GetDroneCount( player )
				global.main.change_map( nxt_level )
				pass
		

func _on_drone_collided( d ):
	if d.parent.Type == 0:
		camera.shake( 0.3, 10, 7 )

func _on_firing( d ):
	print( "fire sound" )
	if d.parent.Type == 0:
		global.main.get_node( "SamplePlayer" ).play( "drone_fire" )













func GetDroneCount( n ):
	var count = 0
	for d in drones:
		if d.parent == n:
			count += 1
	return count


func GetAverageDronePos( n ):
	var pos = Vector2( 0, 0 )
	var count = 0
	for d in drones:
		if d.parent == n:
			pos += d.pos
			count += 1
	pos /= float( count )
	return pos


func GetDronePositions( n ):
	var dpos = []
	for d in drones:
		if d.parent == n:
			dpos.append( d.pos )
	return dpos


func ComputePath( startpos, endpos ):
	return get_node( "navigation" ).get_simple_path( startpos, endpos, true )

func SetDronePath( n, idx, path ):
	var counter = 0
	for d in drones:
		if d.parent == n:
			if counter == idx:
				d.set_target_path( path ) 
			counter += 1

func CheckSpaceForEnemies( drone, dir ):
	var enemydrones = []
	if drone.parent.Type == 0:
		for d in drones:
			if d.parent != drone.parent:
				enemydrones.append( d )
	else:
		for d in drones:
			if d.parent.Type == 0:
				enemydrones.append( d )
	if enemydrones.empty():
		return
	var rag = drone.LASER_RANGE
	# define triangle points
	var p1 = drone.pos
	var p2 = drone.pos + rag * dir.rotated( 22.5 * PI / 180 )
	var p3 = drone.pos + rag * dir.rotated( -22.5 * PI / 180 )
	# cycle enemies within the triangle
	var enemytarget = null
	var enemydistance = 10000000
	for e in enemydrones:
		if Geometry.point_is_inside_triangle( e.pos, p1, p2, p3 ):
			var curdist = ( e.pos - drone.pos ).length_squared()
			if curdist < enemydistance:
				enemydistance = curdist
				enemytarget = e
	return enemytarget



func ChargeDroneFuel():
	for d in drones:
		if d.parent.Type == 0:
			d.fuel = min( d.fuel + 5, 11 )
			d.evt_max = 0.5
			d.isevt = true
			d.modulate_color = Color( 1, 0, 1 )
			








