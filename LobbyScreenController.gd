extends Control

var lobby_list: VBoxContainer = null
var lobby_url = "http://dev.devatstation.com:30069/api/v1/lobbies"
var create_game: Button = null
var join_game: Button = null
var join_code: LineEdit = null
var create_request: HTTPRequest = null
var join_request: HTTPRequest = null
var lobby_request: HTTPRequest = null

func _ready():
    lobby_list = %VBoxContainer
    create_game = %CreateGame
    join_game = %JoinGame
    join_code = %JoinCode
    lobby_request = HTTPRequest.new()
    lobby_request.request_completed.connect(_lobby_request_completed)
    add_child(lobby_request)
    lobby_request.request(lobby_url)
    #request.request_completed.connect(
        #func(result, response_code, headers, body):
            #_lobby_request_completed(result, response_code, headers, body))

func _lobby_request_completed(result, response_code, headers, body):
    remove_child(lobby_request)
    lobby_request.queue_free()
    Log.everywhere("Response code: " + str(response_code))
    Log.everywhere("Result code: " + str(result))
    Log.everywhere("Headers: " + str(headers))
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        Log.everywhere("Response: " + JSON.stringify(json))
        for item in json:
            var lobby_cell: Control = load("res://lobby_cell.tscn").instantiate()
            lobby_cell.get_node("Name").text = item["name"]
            lobby_cell.get_node("IP").text = item["short_id"]
            lobby_list.add_child(lobby_cell)

func _on_create_game_pressed():
    var paramerters = JSON.stringify({ "name": "name", "creator_id" : GameManager.user.id })
    var headers = ["Content-Type: application/json"]
    Log.everywhere("Paramerters: " + str(paramerters))
    create_request = HTTPRequest.new()
    create_request.request_completed.connect(_create_request_completed)
    add_child(create_request)
    create_request.request(lobby_url, headers, HTTPClient.METHOD_POST, paramerters)

func _create_request_completed(result, response_code, headers, body):
    remove_child(create_request)
    create_request.queue_free()
    Log.everywhere("Response code: " + str(response_code))
    Log.everywhere("Result code: " + str(result))
    Log.everywhere("Headers: " + str(headers))
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        Log.everywhere("Response: " + JSON.stringify(json))
        WebRTC.start_connection(json["_id"]["$oid"])
        

func _on_refresh_list_pressed():
    for cell in lobby_list.get_children():
        lobby_list.remove_child(cell)
        cell.queue_free()
    lobby_request = HTTPRequest.new()
    lobby_request.request_completed.connect(_lobby_request_completed)
    add_child(lobby_request)
    lobby_request.request(lobby_url)

func _join_request_completed():
    remove_child(join_request)
    join_request.queue_free()
