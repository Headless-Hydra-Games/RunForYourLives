extends Level

func _on_area_3d_body_entered(body):
	if not is_multiplayer_authority(): return
	
	body.set_position(Vector3(body.get_position().x, 1, 0))
