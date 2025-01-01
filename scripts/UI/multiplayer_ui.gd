extends AspectRatioContainer

# Menus
@onready var mainMenu = $MarginContainer/MainMenu
@onready var connectedPlayersMenu = $MarginContainer/ConnectedPlayers
@onready var connectToServerMenu = $MarginContainer/ConnectToServer

# Main multiplayer menu items
@onready var playerNameTextEdit = $MarginContainer/MainMenu/PlayerNameTextEdit
@onready var createBtn = $MarginContainer/MainMenu/HBoxContainer/CreateBtn
@onready var findBtn = $MarginContainer/MainMenu/HBoxContainer/FindBtn
@onready var createServerErrorLbl = $MarginContainer/MainMenu/ErrorLbl

# Connected player list menu items
@onready var connectedPlayerList = $MarginContainer/ConnectedPlayers/ListView
@onready var serverAddressLabel = $MarginContainer/ConnectedPlayers/ServerAddressDisplayBox/ServerAddressLabel
@onready var serverAddressBox = $MarginContainer/ConnectedPlayers/ServerAddressDisplayBox
@onready var startBtn = $MarginContainer/ConnectedPlayers/HBoxContainer2/StartBtn
@onready var exitConnectedPLayerListBtn = $MarginContainer/ConnectedPlayers/HBoxContainer2/ExitBtn

# Join server menu items
@onready var serverAddress = $MarginContainer/ConnectToServer/ServerAddressEdit
@onready var connectBtn = $MarginContainer/ConnectToServer/HBoxContainer/ConnectBtn
@onready var exitJoinServerMenuBtn = $MarginContainer/ConnectToServer/HBoxContainer/BackBtn
@onready var joinServerErrorLbl = $MarginContainer/ConnectToServer/ErrorLbl

var currentMenu = mainMenu

func _ready():
	currentMenu = mainMenu
	mainMenu.visible = true
	connectedPlayersMenu.hide()
	connectToServerMenu.hide()

func switchToMainMenu():
	currentMenu.hide()
	mainMenu.visible = true
	currentMenu = mainMenu
	clearJoinServerError()
	cleanCreateServerError()

func switchToConnectedPlayerMenu(is_server: bool):
	currentMenu.hide()
	connectedPlayersMenu.visible = true
	currentMenu = connectedPlayersMenu
	
	startBtn.visible = is_server
	serverAddressBox.visible = is_server
	clearJoinServerError()
	cleanCreateServerError()

func switchToConnectToServerMenu():
	currentMenu.hide()
	connectToServerMenu.visible = true
	currentMenu = connectToServerMenu
	clearJoinServerError()
	cleanCreateServerError()

func _on_player_name_text_edit_text_changed():
	var emptyName = playerNameTextEdit.text.is_empty()
	createBtn.disabled = emptyName
	findBtn.disabled = emptyName

func _on_create_btn_pressed():
	$MarginContainer/MainMenu.hide()
	$MarginContainer/ConnectedPlayers.visible = true

func _on_find_btn_pressed():
	$MarginContainer/MainMenu.hide()
	connectToServerMenu.visible = true

func _on_server_address_edit_text_changed():
	connectBtn.disabled = serverAddress.text.is_empty()

func _on_connect_btn_pressed():
	connectToServerMenu.hide()
	$MarginContainer/ConnectedPlayers.visible = true

func joinServerError(msg: String):
	joinServerErrorLbl.text = msg

func clearJoinServerError():
	joinServerErrorLbl.text = ""

func createServerError(msg: String):
	createServerErrorLbl.text = msg

func cleanCreateServerError():
	createServerErrorLbl.text = ""
