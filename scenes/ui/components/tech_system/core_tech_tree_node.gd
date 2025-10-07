@tool
extends JzaGraphTreeNode
class_name CoreTechTreeNode

@export var tech_type: StringName :set = _set_tech_type
@export var name_label: RichTextLabel
var data: Dictionary


func _set_tech_type(p_tech_type):
	tech_type = p_tech_type
	if Engine.is_editor_hint():
		name_label.text = p_tech_type

func set_label(p_text:String):
	name_label.text = p_text

func set_data(p_data: Dictionary):
	data = p_data

func _on_button_pressed():
	emit_signal(tech_type)
