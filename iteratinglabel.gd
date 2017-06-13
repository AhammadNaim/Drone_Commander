extends Label

export( String, MULTILINE ) var text = ""
export var speed = 0.1

func _ready():
	set_fixed_process( true )

var time = 0
var pos = 0
func _fixed_process(delta):
	time += delta
	if time > speed:
		time -= speed
		pos += 1
		if pos >= text.length():
			set_fixed_process( false )
			return
		set_text( text.substr( 0, pos ) )

