@tool
extends EditorPlugin

# Private variables

var __camera_scene : PanelContainer
var __chat_scene : Node
var __notification_scene : PanelContainer

var __nodes : Array[Node]
var __target_nodes : Array[String] = [
	ProjectSettings.get_setting("application/config/name"),
	"2D",
	"3D",
	"Script",
	"Game",
	"AssetLib",
	"Forward",
]


# Lifecycle methods

func _enter_tree() -> void:
	var editor : Control = get_editor_interface().get_base_control()
	editor.material = preload("res://addons/stream-editor/background/background.material")

	for value : String in __target_nodes:
		var node : Node = __find_node_with_text(editor, value)
		if node:
			node.modulate = Color.DARK_SLATE_BLUE
			__nodes.append(node)

	__camera_scene = preload("res://addons/stream-editor/camera/camera.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, __camera_scene)

	__chat_scene = preload("res://addons/stream-editor/chat/chat.tscn").instantiate()
	add_child(__chat_scene)

	__notification_scene = preload("res://addons/stream-editor/notification/notification.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, __notification_scene)

	await get_tree().create_timer(5).timeout
	var toaster : EditorToaster = EditorInterface.get_editor_toaster()
	toaster.push_toast("ThatGuyIan Subscribed 12 months!", EditorToaster.SEVERITY_ERROR)


func _exit_tree() -> void:
	var editor : Control = get_editor_interface().get_base_control()
	editor.material = null

	for node : Node in __nodes:
		node.modulate = Color.WHITE

	if __camera_scene:
		remove_control_from_docks(__camera_scene)
		__camera_scene.queue_free()
		__camera_scene = null

	if __chat_scene:
		remove_child(__chat_scene)
		__chat_scene.queue_free()
		__chat_scene = null

	if __notification_scene:
		remove_control_from_docks(__notification_scene)
		__notification_scene.queue_free()
		__notification_scene = null


# Private methods

func __find_node_with_text(
	root : Node,
	target_text : String,
) -> Node:
	if root.has_method("get_text") && root.get_text().contains(target_text):
		return root

	for child in root.get_children():
		var node = __find_node_with_text(child, target_text)
		if node:
			return node

	return null
