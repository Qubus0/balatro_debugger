@tool
extends EditorPlugin

const BALATRO_TEXT = preload("res://addons/balatro_debugger/balatro_text.tscn")
const BALATRO_BUTTON = preload("res://addons/balatro_debugger/balatro_button.tscn")
var button_impersonators := []
var logger_text: RichTextLabel
var bg


func _enter_tree() -> void:
	#randomize()
	# wait for all editor nodes to be there
	#await get_tree().root.ready # too early for some reason
	await get_tree().create_timer(.2)
	var dummy := Control.new() # only used to easily retrieve the other nodes
	var bottom_panel_buttonbar: HBoxContainer = add_control_to_bottom_panel(dummy, "Dummy").get_parent()
	var bottom_panel := dummy.get_parent()
	remove_control_from_bottom_panel(dummy)
	dummy.queue_free()

	bottom_panel_buttonbar.clip_contents = false
	bottom_panel_buttonbar.get_parent().clip_contents = false

	for button: Button in bottom_panel_buttonbar.get_children():
		# probably breaks for editor translations
		if button.text.contains("Debugger"):
			var impersonator = BALATRO_TEXT.instantiate()
			impersonator.impersonate_target = button
			button_impersonators.append(impersonator)

	var logger_panel := bottom_panel.find_child("*EditorLog*", false, false)
	# logger main rich text label
	logger_text = (logger_panel.get_child(1).find_children("*", "RichTextLabel", false, false).front() as RichTextLabel)
	bg = preload("res://addons/balatro_debugger/logger_bg.tscn").instantiate()
	logger_text.add_child(bg)
	logger_text.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())

	# editor log panel > last child is the right side button area, all buttons
	var th := EditorInterface.get_editor_theme()
	var log_button_icon_colors := [
		th.get_color("font_color", "Editor"),
		th.get_color("error_color", "Editor"),
		th.get_color("warning_color", "Editor"),
		th.get_color("font_color", "Editor"),
	]
	var button_index := 0
	for button in logger_panel.get_child(-1).find_children("*", "Button", false, false):
		var impersonator = BALATRO_BUTTON.instantiate()
		impersonator.impersonate_target = button
		impersonator.base_color = log_button_icon_colors[button_index]
		button_impersonators.append(impersonator)
		button_index += 1


func _exit_tree() -> void:
	for impersonator in button_impersonators:
		impersonator.impersonate_target = null

	logger_text.remove_theme_stylebox_override(&"normal")
	bg.queue_free()
