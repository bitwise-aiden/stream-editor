class_name EmoteDownloader extends Node


# Private constants

const __BASE_URL : String = "https://static-cdn.jtvnw.net/emoticons/v2/%s/%s/dark/1.0"


# Public methods

func download(
	emote_id : String,
	path : String,
) -> void:
	if await  __download_static(emote_id, path):
		__download_animated(emote_id, path)


# Private methods

func __download_static(
	emote_id : String,
	path : String,
) -> bool:
	var url : String = __BASE_URL % [emote_id, "static"]
	var data : PackedByteArray = await __make_request(url)

	var image : Image = Image.new()
	if data.is_empty() || image.load_png_from_buffer(data) != OK:
		printerr("Unable to cache emote: `%s`" % path)

		DirAccess.copy_absolute(
			"res://addons/stream-editor/cache/missing.tres",
			path,
		)

		return false

	var animated : AnimatedTexture = AnimatedTexture.new()
	animated.set_frame_texture(0, ImageTexture.create_from_image(image))

	ResourceSaver.save(animated, path)

	return true


func __download_animated(
	emote_id : String,
	path : String,
) -> void:
	# Intentionally skipping this part for now because there are probably
	# more important features than handrolling my own GIF -> AnimatedTexture
	# parser.... Though it does sound _very_ interesting to do, so here are
	# some resources for *when* I pick this up again:
	# - https://en.wikipedia.org/wiki/GIF
	# - https://www.w3.org/Graphics/GIF/spec-gif89a.txt
	return

	var url : String = __BASE_URL % [emote_id, "animated"]
	var data : PackedByteArray = await __make_request(url)

	if data.is_empty():
		return


func __make_request(
	url : String
) -> PackedByteArray:
	var request : HTTPRequest = HTTPRequest.new()
	add_child(request)

	request.request(url)
	var result : Array = await request.request_completed

	remove_child(request)

	if result[1] == 200:
		return result[3]

	return PackedByteArray()
