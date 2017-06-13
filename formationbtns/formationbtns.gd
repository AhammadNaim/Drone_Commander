extends ButtonGroup

onready var ControlNode = get_parent().get_parent()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#square
func _on_TextureButton_pressed():
	var dronecount = ControlNode.GetDroneCount( ControlNode.player )
	ControlNode.player.formation.SetFormation( ControlNode.player.formation.SQUA, dronecount )
	if ControlNode.player.vel.length() == 0:
		ControlNode.player._on_player_move_to( ControlNode.player.get_pos() )


func _on_TextureButton1_pressed():
	var dronecount = ControlNode.GetDroneCount( ControlNode.player )
	ControlNode.player.formation.SetFormation( ControlNode.player.formation.HORZ, dronecount )
	if ControlNode.player.vel.length() == 0:
		ControlNode.player._on_player_move_to( ControlNode.player.get_pos() )


func _on_TextureButton2_pressed():
	var dronecount = ControlNode.GetDroneCount( ControlNode.player )
	ControlNode.player.formation.SetFormation( ControlNode.player.formation.VERT, dronecount )
	if ControlNode.player.vel.length() == 0:
		ControlNode.player._on_player_move_to( ControlNode.player.get_pos() )


func _on_TextureButton3_pressed():
	var dronecount = ControlNode.GetDroneCount( ControlNode.player )
	ControlNode.player.formation.SetFormation( ControlNode.player.formation.SMAL, dronecount )
	if ControlNode.player.vel.length() == 0:
		ControlNode.player._on_player_move_to( ControlNode.player.get_pos() )


func _on_TextureButton4_pressed():
	var dronecount = ControlNode.GetDroneCount( ControlNode.player )
	ControlNode.player.formation.SetFormation( ControlNode.player.formation.LARG, dronecount )
	if ControlNode.player.vel.length() == 0:
		ControlNode.player._on_player_move_to( ControlNode.player.get_pos() )
