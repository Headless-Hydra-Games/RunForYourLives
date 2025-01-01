extends Node

var enet_peer: ENetMultiplayerPeer
var server_address

func create_server(port: int):
	enet_peer = ENetMultiplayerPeer.new()
	var result = enet_peer.create_server(port)
	
	if result == OK:
		multiplayer.multiplayer_peer = enet_peer
		upnp_setup(port)
	
	return result

func close_server():
	multiplayer.multiplayer_peer.close()
	enet_peer.close()

func upnp_setup(port: int):
	var upnp = UPNP.new()
	
	var result = upnp.discover()
	
	if result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP discovery error code: " + str(result))
		return
	
	if not (upnp.get_gateway() and upnp.get_gateway().is_valid_gateway()):
		print("UPNP invalid gateway")
		return
	
	var port_map_result = upnp.add_port_mapping(port)
	
	if port_map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP port mapping failed")
		return
	
	print("Successfully setup UPNP. Address: %s" % upnp.query_external_address())
	server_address = upnp.query_external_address()
