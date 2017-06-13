extends Control

export(String, MULTILINE) var msg = "Manel"
signal click

func _ready():
	get_node( "Label" ).set_text( msg )


var timeout = false
func _on_anounce_input_event( ev ):
	if not timeout: return
	if ev.is_action_pressed( "left_click" ):
		get_tree().set_pause( false )
		emit_signal( "click" )
		queue_free()


func _on_Timer_timeout():
	timeout = true
