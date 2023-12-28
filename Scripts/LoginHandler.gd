extends Control

var username: LineEdit = null
var login_url = "http://dev.devatstation.com:30069/api/v1/users"
var login_request: HTTPRequest = null

func _ready():
	username = %Username
	username.grab_focus()


func _on_username_text_submitted(username_string):
	var paramerters = JSON.stringify({ "display_name": username_string })
	var headers = ["Content-Type: application/json"]
	Log.everywhere("Paramerters: " + str(paramerters))
	if not login_request:
		login_request = HTTPRequest.new()
		login_request.request_completed.connect(_request_completed)
		add_child(login_request)
		login_request.request(login_url, headers, HTTPClient.METHOD_POST, paramerters)


func _request_completed(result, response_code, headers, body):
	remove_child(login_request)
	login_request.queue_free()
	Log.everywhere("Response code: " + str(response_code))
	Log.everywhere("Result code: " + str(result))
	Log.everywhere("Headers: " + str(headers))
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		Log.everywhere("Response: " + JSON.stringify(json))
		GameManager.user = User.new(json["_id"]["$oid"])
		get_tree().change_scene_to_file("res://lobby_selection_screen.tscn")

