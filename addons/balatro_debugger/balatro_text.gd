@tool
extends Control


@onready var fire: Control = %Fire
@onready var fire_shader: ShaderMaterial = fire.material

@onready var digit: RichTextLabel = %BalatroDigit
@onready var digit_box: BoxContainer = %DigitBox
@onready var icon: Button = %Icon
@onready var text_before: Label = %TextBefore
@onready var text_after: Label = %TextAfter
@onready var spacer: MarginContainer = %Spacer

var digits_regex: RegEx

var max_intensity := 100.0
var min_intensity := 0.0
var cooldown := 10
var intensity := .0:
	set(val):
		intensity = clampf(val, min_intensity, max_intensity)

var prev_text := ""
var text := "":
	set(val):
		if not digits_regex:
			digits_regex = RegEx.create_from_string(r"([^\d]*)(\d*)(.*)")
		if not is_node_ready():
			#await ready
			return
		prev_text = text
		text = val
		if text == prev_text:
			return

		# minimum to scale with consecutive
		var difference_factor: float = clampf(int(text) - int(prev_text), 3, 60)
		intensity += difference_factor

		var result := digits_regex.search(text)
		if not result:
			return
		var prefix := result.get_string(1)  # "Debugger("
		var digit_text := result.get_string(2)  # "123"
		var suffix := result.get_string(3)  # ")"
		text_before.text = prefix
		text_after.text = suffix

		digit_box.visible = digit_text != ""

		var digit_display_text := ""
		var start_index := randi_range(0, digit_text.length()-1)
		for char_index: int in digit_text.length():
			# each digit is scaled a bit differently
			var distance_factor: float = absi(char_index - start_index) * 20
			var distanced := max(intensity - distance_factor, 1)
			var pop_scale := clamp(remap(distanced, min_intensity, max_intensity, 1.3, 2.5), 1, 5)
			digit_display_text += "[font_size=30][pop peak_scale=%s]%s[/pop]" % [pop_scale, digit_text[char_index]]
		digit.text = "%s" % digit_display_text
		tween_rotation()

var base_color: Color:
	set(val):
		base_color = val
		if base_color == Color.BLACK:
			return
		var h = base_color.h
		var s = base_color.s
		var v = base_color.v

		# Generate new colors: slightly brighter and hue shifted towards cooler (lower hue)
		var shift := -0.07
		var brightness := .3
		var color1 = Color.from_hsv(fmod((h - shift), 1.0), s, min(v + brightness, 1.0))
		var color2 = Color.from_hsv(fmod((h - 2*shift), 1.0), s, min(v + 2*brightness, 1.0))
		fire_shader.set_shader_parameter(&"top_color", base_color)
		fire_shader.set_shader_parameter(&"middle_color", color1)
		fire_shader.set_shader_parameter(&"bottom_color", color2)


var impersonate_target: Button:
	set(val):
		if impersonate_target == val:
			return
		if val == null:
			impersonate_target.reparent(get_parent(), false)
			impersonate_target.get_parent().move_child(impersonate_target, get_index())
			get_parent().remove_child(self)
			return_colors()
			impersonate_target = val
			queue_free()
			return

		fire_offset_y = randf_range(0, 10)
		impersonate_target = val
		steal_themes()
		var imp_index = impersonate_target.get_index()
		var imp_parent = impersonate_target.get_parent()
		impersonate_target.reparent(self, false)
		move_child(impersonate_target, 0)

		if is_inside_tree():
			self.reparent(imp_parent)
		else:
			imp_parent.add_child(self)
		imp_parent.move_child(self, imp_index)
		text = impersonate_target.text


func _ready() -> void:
	# prevent the fire from being culled since it's very slim and
	# expand margins are ignored by godot for some reason
	var stylebox: StyleBoxTexture = fire.get_theme_stylebox(&"panel", &"PanelContainer")
	RenderingServer.canvas_item_set_custom_rect(fire.get_canvas_item(), true,
		Rect2(
			fire.position.x, fire.position.y - stylebox.expand_margin_top,
			fire.size.x, fire.size.y + stylebox.expand_margin_top + stylebox.expand_margin_bottom
		)
	)


func _process(delta: float) -> void:
	if intensity > min_intensity:
		intensity -= cooldown * delta

	animate_fire(delta)
	sync_theme()
	if impersonate_target:
		text = impersonate_target.text



var fire_offset_y = 0.0
var fire_speed := 0.2
var time := 0.0

var fire_aperture_min := 0.2
var fire_aperture_max := 2.0
var fire_speed_min := 0.2
var fire_speed_max := 1.8
func animate_fire(delta: float):
	time += delta # hacky but eh
	var aperture := clamp(
		remap_exponential(intensity, fire_aperture_min, fire_aperture_max, 2.),
		fire_aperture_min, fire_aperture_max
	)
	if intensity > 90: aperture = fire_aperture_min
	if time > .3:
		time = 0
		var tw := create_tween().set_parallel()
		tw.tween_method(
			set_shader_param.bind("fire_aperture"),
			fire_shader.get_shader_parameter("fire_aperture"),
			aperture,
			.3
		)
		tw.tween_property(
			self, "fire_speed",
			remap(intensity, min_intensity, max_intensity, 0.2, 1.8),
			.3
		)

	# not the most efficient to control the speed outside the shader instead of with TIME
	# but this prevents speedup and reverses when changing the speed
	fire_offset_y += delta * fire_speed
	fire_shader.set_shader_parameter("fire_offset_y", fire_offset_y)


func set_shader_param(value: float, parameter: String) -> void:
	fire_shader.set_shader_parameter(parameter, value)


func remap_exponential(intens: float, from: float, to: float, steepness: float) -> float:
	var t := remap(intens, min_intensity, max_intensity -1, 0.0, 1.0) # normalize
	return from + (to - from) * exp(-steepness * t) # Apply exponential decay

var rotation_tween: Tween
func tween_rotation() -> void:
	digit.pivot_offset = digit.size/2
	if rotation_tween and rotation_tween.is_running():
		return
		#rotation_tween.stop()
	rotation_tween = create_tween()
	rotation_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)

	#if abs(digit.rotation_degrees) > 0:
		#rotation_tween.tween_property(digit, "rotation_degrees", 0, 0.1) # prevent spinning
	var rot := remap(randi_range(20, 30) * [-1, 1].pick_random(), -max_intensity, max_intensity, -30, 30)
	rotation_tween.tween_property(digit, "rotation_degrees", rot, 0.1).from_current()
	rotation_tween.tween_property(digit, "rotation_degrees", 0, 0.1)



var impersonate_font_color: Color
var impersonate_font_pressed_color: Color
var impersonate_font_hover_color: Color
var impersonate_font_hover_pressed_color: Color
var impersonate_font_focus_color: Color
var impersonate_font_disabled_color: Color

var impersonate_icon_normal_color: Color
var impersonate_icon_pressed_color: Color
var impersonate_icon_hover_color: Color
var impersonate_icon_hover_pressed_color: Color
var impersonate_icon_focus_color: Color
var impersonate_icon_disabled_color: Color


#var impersonate_font_outline_color: Color # no editor text uses it
func sync_theme():
	if not impersonate_target:
		return

	icon.icon = impersonate_target.icon
	spacer.add_theme_constant_override(
		&"margin_right",
		impersonate_target.get_theme_constant(&"h_separation") if icon.icon else 0
	)

	# the debugger button gets a new color when warnings or errors appear
	var new_color := impersonate_target.get_theme_color(&"font_color", &"Button")
	if new_color != Color.TRANSPARENT:
		impersonate_font_color = new_color
		impersonate_target.add_theme_color_override(&"font_color", Color.TRANSPARENT)

	# order of prescedence
	# disabled > pressed > hover_pressed > hover > focussed > normal
	# deafeats the purpose of hover_pressed but the engine made that logic
	if impersonate_target.has_focus():
		icon.add_theme_color_override(&"icon_normal_color", impersonate_icon_focus_color)
		text_before.add_theme_color_override(&"font_color", impersonate_font_focus_color)
		text_after.add_theme_color_override(&"font_color", impersonate_font_focus_color)
	match impersonate_target.get_draw_mode():
		Button.DrawMode.DRAW_NORMAL when not impersonate_target.has_focus():
			icon.add_theme_color_override(&"icon_normal_color", impersonate_icon_normal_color)
			text_before.add_theme_color_override(&"font_color", impersonate_font_color)
			text_after.add_theme_color_override(&"font_color", impersonate_font_color)
		Button.DrawMode.DRAW_PRESSED:
			icon.add_theme_color_override(&"icon_normal_color", impersonate_icon_pressed_color)
			text_before.add_theme_color_override(&"font_color", impersonate_font_pressed_color)
			text_after.add_theme_color_override(&"font_color", impersonate_font_pressed_color)
		Button.DrawMode.DRAW_HOVER:
			icon.add_theme_color_override(&"icon_normal_color", impersonate_icon_hover_color)
			text_before.add_theme_color_override(&"font_color", impersonate_font_hover_color)
			text_after.add_theme_color_override(&"font_color", impersonate_font_hover_color)
		Button.DrawMode.DRAW_HOVER_PRESSED:
			icon.add_theme_color_override(&"icon_normal_color", impersonate_icon_hover_pressed_color)
			text_before.add_theme_color_override(&"font_color", impersonate_font_hover_pressed_color)
			text_after.add_theme_color_override(&"font_color", impersonate_font_hover_pressed_color)
		Button.DrawMode.DRAW_DISABLED:
			icon.add_theme_color_override(&"icon_normal_color", impersonate_icon_disabled_color)
			text_before.add_theme_color_override(&"font_color", impersonate_font_disabled_color)
			text_after.add_theme_color_override(&"font_color", impersonate_font_disabled_color)


func steal_themes() -> void:
	impersonate_font_color = impersonate_target.get_theme_color(&"font_color", &"Button")
	impersonate_font_pressed_color = impersonate_target.get_theme_color(&"font_pressed_color", &"Button")
	impersonate_font_hover_color = impersonate_target.get_theme_color(&"font_hover_color", &"Button")
	impersonate_font_hover_pressed_color = impersonate_target.get_theme_color(&"font_hover_pressed_color", &"Button")
	impersonate_font_focus_color = impersonate_target.get_theme_color(&"font_focus_color", &"Button")
	impersonate_font_disabled_color = impersonate_target.get_theme_color(&"font_disabled_color", &"Button")
	impersonate_target.add_theme_color_override(&"font_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"font_pressed_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"font_hover_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"font_hover_pressed_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"font_focus_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"font_disabled_color", Color.TRANSPARENT)

	impersonate_icon_normal_color = impersonate_target.get_theme_color(&"icon_normal_color", &"Button")
	impersonate_icon_pressed_color = impersonate_target.get_theme_color(&"icon_pressed_color", &"Button")
	impersonate_icon_hover_color = impersonate_target.get_theme_color(&"icon_hover_color", &"Button")
	impersonate_icon_hover_pressed_color = impersonate_target.get_theme_color(&"icon_hover_pressed_color", &"Button")
	impersonate_icon_focus_color = impersonate_target.get_theme_color(&"icon_focus_color", &"Button")
	impersonate_icon_disabled_color = impersonate_target.get_theme_color(&"icon_disabled_color", &"Button")
	impersonate_target.add_theme_color_override(&"icon_normal_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"icon_pressed_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"icon_hover_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"icon_hover_pressed_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"icon_focus_color", Color.TRANSPARENT)
	impersonate_target.add_theme_color_override(&"icon_disabled_color", Color.TRANSPARENT)


func return_colors() -> void:
	impersonate_target.add_theme_color_override(&"font_color", impersonate_font_color)
	impersonate_target.add_theme_color_override(&"font_pressed_color", impersonate_font_pressed_color)
	impersonate_target.add_theme_color_override(&"font_hover_color", impersonate_font_hover_color)
	impersonate_target.add_theme_color_override(&"font_hover_pressed_color", impersonate_font_hover_pressed_color)
	impersonate_target.add_theme_color_override(&"font_focus_color", impersonate_font_focus_color)
	impersonate_target.add_theme_color_override(&"font_disabled_color", impersonate_font_disabled_color)

	impersonate_target.add_theme_color_override(&"icon_normal_color", impersonate_icon_normal_color)
	impersonate_target.add_theme_color_override(&"icon_pressed_color", impersonate_icon_pressed_color)
	impersonate_target.add_theme_color_override(&"icon_hover_color", impersonate_icon_hover_color)
	impersonate_target.add_theme_color_override(&"icon_hover_pressed_color", impersonate_icon_hover_pressed_color)
	impersonate_target.add_theme_color_override(&"icon_focus_color", impersonate_icon_focus_color)
	impersonate_target.add_theme_color_override(&"icon_disabled_color", impersonate_icon_disabled_color)



# other way of scaling each digit individually
#var text := "hello":
	#set(val):
		#if not is_inside_tree():
			#await ready
		#prev_text = text
		#text = val
		#for char_index in text.length():
			#if char_index > prev_text.length() -1 or text[char_index] == prev_text[char_index]:
				#continue
			#var digit: RichTextLabel
			#if get_child_count()-1 > char_index:
				#digit = get_child(char_index)
			#else:
				#digit = BALATRO_DIGIT.instantiate()
				#add_child(digit)
				#move_child(digit, char_index)
			#var peak_scale := clampf(int(prev_text[char_index]) - int(text[char_index])/10.0, 1.4, 3)
			#digit.text = "[pop peak_scale=%s]%s[/pop]" % [peak_scale, text[char_index]]
#
#
#func _ready() -> void:
	#var internal_node = $Label
	#self.remove_child(internal_node)
	#self.add_child(internal_node, false, Node.INTERNAL_MODE_FRONT)
	#internal_node = $Label2
	#self.remove_child(internal_node)
	#self.add_child(internal_node, false, Node.INTERNAL_MODE_BACK)
