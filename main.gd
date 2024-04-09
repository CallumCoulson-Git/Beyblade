extends Node

var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene
@export var SpawnPoints: Array[Vector3]
# Called when the node enters the scene tree for the first time.
func _on_host_pressed():
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player()
	get_node("CanvasLayer/Host").disabled = true
	get_node("CanvasLayer/Join").disabled = true
	$CanvasLayer/Join/IP.visible = false
	
func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.set_position(SpawnPoints.pick_random())
	player.name = str(id)
	call_deferred("add_child", player)
	
func _on_join_pressed():
	if $CanvasLayer/Join/IP.text != "":
		peer.create_client(str($CanvasLayer/Join/IP.text),135)
	else:
		peer.create_client("localhost",135)
	multiplayer.multiplayer_peer = peer
	get_node("CanvasLayer/Host").disabled = true
	get_node("CanvasLayer/Join").disabled = true
	$CanvasLayer/Join/IP.visible = false
