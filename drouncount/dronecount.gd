extends Control

onready var ControlNode = get_parent().get_parent()

func _ready():
	get_node( "Label" ).set_text( "" )
	get_node( "Label 2" ).set_text( "" )
	set_fixed_process( true )

func _fixed_process(delta):
	var p = 0
	var a = 0
	for d in ControlNode.drones:
		if d.parent.Type == 0:
			p += 1
		else:
			a += 1
	get_node( "Label" ).set_text( "x%d" % p )
	get_node( "Label 2" ).set_text( "x%d" % a )
