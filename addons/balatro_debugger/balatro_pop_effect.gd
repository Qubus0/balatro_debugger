@tool
class_name BalatroPopEffect
extends RichTextEffect

var bbcode = "pop"
var counter: int = 0
var font_size: int = 0

var attached_to_label: RichTextLabel:
	set(val):
		attached_to_label = val
		if is_instance_valid(attached_to_label):
			font_size = attached_to_label.get_theme_font_size(&"normal_font_size", &"RichTextLabel")


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# at about .1 duration it becomes invisible with the lowered framerate
	# that the editor has while running the project... looks better though
	var duration := float(char_fx.env.get("duration", .15))
	var peak_scale := float(char_fx.env.get("peak_scale", 2.5))

	# Normalized time [0, 1]
	var t := minf(char_fx.elapsed_time / duration, 1)
	# Scale factor varies from 1 → peak → 1
	var scale := 1 + (peak_scale - 1) * sin(t * PI)

	# baseline center upwards
	#var scale_pivot := Vector2(glyph_size(char_fx).x/2, glyph_size(char_fx).y)
	var scale_pivot := glyph_size(char_fx)/2
	char_fx.transform = char_fx.transform\
		.translated(-scale_pivot)\
		.scaled(Vector2(scale, scale))\
		.translated(scale_pivot)\
		;
	return true


# technically not the size but get_glyph_size takes
func glyph_size(char_fx : CharFXTransform) -> Vector2:
	# constant from the chosen monospaced font and size
	return Vector2(7, 18) * (2 if DisplayServer.has_feature(DisplayServer.FEATURE_HIDPI) else 1)

	# otherwise
	#var size := font_size if font_size > 0 else 16
	#return TextServerManager.get_primary_interface().font_get_glyph_advance(char_fx.font, size, char_fx.glyph_index)
