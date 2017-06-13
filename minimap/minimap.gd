extends Control


onready var mysize = get_size()
var areasize = null
#onready var planets = get_node( "../../planets" ).get_children()
const playerColor = Color( 1, 1, 1 )
const aiColor = Color( 1, 0, 1 )
var pixel = load( "res://pixel.png" )
onready var ControlNode = get_parent().get_parent()

class Planet:
	var pos
	var radius
var planets = []

func _ready():
	print( "minimap planets: ", ControlNode.planets )
	for p in ControlNode.planets:
		var pl = Planet.new()
		pl.pos = p.get_pos()
		pl.radius = p.get_node( "CollisionShape2D" ).get_shape().get_radius()
		planets.append( pl )
	pass


func _on_minimaptimer_timeout():
	if areasize == null:
		areasize = Vector2( ControlNode.camera.get_limit(2), ControlNode.camera.get_limit(3) )
	update()




func _draw():
	if areasize == null: return
	for p in planets:
		var pos = p.pos / areasize * mysize
		draw_circle( pos, p.radius / areasize.x * mysize.x, Color( 0, 1, 1 ) )
	
	for d in ControlNode.drones:
		var pos = d.pos / areasize * mysize
		if d.parent.Type == 0:
			draw_texture( pixel, pos, Color(1,1,1) )
		else:
			draw_texture( pixel, pos, Color(1,0,1) )
	
	pass

func _on_minimap_input_event( ev ):
	if ev.is_action_pressed( "left_click" ):
		var pos = get_local_mouse_pos() / mysize * areasize
		get_node( "../../player" )._on_player_input_event( ev, pos )
	pass # replace with function body
