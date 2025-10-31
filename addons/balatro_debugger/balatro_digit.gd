@tool
extends RichTextLabel


func _ready() -> void:
	for effect in custom_effects:
		if effect is BalatroPopEffect:
			effect.attached_to_label = self
