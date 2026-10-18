@tool
extends AspectRatioContainer

@onready var color_rect: ColorRect = $ColorRect

func set_first_color(color: Color):
	color_rect.material.set_shader_parameter("colour_1", color)

func set_second_color(color: Color):
	color_rect.material.set_shader_parameter("colour_2", color)
