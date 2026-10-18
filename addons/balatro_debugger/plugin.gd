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

	var dock := EditorDock.new()
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	add_dock(dock)

	var bottom_panel = dock.get_parent()
	remove_dock(dock)
	dock.free()

	var logger_panel := bottom_panel.get_node(tr("Output"))
	# logger main rich text label: HBoxContainer/VBoxContainer/RichTextLabel
	logger_text = (logger_panel.get_child(1).get_child(0).get_child(0) as RichTextLabel)
	bg = load("res://addons/balatro_debugger/logger_bg.tscn").instantiate()
	logger_text.add_child(bg)
	logger_text.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())

	var th := EditorInterface.get_editor_theme()

	bg.set_first_color(th.get_color("base_color", "Editor"))
	bg.set_second_color(th.get_color("accent_color", "Editor"))

	# editor log panel > last child is the right side button area, all buttons
	var log_button_icon_colors := [
		th.get_color("font_color", "Editor"),
		th.get_color("error_color", "Editor"),
		th.get_color("warning_color", "Editor"),
		th.get_color("font_color", "Editor"),
	]
	var button_index := 0
	# HBoxContainer/VBoxContainer/HFlowContainer/HBoxContainer/Button(s)
	for button in logger_panel.get_child(1).get_child(0).get_child(1).get_child(-1).get_children():
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
