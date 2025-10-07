extends Control

var general_tech_label_scene = preload("res://scenes/ui/components/tech_system/general_tech_label.tscn")

@export var label_container:VBoxContainer

var tech_label_nodes:Array[Node] = []

signal label_pressed

# 在label_container中添加tech_label
func add_tech_label(tech_type: StringName, progress_value: float = 0.0) -> Control:	
	var tech_label =  general_tech_label_scene.instantiate()
	label_container.add_child(tech_label)
	tech_label.set_tech_data(tech_type, progress_value)
	tech_label_nodes.append(tech_label)
	
	tech_label.label_left_clicked.connect(_on_label_left_clicked.bind(tech_type))
	return tech_label

# 清空所有tech_label
func clear_tech_labels() -> void:
	var children = label_container.get_children()
	for child in children:
		child.queue_free()
	tech_label_nodes.clear()
	
func _on_label_left_clicked(tech_type) -> void:
	label_pressed.emit(tech_type)
