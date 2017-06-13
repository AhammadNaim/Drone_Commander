
const SQUA = 0
const HORZ = 1
const VERT = 2
const LARG = 3
const SMAL = 4

var formation = []
var type

func _init():
	pass
	



# calculates a formation
func SetFormation( formationtype, N ):
	type = formationtype
	formation = []
	var size_x
	var size_y
	if formationtype == SQUA:
		size_y = ceil( sqrt( N ) )
		size_x = ceil( N / size_y )
		for x in range( size_x ):
			for y in range( size_y ):
				formation.append( Vector2( size_x - x - 0.5 - size_x / 2, y - size_y / 2 + 0.5 ) )
				if formation.size() == N: break
			if formation.size() == N: break
	elif formationtype == VERT:
		size_y = max( 3.0, ceil( N / 60.0 ) )
		size_x = ceil( N / size_y )
		for x in range( size_x ):
			for y in range( size_y ):
				formation.append( Vector2( size_x - x - 0.5 - size_x / 2, y - size_y / 2 + 0.5 ) )
				if formation.size() == N: break
			if formation.size() == N: break
	elif formationtype == HORZ:
		size_x = max( 3.0, ceil( N / 60.0 ) )
		size_y = ceil( N / size_x )
		for x in range( size_x ):
			for y in range( size_y ):
				formation.append( Vector2( size_x - x - 0.5 - size_x / 2, y - size_y / 2 ) )
				if formation.size() == N: break
			if formation.size() == N: break
	elif formationtype == SMAL:
		size_y = max( 3.0, ceil( N / 60.0 ) )
		size_x = ceil( N / size_y )
		for x in range( size_x ):
			for y in range( size_y ):
				#var p = Vector2(  -x - abs( y - size_y / 2 ) / 2, y - size_y / 2 )
				var p = Vector2( x - size_x / 2, -y -abs( x - size_x / 2 ) / 2 )
				formation.append( p )
				if formation.size() == N: break
			if formation.size() == N: break
	elif formationtype == LARG:
		size_y = max( 3.0, ceil( N / 60.0 ) )
		size_x = ceil( N / size_y )
		for x in range( size_x ):
			for y in range( size_y ):
				#formation.append( Vector2( -x + abs( y - size_y / 2 ) / 2, y - size_y / 2 ) )
				formation.append( Vector2( x - size_x / 2, -y + abs( x - size_x / 2 ) / 2 ) )
				if formation.size() == N: break
			if formation.size() == N: break





func GetFormation( offset, angle, spacing = Vector2( 16, 16 ) ):
	var rf = []
	for idx in range( formation.size() ):
		rf.append( ( formation[idx] * spacing ).rotated( angle ) + offset )
	return rf

#func apply( angle = 0.0, offset = Vector2( 0, 0 ), spacing = Vector2( 16, 16 ), target = true ):
#	var rf = get_offset_formation( angle, offset, spacing )
#	if target:
#		for idx in range( elements.size() ):
#			#elements[idx].set_target_pos( ( formation[idx] * spacing ).rotated( angle ) + offset )
#			elements[idx].set_target_pos( rf[idx] )
#	else:
#		for idx in range( elements.size() ):
#			elements[idx].set_pos( ( formation[idx] * spacing ).rotated( angle ) + offset )











