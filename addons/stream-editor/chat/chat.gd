@tool
extends Node


# Public enums

enum State { disconnected = 0 , connected = 1 << 0, joined = 1 << 1 }


# Private constants

# Token generation: https://id.twitch.tv/oauth2/authorize?response_type=token&client_id=g5d7s4wwumnscbt222rrkritljlzdl&redirect_uri=http://localhost&scope=chat:read+chat:edit+channel:moderate+whispers:read+whispers:edit+channel_editor
const __TOKEN: String = ""
const __USERNAME: String = "veloperson"
const __CHANNEL: String = "veloperson"

const __REGEX_MESSAGE : String = "^(@(?P<tags>.*?) )?(?P<sender>:.*?tmi.twitch.tv) (?P<cmd>.*?) (?P<remainder>.*)$"


# Private variables

var __socket : WebSocketPeer
var __state : int

var __regex_message : RegEx


# Lifecycle methods

func _ready():
	__socket = WebSocketPeer.new()
	__socket.connect_to_url("wss://irc-ws.chat.twitch.tv:443")

	__regex_message = RegEx.new()
	__regex_message.compile(__REGEX_MESSAGE)


func _process(
	delta : float,
) -> void:
	if !__socket:
		return

	__socket.poll()

	match __socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if __state & State.connected:
				while __socket.get_available_packet_count():
					var messages : String = __socket.get_packet().get_string_from_utf8()
					for message : String in messages.split("\r\n", false):
						__handle_incoming_message(message)
			else:
				__state |= State.connected

				__send("PASS oauth:%s" % __TOKEN)
				__send("NICK %s" % __USERNAME)
				__send("CAP REQ :twitch.tv/commands twitch.tv/tags twitch.tv/membership")
		WebSocketPeer.STATE_CLOSED:
			if __state & State.connected == 0:
				print("Could not connect")
			else:
				__state = State.disconnected

				var code : int = __socket.get_close_code()
				var reason : String = __socket.get_close_reason()

				print("Connection closed: [%d] %s" % [code, reason])

			set_process(false)


# Public methods

func send_message(
	message : String,
) -> void:
	__send("PRIVMSG #%s :%s\r\n" % [__CHANNEL, message])


# Private methods

func __download_emote(
	id : String,
	path : String,
) -> void:
	var url : String = "https://static-cdn.jtvnw.net/emoticons/v2/%s/default/dark/2.0" % id

	var request : HTTPRequest = HTTPRequest.new()
	add_child(request)

	request.request(url)

	var result : Array = await request.request_completed
	remove_child(request)

	if result[1] == 200:
		var file_access : FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file_access.store_buffer(result[3])


func __handle_incoming_message(
	message : String,
) -> void:
	if message.begins_with("PING"):
		var response : String = message.split(" ", true, 1)[-1]
		__send("PONG %s" % response)

		return

	var parsed_message : RegExMatch = __regex_message.search(message)
	if !parsed_message:
		print("Unable to parse message: `%s`" % message)
		return

	var tags : Dictionary[String, String] = __parse_tags(parsed_message.get_string("tags"))
	var command : String = parsed_message.get_string("cmd")
	var remainder : String = parsed_message.get_string("remainder")

	match parsed_message.get_string("cmd"):
		"376":
			__send("JOIN #%s" % __CHANNEL)
		"JOIN":
			if __state & State.joined == 0:
				__state |= State.joined
				print("Joined %s" % __CHANNEL)
		"PRIVMSG":
			var color : String = tags["color"]
			var display_name : String = tags["display-name"]
			var user_message : String = remainder.split(":", 1)[-1]

			user_message = __replace_emotes(user_message, tags["emotes"])

			var display_message : String = "[color=%s]%s[/color] %s" % [
				color,
				display_name,
				user_message,
			]

			if tags["first-msg"] == "1":
				display_message = "[wave amp=50.0 freq=5.0 connected=1]%s[/wave]" % display_message

			print_rich(display_message)


func __parse_tags(
	tag_string : String,
) -> Dictionary[String, String]:
	if !tag_string:
		return {}

	var tags : Dictionary[String, String] = {}

	for tag : String in tag_string.split(";"):
		var parts : PackedStringArray = tag.split("=")

		tags[parts[0]] = parts[1]

	return tags


func __replace_emotes(
	message : String,
	emotes : String,
) -> String:
	var emote_data : Dictionary[String, String]

	for emote : String in emotes.split("/"):
		var parts : PackedStringArray = emote.split(":")
		var id : String = parts[0]

		# Only need to look at the first one as they will all share the
		# same emote text for us to replace.
		var location_parts : PackedStringArray = parts[1].split(",")[0].split("-")
		var start : int = int(location_parts[0])
		var length : int = int(location_parts[1]) - start + 1

		var emote_text : String = message.substr(start, length)
		var emote_path : String = "res://addons/stream-editor/cache/%s.png" % emote_text

		if !FileAccess.file_exists(emote_path):
			__download_emote(id, emote_path)

		emote_data[emote_text] = emote_path

	for emote_text : String in emote_data:
		var emote_path : String = emote_data[emote_text]

		if !FileAccess.file_exists(emote_path):
			emote_path = "res://addons/stream-editor/cache/missing.png"

		message = message.replace(emote_text, "[img]%s[/img]" % emote_path)

	return message


func __send(
	contents : String,
) -> void:
	__socket.send_text(contents)
