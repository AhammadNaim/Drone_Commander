extends Control

onready var global = get_node( "/root/global" )

func _ready():
	get_tree().set_pause( false )
	global.main.change_song( "res://music/Juhani Junkala [Retro Game Music Pack] Title Screen.ogg", true )
	pass


func _on_intro_input_event( ev ):
	if ev.is_action_pressed( "left_click" ):
		#global.main.change_map( "res://tutorials/ending.tscn" )
		global.main.change_map( "res://tutorials/tutorial_1.tscn" )
