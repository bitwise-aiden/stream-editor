class_name Message extends RefCounted


# Private constants

const __MAX_AGE_MS : int = 2500
const __MISSING_EMOTE_PATH : String = "res://addons/stream-editor/cache/missing.tres"


# Private variables

var __message : String
var __user_name : String
var __user_color : String
var __emotes : Dictionary[String, String]
var __first_time_chatter : bool
var __age : int


# Lifecycle methods

func _init(
	message : String,
	user_name : String,
	user_color : String,
	emotes : Dictionary[String, String],
	first_time_chatter : bool,
) -> void:
	__message = message
	__user_name = user_name
	__user_color = user_color
	__emotes = emotes
	__first_time_chatter = first_time_chatter

	__age = Time.get_ticks_msec()


# Public methods

func output() -> void:
	var output_message : String = __message

	for emote : String in __emotes:
		var path : String = __emotes[emote]

		if !FileAccess.file_exists(path):
			path = __MISSING_EMOTE_PATH

		output_message = output_message.replace(
			emote,
			"[img tooltip=%s]%s[/img]" % [emote, path],
		)

	output_message = "[color=%s]%s[/color] %s" % [
		__user_color,
		__user_name,
		output_message,
	]

	if __first_time_chatter:
		output_message = "[wave amp=50.0 freq=5.0 connected=1]%s[/wave]" % output_message

	print_rich(output_message)


func should_output() -> bool:
	if Time.get_ticks_msec() - __age > __MAX_AGE_MS:
		return true

	for emote : String in __emotes:
		var path : String = __emotes[emote]

		if !FileAccess.file_exists(path):
			return false

	return true
