extends Node

@export var port = 7001

var server = null

enum player_attribute {NAME, PEER_ID}

var player_info = {}
var player_list: Array[Dictionary]

@onready var startBtn = $MultiplayerUI.startBtn

#signal player_connected(peer_id: int, player_name: String)
signal player_disconnected(peer_id: int)

func _ready():
	$MultiplayerUI.createBtn.pressed.connect(create_server)
	$MultiplayerUI.connectBtn.pressed.connect(join_server)
	$MultiplayerUI.findBtn.pressed.connect($MultiplayerUI.switchToConnectToServerMenu)
	$MultiplayerUI.exitConnectedPLayerListBtn.pressed.connect(close_and_return_to_main_menu)
	$MultiplayerUI.exitJoinServerMenuBtn.pressed.connect(exitJoinServerMenu)
	$Client.connected.connect(connected)
	$Client.timeout_signal.connect(func(): $MultiplayerUI.joinServerError("Connection timeout"))

func create_server():
	server = load("res://Scenes/server.tscn").instantiate()
	add_child(server)
	var result = server.create_server(port)
	if result != OK:
		$MultiplayerUI.createServerError("Error: " + error_string(result))
		print("Error: " + error_string(result))
		remove_child(server)
		server.queue_free()
		server = null
	else:
		$MultiplayerUI.switchToConnectedPlayerMenu(true)
		$Client.multiplayer.multiplayer_peer = server.enet_peer
		player_info[player_attribute.NAME] = $MultiplayerUI.playerNameTextEdit.text
		player_info[player_attribute.PEER_ID] = $Client.multiplayer.get_unique_id()
		player_list.append(player_info)
		display_player_list()
		if !server.multiplayer.peer_connected.is_connected(enable_startBtn):
			server.multiplayer.peer_connected.connect(enable_startBtn)
		if !server.multiplayer.peer_disconnected.is_connected(remove_player):
			server.multiplayer.peer_disconnected.connect(remove_player)
		$MultiplayerUI.serverAddressLabel.text = server.server_address

func join_server():
	$MultiplayerUI.clearJoinServerError()
	var result = $Client.join_server($MultiplayerUI.serverAddress.text, port)
	if result != OK:
		$MultiplayerUI.joinServerError("Error: " + error_string(result))
		print("Error: " + error_string(result))

func connected(peer_id: int):
	$MultiplayerUI.switchToConnectedPlayerMenu(false)
	$Client.multiplayer.server_disconnected.connect(close_and_return_to_main_menu)
	player_info[player_attribute.NAME] = $MultiplayerUI.playerNameTextEdit.text
	player_info[player_attribute.PEER_ID] = peer_id
	add_player_to_list.rpc(player_info)

func remove_player(peer_id: int):
	player_disconnected.emit(peer_id)
	if multiplayer.get_peers().is_empty():
		$MultiplayerUI.startBtn.disabled = true
	remove_player_from_list(peer_id)

func remove_player_from_list(peer_id: int):
	for info in player_list:
		if info[player_attribute.PEER_ID] == peer_id:
			player_list.erase(info)
			break
	update_client_player_lists.rpc(player_list)
	display_player_list()

@rpc("any_peer", "reliable")
func add_player_to_list(info: Dictionary):
	if $Client.multiplayer.is_server():
		player_list.append(info)
		update_client_player_lists.rpc(player_list)
		display_player_list()

@rpc("call_remote", "reliable")
func update_client_player_lists(list: Array[Dictionary]):
	player_list = list
	display_player_list()

func display_player_list():
	$MultiplayerUI.connectedPlayerList.listContainer.clear()
	for info in player_list:
		$MultiplayerUI.connectedPlayerList.listContainer.add_item(info[player_attribute.NAME])

func close_menu():
	$MultiplayerUI.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func open_menu():
	$MultiplayerUI.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_and_return_to_main_menu():
	if server != null:
		server.multiplayer.peer_connected.disconnect(enable_startBtn)
		server.multiplayer.peer_disconnected.disconnect(remove_player)
		server.close_server()
		remove_child(server)
		server.queue_free()
		server = null
		player_list.clear()
		display_player_list()
	else:
		$Client.multiplayer.server_disconnected.disconnect(close_and_return_to_main_menu)
		$Client.leave_server()
	
	player_list.clear()
	display_player_list()
	$MultiplayerUI.switchToMainMenu()
	open_menu()

func enable_startBtn(_peer_id): 
	if $MultiplayerUI.startBtn.disabled : 
		$MultiplayerUI.startBtn.disabled = false

func exitJoinServerMenu():
	$MultiplayerUI.switchToMainMenu()
	$Client.stop_connection_attempt()
