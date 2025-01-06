@tool
extends ColorRect


# Lifecycle methods

func _ready() -> void:
	resized.connect(__resized)
	__resized()


# Private methods

func __resized() -> void:
	material.set_shader_parameter("viewport_size", size)
