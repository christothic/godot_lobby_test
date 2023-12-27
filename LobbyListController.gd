extends ItemList

var request: HTTPRequest = null
var lobby_url = "http://dev.devatstation.com:30069/api/v1/lobbies"

func _ready():
    request = %HTTPRequest
    request.request(lobby_url)


# func _on_http_request_request_completed(result, response_code, headers, body):
#     #if response_code == 200:
#         #get_tree().change_scene("res://lobby_selection_screen.tscn")
#     var json = JSON.parse_string(body.get_string_from_utf8())
#     Log.everywhere("Response: " + JSON.stringify(json))
