extends Node2D
onready var global = get_node( "/root/global" )


export( int, 0, 1 ) var Type = 0
export( bool ) var preserve_state = false
export( int ) var Start_Drone_Count = 100
export( NodePath ) var Control_Node_Path = ""
export( int ) var Cycle_Interval = 1.0
var ControlNode = null
var Formation = preload( "res://drone/formation.gd" )
var tactic = ""
onready var formation = Formation.new()

const ATTACK_DISTANCE = 300
const ATTACK_RANGE = 150
const AI_PREDICTION_MAX_TIME = 2.0


var formation_angle = 0
var vel = Vector2()
var target_path = []
var ai_moving = false
var cycletime = 0.0

func _ready():
	if ControlNode == "": return
	ControlNode = get_node( Control_Node_Path )
	print( "======================= ", get_name(), " =======================" )
	print( "control node: ", ControlNode.get_name() )
	print( "type: ", Type )
	
	# register type with control
	if Type == 0:
		# Type Player
		ControlNode.RegisterPlayer( self )
		ControlNode.connect( "player_move_to", self, "_on_player_move_to" )
		if preserve_state:
			if global.gamestate.player_pos != null:
				Start_Drone_Count = global.gamestate.player_count
				set_pos( global.gamestate.player_pos )
	else:
		ControlNode.RegisterAI( self )
	ControlNode.connect( "player_dead", self, "_on_player_dead" )
	ControlNode.connect( "ai_dead", self, "_on_ai_dead" )
	
	# define initial formation
	print( "defining initial formation" )
	formation.SetFormation( Formation.SQUA, Start_Drone_Count )
	var cf = formation.GetFormation( get_pos(), formation_angle )
	# create initial set of drones
	print( "creating %d drones" % Start_Drone_Count )
	for idx in range( Start_Drone_Count ):
		ControlNode.CreateDrone( self, cf[ idx ] )
	
	# start process
	yield( ControlNode, "start_level" )
	set_fixed_process( true )

#-------------------------------------------------------------------
# Fixed Process
#-------------------------------------------------------------------
func _fixed_process( delta ):
	# update position and velocity
	var oldpos = get_pos()
	var newpos = ControlNode.GetAverageDronePos( self )
	set_pos( newpos )
	vel = ( newpos - oldpos ) / delta
	# manage ai path
	if Type == 1:
		if not target_path.empty():
			var distance = target_path[0] - newpos
			if distance.length() < 64:
				target_path.pop_front()
				if not target_path.empty():
					_on_player_move_to( target_path[0] )
		cycletime += delta
		if cycletime > Cycle_Interval:
			cycletime -= Cycle_Interval
			cycle()
	
#-------------------------------------------------------------------
# player move
#-------------------------------------------------------------------
func _on_player_move_to( target_pos ):
	# compute target formation
	var dir = target_pos - get_pos()
	if dir.length() > 0:
		formation_angle = dir.angle()
	var newformation = formation.GetFormation( target_pos, formation_angle )
	# compute target paths
	var startpositions = ControlNode.GetDronePositions( self )
	for idx in range( startpositions.size() ):
		var path = ControlNode.ComputePath( startpositions[idx], newformation[idx] )
		ControlNode.SetDronePath( self, idx, path )


#-------------------------------------------------------------------
# ai move
#-------------------------------------------------------------------
func cycle():
	var player = ControlNode.player
	var playerpos = player.get_pos()
	var aipos = get_pos()
	var movedir = Vector2()
	var dronecount = ControlNode.GetDroneCount( self )
	var avg_attack_range = ATTACK_RANGE / sqrt( dronecount ) * 4
	
	# future positions of the player
	var pdir = Vector2( sin( player.formation_angle ), cos( player.formation_angle ) )
	#print( pdir )
	var ppos = []
	for t in range( 1, AI_PREDICTION_MAX_TIME ):
		ppos.append( playerpos + float( t ) * player.vel )
	
	# compute intersept paths
	var min_flank_path = []
	var min_flank_path_len = 10000000000
	var min_frontal_path = []
	var min_frontal_path_len = 10000000000
	var min_direct_path = []
	var min_direct_path_len = 10000000000
	for p in ppos:
		# compute player path to this point
		var ppath = ControlNode.ComputePath( playerpos, p ) #nav.get_simple_path( playerpos, p, true )
		var plen = get_path_length( ppath )

		# compute player direction at the end of the path
		var pdir = ( ppath[-1] - ppath[-2] ).normalized()
		
		#=============================================================
		# calculate flanking attack
		#=============================================================
		# compute normals for flanking
		var pnorm = pdir.rotated( PI / 2 )
		var pnorm_2 = pdir.rotated( -PI / 2 )
		if ( aipos - p - pnorm_2 ).length_squared() < ( aipos - p - pnorm ).length_squared():
			pnorm = pnorm_2
		# compute flanking path
		var flank_path = ControlNode.ComputePath( aipos, p + ATTACK_DISTANCE * pnorm ) #nav.get_simple_path( aipos, p + ATTACK_DISTANCE * pnorm, true )
		flank_path.append_array( ControlNode.ComputePath( p + ATTACK_DISTANCE * pnorm, p + avg_attack_range * pnorm ) ) #nav.get_simple_path( p + ATTACK_DISTANCE * pnorm, p + avg_attack_range * pnorm,true ) )
		var flank_path_length = get_path_length( flank_path )
		if abs( flank_path_length - plen ) < 200 and flank_path_length < min_flank_path_len:
			min_flank_path_len = flank_path_length
			min_flank_path = []
			for x in flank_path:
				min_flank_path.append( x )
		
		#=============================================================
		# calculate frontal attack
		#=============================================================
		var frontal_path = ControlNode.ComputePath( aipos, p + pdir * ATTACK_DISTANCE ) #nav.get_simple_path( aipos, p + pdir * ATTACK_DISTANCE, true )
		frontal_path.append_array( ControlNode.ComputePath( p + pdir * ATTACK_DISTANCE, p + pdir * avg_attack_range ) ) #nav.get_simple_path( p + pdir * ATTACK_DISTANCE, p + pdir * avg_attack_range, true ) )
		var frontal_path_length = get_path_length( frontal_path )
		if abs( frontal_path_length - plen ) < 200 and frontal_path_length < min_frontal_path_len:
			min_frontal_path_len = frontal_path_length
			min_frontal_path = []
			for x in frontal_path:
				min_frontal_path.append( x )
		
		#=============================================================
		# calculate direct attack
		#=============================================================
		movedir = ( aipos - p ).normalized()
		var direct_path = ControlNode.ComputePath( aipos, p - movedir * avg_attack_range ) #nav.get_simple_path( aipos, p - movedir * avg_attack_range, true )
		var direct_path_length = get_path_length( direct_path )
		if abs( direct_path_length - plen ) < 200 and direct_path_length < min_direct_path_len:
			min_direct_path_len = direct_path_length
			min_direct_path = []
			for x in direct_path:
				min_direct_path.append( x )
		
	# No strategic path is available
	var final_path = []
	if min_flank_path.size() == 0 and min_frontal_path.size() == 0 and min_direct_path.size() == 0:
		final_path = ControlNode.ComputePath( aipos, playerpos + player.vel - movedir * avg_attack_range ) #nav.get_simple_path( aipos, playerpos + player.vel - movedir * avg_attack_range )
		tactic = "intercept"
	else:
		var flank_score = 0
		var frontal_score = 0
		var direct_score = 0
		if min_flank_path.size() > 0:
			flank_score += 12
			if formation.type == formation.HORZ:
				flank_score += 12
			if tactic == "flank":
				flank_score += 20
		if min_frontal_path.size() > 0:
			frontal_score += 8
			if formation.type == formation.SMAL:
				frontal_score += 8
			if tactic == "frontal":
				flank_score += 20
		if min_direct_path.size() > 0:
			direct_score += 6
			if formation.type == formation.SQUA:
				direct_score += 6
		#print( "Scores: ", flank_score, " ", frontal_score, " ", direct_score )
		if flank_score >= frontal_score and flank_score >= direct_score:
			tactic = "flank"
			target_path = min_flank_path
			formation.SetFormation( formation.HORZ, dronecount )
		elif frontal_score > flank_score and frontal_score >= direct_score:
			tactic = "frontal"
			target_path = min_frontal_path
			formation.SetFormation( formation.SMAL, dronecount )
		else:
			tactic = "direct"
			target_path = min_direct_path
			formation.SetFormation( formation.SQUA, dronecount )
	target_path = []
	for p in final_path:
		target_path.append( p )

	


func get_path_length( path ):
	var lenx = 0.0
	for idx in range( 1, path.size() ):
		lenx += ( path[idx-1] - path[idx] ).length()
	return lenx




func _on_player_dead():
	#set_fixed_process( false )
	#queue_free()
	return
	
	#

func _on_ai_dead( n ):
	if self == n:
		#set_fixed_process( false )
		queue_free()




