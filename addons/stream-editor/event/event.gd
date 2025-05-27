@tool
extends Node

var camera_screen : Control


func __find_node_by_type(
	type : String,
	root : Node = EditorInterface.get_base_control(),
) -> Node:
	if root.get_class() == type:
		return root

	for child : Node in root.get_children():
		var result : Node = __find_node_by_type(type, child)
		if result:
			return result

	return null


func _ready() -> void:
	await get_tree().create_timer(5).timeout

	var screens : Array[Control] = [
		EditorInterface.get_editor_toaster().get_parent().get_parent().get_parent(),
		EditorInterface.get_editor_main_screen().get_parent().get_parent(),
		EditorInterface.get_inspector().get_parent().get_parent(),
		EditorInterface.get_file_system_dock().get_parent(),
		#__find_node_by_type(EditorInterface.get_base_control(), "Camera").get_parent().get_parent(),
		#__find_node_by_type("EditorRunBar"),
		__find_node_by_type("SceneTreeDock").get_parent().get_parent(),
	]

	for child in __find_node_by_type("EditorTitleBar").get_children():
		screens.append(child)


	#await get_tree().create_timer(5).timeout

	#for screen in screens:
		#var original_pivot : Vector2 = screen.pivot_offset
		#screen.pivot_offset = screen.size * 0.5
#
		#var original_scale : Vector2 = screen.scale
#
		#var tween : Tween = create_tween()
		#tween.tween_property(
			#screen,
			#"scale",
			#original_scale * 0.95,
			#0.1,
		#).set_ease(Tween.EASE_IN_OUT)
		#for i in 50:
			#var location : Vector2 = Vector2(
				#randf() * 15.0,
				#randf() * 15.0,
			#) + screen.position
			#tween.tween_property(
				#screen,
				#"position",
				#location,
				#0.1,
			#)
		#tween.tween_property(
			#screen,
			#"position",
			#screen.position,
			#0.1,
		#)
		#tween.tween_property(
			#screen,
			#"scale",
			#original_scale,
			#0.1
		#).set_ease(Tween.EASE_IN_OUT)
		#tween.tween_property(
			#screen,
			#"pivot_offset",
			#original_pivot,
			#0.0
		#)
