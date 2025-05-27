@tool
extends Node


# Public enums

enum State { disconnected = 0 , connected = 1 << 0, joined = 1 << 1 }


# Private constants

# Token generation: https://id.twitch.tv/oauth2/authorize?response_type=token&client_id=g5d7s4wwumnscbt222rrkritljlzdl&redirect_uri=http://localhost&scope=chat:read+chat:edit+channel:moderate+whispers:read+whispers:edit+channel_editor
const __TOKEN: String = "jhzgkc5bw19o6h2zy5ltyq5gfs7d72"
const __USERNAME: String = "veloperson"
const __CHANNEL: String = "veloperson"

const __REGEX_MESSAGE : String = "^(@(?P<tags>.*?) )?(?P<sender>:.*?tmi.twitch.tv) (?P<cmd>.*?) (?P<remainder>.*)$"


# Private variables

var __socket : WebSocketPeer
var __state : int

var __regex_message : RegEx

var __message_queue : Array[Message]
var __emote_downloader : EmoteDownloader


# Lifecycle methods

func _ready():
	__socket = WebSocketPeer.new()
	__socket.connect_to_url("wss://irc-ws.chat.twitch.tv:443")

	__regex_message = RegEx.new()
	__regex_message.compile(__REGEX_MESSAGE)

	__emote_downloader = EmoteDownloader.new()
	add_child(__emote_downloader)


func __check_animated() -> void:
	var animated : AnimatedTexture = AnimatedTexture.new()
	var frame : int = 0

	var frames : Array[ImageTexture]

	for file : String in DirAccess.get_files_at("res://addons/stream-editor/cache"):
		if !file.ends_with(".png"):
			continue

		var path : String = "res://addons/stream-editor/cache/%s" % file
		var file_access : FileAccess = FileAccess.open(path, FileAccess.READ)

		print(file)
		var image : Image = Image.new()
		image.load_png_from_buffer(file_access.get_buffer(file_access.get_length()))

		var texture : ImageTexture = ImageTexture.create_from_image(image)
		frames.append(texture)

	for texture : ImageTexture in frames:
		animated.set_frame_texture(frame, texture)
		animated.set_frame_duration(frame, 0.2)
		print(animated.frames, " ", frame, " ", animated.get_frame_texture(frame))

		frame += 1

	animated.frames = frames.size()

	print("a")
	var error : Error = ResourceSaver.save(frames.front(), "res://addons/stream-editor/cache/missing.tres")
	print(error)

	print("b")

	print_rich("[img]res://addons/stream-editor/cache/testing.tres[/img]")

	print("c")


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

				while !__message_queue.is_empty() && __message_queue.front().should_output():
					var message : Message = __message_queue.pop_front()
					message.output()
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
			var user_color : String = tags["color"]
			var user_name : String = tags["display-name"]
			var user_message : String = remainder.split(":", false, 1)[-1]
			var first_time_chatter : bool = tags["first-msg"] == "1"
			var emotes : Dictionary[String, String] = __parse_emotes(user_message, tags["emotes"])

			var message_instance : Message = Message.new(
				user_message,
				user_name,
				user_color,
				emotes,
				first_time_chatter,
			)

			__message_queue.append(message_instance)


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


func __parse_emotes(
	message : String,
	emotes : String,
) -> Dictionary[String, String]:
	var emote_data : Dictionary[String, String]

	for emote : String in emotes.split("/", false):
		var parts : PackedStringArray = emote.split(":")
		var id : String = parts[0]

		# Only need to look at the first one as they will all share the
		# same emote text for us to replace.
		var location_parts : PackedStringArray = parts[1].split(",")[0].split("-")
		var start : int = int(location_parts[0])
		var length : int = int(location_parts[1]) - start + 1

		var emote_text : String = message.substr(start, length)
		var emote_path : String = "res://addons/stream-editor/cache/%s.tres" % emote_text

		if !FileAccess.file_exists(emote_path):
			__emote_downloader.download(id, emote_path)

		emote_data[emote_text] = emote_path

	return emote_data


func __send(
	contents : String,
) -> void:
	__socket.send_text(contents)
