@tool
class_name TreeMapNode
extends Node2D

signal moved # 节点移动时发出
#signal connections_edited # 连接编辑时发出


@export var outputs: Array[int] = [] # 输出连接的节点索引数组
@export var inputs: Array[int] = [] # 输入连接的节点索引数组

@export var locked: bool = false # 节点是否锁定
#@export_category("自定义")
#@export var data: Resource # 节点关联的数据


@export_category("覆盖属性")
# 默认值会被父节点 TreeMap 覆盖。
# 默认属性 - 如果父节点属性不存在，则使用此处的备用值。
#var default_node_color = Color.WHITE # 默认节点颜色
#var default_line_color = Color.WHITE # 默认连线颜色
#var default_arrow_color = Color.WHITE # 默认箭头颜色
#var default_arrow_texture = preload("res://addons/tree_maps/icons/arrow_filled.png") # 默认箭头纹理

# 从 TreeMap 继承的属性
var parent_node_color: Color
var parent_line_color: Color
var parent_arrow_color: Color
var parent_arrow_texture: Texture2D
	# 仅用于继承
var parent_node_size: float
var parent_node_shape: String
var parent_node_texture: Texture2D
var parent_line_thickness: float
var parent_line_texture: Texture2D

# 内部使用的属性
#var internal_line_color = default_line_color # 内部连线颜色

# 可编辑的覆盖属性
@export_group("节点")
@export var node_color: Color = Color.WHITE
@export_group("连线")
@export var line_color: Color = Color.WHITE
#@export var line_thickness: float = 10.0
@export_group("箭头")
@export var arrow_color: Color = Color.WHITE  ## 调整默认纹理的颜色
@export var arrow_texture: Texture2D = preload("res://addons/tree_maps/icons/arrow_filled.png")

var override_properties = []


func _setup():
	#print("setup")
	# 如果没有指定覆盖属性，则使用继承的属性。
	#if !line_color:
		#internal_line_color = parent_line_color
	# 如果没有指定继承的属性，则使用默认属性。
	#if !parent_line_color:
		#internal_line_color = default_line_color
	pass


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		set_notify_transform(true)
		EditorInterface.get_inspector().property_edited.connect( _on_property_edited )
	_setup()


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_inspector().property_edited.disconnect( _on_property_edited )


func _draw() -> void:
	_draw_connection()
	_draw_node()


func _draw_connection():
	for i in outputs:
		draw_set_transform(Vector2(0,0), 0)  # 重置绘制位置
		var target_pos = get_parent().get_child(i).global_position
		draw_line(Vector2(0,0) , target_pos - self.global_position, line_color, parent_line_thickness)

		var arrow_texture = arrow_texture
		var arrow_pos = (target_pos - self.position) / 2  # 获取节点之间的中点
		var arrow_ang = (target_pos - position).angle()   # 获取指向下一个连接节点的方向角度
		draw_set_transform(arrow_pos, arrow_ang)  # 将绘制偏移设置为箭头位置，使其成为旋转中心点
		draw_texture(arrow_texture, -arrow_texture.get_size() / 2, arrow_color)


func _draw_node():
	draw_set_transform(Vector2(0,0), 0)
	if parent_node_texture:
		var texture_offset = -(parent_node_texture.get_size() / 2)
		draw_texture(parent_node_texture, texture_offset, node_color)
	else:
		draw_circle(Vector2(0,0), parent_node_size / 2, node_color, true)
	#draw_colored_polygon() # 绘制带颜色的多边形


func _notification(what) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		moved.emit(self)


func _property_can_revert(property: StringName) -> bool:
	match property:
		"line_color", "node_color", "arrow_color", "arrow_texture":
			return true
	return false


func _property_get_revert(property: StringName) -> Variant:
	#match property:
		#"line_color":
			#return parent_line_color
	if get(property):
		# 如果父节点的继承属性可用，则返回该属性，否则返回备用的默认值
		var parent_prop = get("parent_" + property)
		if parent_prop: return parent_prop
		else: return get("default_" + property)
	return


#
func _on_property_edited(property: String):
	if EditorInterface.get_inspector().get_edited_object() == self:
		match property:
			"line_color", "node_color", "arrow_color", "arrow_texture":
				apply_properties()


# 更新属性
func apply_properties():
	# 如果覆盖属性等于继承属性，则使用继承属性进行更新
	#if line_color == parent_line_color: internal_line_color = parent_line_color
	# 否则使用覆盖属性
	#else: internal_line_color = line_color
	if line_color == parent_node_color: line_color = parent_line_color
	if node_color == parent_node_color: node_color = parent_node_color
	if arrow_color == parent_arrow_color: arrow_color = parent_arrow_color
	if arrow_texture == parent_arrow_texture: arrow_texture = parent_arrow_texture
	queue_redraw()


func toggle_lock():
	pass


## 为节点连接添加一个索引。
func add_connection(idx: int, connection_array: Array[int]):
	connection_array.append(idx)
	queue_redraw()


## 从节点的连接数组中移除索引。
func remove_connection(idx: int, connection_array: Array[int]):
	connection_array.erase(idx)
	queue_redraw()


func swap_connection(idx, old_array, new_array):
	old_array.erase(idx)
	new_array.append(idx)


# 如果输入/输出数组中包含值为 "idx" 的整数，则返回 true/false
func has_connection(idx: int, connection_array: Array[int]):
	return connection_array.has(idx)


func extend():
	pass
