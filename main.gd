extends Node2D

onready var global = get_node( "/root/global" )
var state = 0
var cur_map = ""
onready var anim = get_node( "fadinglayer/AnimationPlayer" )
onready var mapnode = get_node( "map" )

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	change_map( "res://intro/intro.tscn" )
	#change_map( "res://level.tscn" )
	pass



func change_map( mapname ):
	# fade out
	anim.play( "fade_out" )
	yield( anim, "finished" )
	# clear existing map
	for c in mapnode.get_children():
		c.queue_free()
	# load new map
	print( mapname )
	var map = load( mapname ).instance()
	mapnode.add_child( map )
	#get_tree().set_pause( true )
	# fade in
	anim.play( "fade_in" )
	yield( anim, "finished" )
	# start
	#get_tree().set_pause( false )
	pass

onready var streamplayer = get_node( "StreamPlayer" )
func change_song( song, restart = true ):
	var newsong = load( song )
	if streamplayer.is_playing():
		if newsong == streamplayer.get_stream():
			if restart:
				get_node( "StreamPlayer/streamanim" ).play( "fade_out", -1, 1 )
				yield( get_node( "StreamPlayer/streamanim" ), "finished" )
				streamplayer.stop()
			else:
				return
		else:
			get_node( "StreamPlayer/streamanim" ).play( "fade_out", -1, 1 )
			yield( get_node( "StreamPlayer/streamanim" ), "finished" )
			streamplayer.stop()
	streamplayer.set_stream( newsong )
	get_node( "StreamPlayer" ).set_volume_db( 10.0 )
	streamplayer.play()
	
