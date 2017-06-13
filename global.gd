extends Node

var main = null
var Debug = true

class State:
	var player_count
	var player_pos
var gamestate = State.new()


func _ready():
	# random stuff
	randomize()
	
	set_pause_mode( 1 )
	
	# main scene
	var _root = get_tree().get_root()
	main = _root.get_child( _root.get_child_count() - 1 )
	
	# center screen
	var screen_size = OS.get_screen_size( 0 )
	var window_size = OS.get_window_size()
	OS.set_window_position( screen_size * 0.5 - window_size * 0.5 )
	
	# start process
	set_process( true )


func _process( delta ):
	# hit Esc to quit
	if Input.is_key_pressed( KEY_ESCAPE ):
		get_tree().quit()
	


