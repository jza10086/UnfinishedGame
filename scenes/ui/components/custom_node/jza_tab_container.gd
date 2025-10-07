@tool
class_name JzaTabContainer 
extends TabContainer
## 自定义 TabContainer，根据 JzaControl 子节点属性自动设置选项卡样式

func _ready():
	child_entered_tree.connect(_on_child_changed)
	child_exiting_tree.connect(_on_child_changed)
	call_deferred("_update_all_tabs")

func _enter_tree():
	if Engine.is_editor_hint():
		#if not child_entered_tree.is_connected(_on_child_changed):
			#child_entered_tree.connect(_on_child_changed)
		#if not child_exiting_tree.is_connected(_on_child_changed):
			#child_exiting_tree.connect(_on_child_changed)
		call_deferred("_update_all_tabs")

func _on_child_changed(_node: Node):
	call_deferred("_update_all_tabs")

func _update_all_tabs():
	for i in range(get_tab_count()):
		var child = get_tab_control(i)
		if child is JzaControl:
			var jza_control = child as JzaControl
			set_tab_icon(i, jza_control.texture)
			set_tab_title(i, child.name if jza_control.show_name else "")
			set_tab_disabled(i, jza_control.disabled)
		else:
			set_tab_title(i, child.name)
			set_tab_disabled(i, false)

func _notification(what):
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		call_deferred("_update_all_tabs")


func refresh_tabs():
	_update_all_tabs()

# 设置 JzaControl 属性的便捷方法
func set_jza_control_property(tab_index: int, property: String, value):
	if tab_index < 0 or tab_index >= get_tab_count():
		return
		
	var child = get_tab_control(tab_index)
	if child is JzaControl:
		child.set(property, value)

# 批量操作方法
func set_all_jza_tabs_disabled(disabled: bool):
	for i in range(get_tab_count()):
		var child = get_tab_control(i)
		if child is JzaControl:
			child.disabled = disabled
