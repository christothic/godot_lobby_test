extends Node

var peer_connection = WebRTCPeerConnection.new()
var data_channel: WebRTCDataChannel
var lobby_id: String
var ws = WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED
var heartbeat_interval = 10
var heartbeat_timer = Timer.new()

func _on_heartbeat_timeout():
	peer_connection.poll()
	ws.poll()
	Log.everywhere(ws.get_ready_state())
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		Log.everywhere("STATE_OPEN")
		send("ping")

func send(message) -> int:
	if typeof(message) == TYPE_STRING:
		return ws.send_text(message)
	return ws.send(var_to_bytes(message))

	
func start_websocket():
	var err = ws.connect_to_url("ws://dev.devatstation.com:30069/ws")
	if err != OK:
		return err
	last_state = ws.get_ready_state()
	add_child(heartbeat_timer)
	heartbeat_timer.wait_time = heartbeat_interval
	heartbeat_timer.timeout.connect(_on_heartbeat_timeout)
	heartbeat_timer.start()
	return OK
	
func _ready():
	start_websocket()    
	
func start_connection(new_lobby_id: String):
	self.lobby_id = new_lobby_id
	peer_connection.session_description_created.connect(_on_session_description_created)
	peer_connection.ice_candidate_created.connect(_on_ice_candidate_created)
	setup_webrtc()
	create_data_channel(lobby_id)
	create_webrtc_offer()

func setup_webrtc():
	var configuration = {
		"iceServers": [
			{
				"urls": [ "stun:stun.l.google.com:19302", "stun:stun.2.google.com:19302" ],
			}
		]
	}
	peer_connection.initialize(configuration)
	
func _process(_delta):
	if ws.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		Log.everywhere("STATE_CONNECTING")
		ws.poll()
	#if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		#Log.everywhere("STATE_OPEN")
	if ws.get_ready_state() == WebSocketPeer.STATE_CLOSING:
		Log.everywhere("STATE_CLOSING")
		ws.poll()
	if ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		Log.everywhere("STATE_CLOSED")

func create_data_channel(channel_id: String):
	data_channel = peer_connection.create_data_channel(channel_id)
	peer_connection.data_channel_received.connect(_on_data_received)
	Log.everywhere(data_channel)

func _on_data_received(channel_id, data):
	Log.everywhere("Received data on channel %s: %s" % [channel_id, data])

func create_webrtc_offer():
	peer_connection.create_offer()

func _on_session_description_created(type: String, sdp: String):
	Log.everywhere("_on_session_description_created: TYPE!: " + str(type))
	
	peer_connection.set_local_description(type, sdp)
	send_webrtc_data(type, sdp)
	
func handle_webrtc_answer(sdp: String):
	peer_connection.set_remote_description("answer", sdp)
	peer_connection.create_answer()


func _on_ice_candidate_created(media: String, index: int, sdp: String):
	send_ice_candidate_to_server(media, index, sdp)
	
func add_ice_candidate(media: String, index: int, sdp: String):
	peer_connection.add_ice_candidate(media, index, sdp)

func send_webrtc_data(type: String, offer_string: String):
	var request: HTTPRequest = HTTPRequest.new()
	var paramerters = JSON.stringify({ 
		"user_id": GameManager.user.id,
		"webrtc_" + type: offer_string 
		})
	var headers = ["Content-Type: application/json"]
	Log.everywhere("Paramerters: " + str(paramerters))
	Log.everywhere("Headers: " + str(headers))
	add_child(request)
	request.request_completed.connect(
		func(result: int, response_code: int, response_headers: PackedStringArray, body: PackedByteArray):
			Log.everywhere("Response code: " + str(response_code))
			Log.everywhere("Result code: " + str(result))
			Log.everywhere("Headers: " + str(response_headers))
			if response_code == 200:
				var json = JSON.parse_string(body.get_string_from_utf8())
				Log.everywhere("Response: " + JSON.stringify(json))
	)
	request.request("http://dev.devatstation.com:30069/api/v1/lobbies/" + lobby_id + "/webrtc_" + type, headers, HTTPClient.METHOD_PUT, paramerters)

func send_ice_candidate_to_server(media: String, index: int, sdp: String):
	var request: HTTPRequest = HTTPRequest.new()
	var paramerters = JSON.stringify({
			"user_id": GameManager.user.id,
			"candidate": sdp,
			"sdp_mid": media,
			"sdp_mline_index": index
		})
	var headers = ["Content-Type: application/json"]
	Log.everywhere("Paramerters: " + str(paramerters))
	Log.everywhere("Headers: " + str(headers))
	add_child(request)
	request.request_completed.connect(
		func(result: int, response_code: int, response_headers: PackedStringArray, body: PackedByteArray):
			Log.everywhere("Response code: " + str(response_code))
			Log.everywhere("Result code: " + str(result))
			Log.everywhere("Headers: " + str(response_headers))
			if response_code == 200:
				var json = JSON.parse_string(body.get_string_from_utf8())
				Log.everywhere("Response: " + JSON.stringify(json))
	)
	request.request("http://dev.devatstation.com:30069/api/v1/lobbies/" + lobby_id + "/webrtc_ice_candidate", headers, HTTPClient.METHOD_PUT, paramerters)
