extends Control

export(String, MULTILINE) var nxt_scene = ""
export( String, MULTILINE ) var songname = "res://music/Juhani Junkala [Retro Game Music Pack] Level 1.ogg"
func _ready():
	global.main.change_song( songname, true )
	get_tree().set_pause( false )

func _on_tutorial_1_input_event( ev ):
	if ev.is_action_pressed( "left_click" ):
		global.main.change_map( nxt_scene )
