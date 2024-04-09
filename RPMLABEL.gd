extends Label

func _process(_delta):
	if is_multiplayer_authority():
		var Player = get_node("../..")
		var RPM = roundi(Player.angular_velocity.y)
		#print_debug(RPM)
		text = str("RPM: ", RPM)
	else:
		text = str("")
