extends Control

var unit_panel_scene = preload("res://scenes/ui/components/unit_panel.tscn")

@export var panel_container:PanelContainer

# 在panel_container中添加unit_panel
func add_unit_panel() -> Control:	
	var unit_panel = unit_panel_scene.instantiate()
	panel_container.add_child(unit_panel)
	return unit_panel

# 添加unit_panel并设置数据
func add_unit_panel_with_data(name_text: String, cost_text: String, texture: Texture2D = null, labels: Array[String] = [], tags: Array[String] = []) -> Control:
	var unit_panel = add_unit_panel()
	unit_panel.set_name_label(name_text)
	unit_panel.add_cost_label(cost_text)
	unit_panel.set_texture(texture)
	
	# 添加标签
	for label_text in labels:
		unit_panel.add_label(label_text)
	
	# 添加标签
	for tag_text in tags:
		unit_panel.add_tag(tag_text)
	
	return unit_panel

# 删除指定的unit_panel
func remove_unit_panel(unit_panel: Control) -> bool:
	if not unit_panel:
		return false
	
	if unit_panel.get_parent() == panel_container:
		panel_container.remove_child(unit_panel)
		unit_panel.queue_free()
		return true
	else:
		push_error("UnitList: 指定的unit_panel不是panel_container的子节点")
		return false

# 清空所有unit_panel
func clear_all_unit_panels() -> void:
	var children = panel_container.get_children()
	for child in children:
		child.queue_free()
	
	print("UnitList: 已清空所有unit_panel，共 " + str(children.size()) + " 个")
