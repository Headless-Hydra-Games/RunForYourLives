extends Node

@export var timeout_value = 5

var enet_peer: ENetMultiplayerPeer
@onready var join_timeout = $Timer

signal connected(peer_id: int)
signal timeout_signal

func _ready():
	join_timeout.autostart = false
	join_timeout.one_shot = true
	join_timeout.wait_time = timeout_value
	join_timeout.timeout.connect(connection_timeout)

func join_server(address: String, port: int):
	enet_peer = ENetMultiplayerPeer.new()
	var result = enet_peer.create_client(address, port)
	
	join_timeout.start()
	
	multiplayer.multiplayer_peer = enet_peer
	
	if !multiplayer.connected_to_server.is_connected(connected_to_server):
		multiplayer.connected_to_server.connect(connected_to_server)
	
	return result

func leave_server():
	multiplayer.connected_to_server.disconnect(connected_to_server)
	multiplayer.multiplayer_peer.close()
	enet_peer.close()

func connected_to_server():
	join_timeout.stop()
	connected.emit(multiplayer.get_unique_id())

func connection_timeout():
	print("Connection timeout")
	leave_server()
	timeout_signal.emit()

func stop_connection_attempt():
	if !join_timeout.is_stopped():
		join_timeout.stop()
		leave_server()
