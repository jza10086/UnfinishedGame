@tool
class_name JzaGraphTreeNode
extends Node2D

@export var texture_rect: TextureRect
@export var texture: Texture2D : set = set_texture
@export var available: bool : set = set_button
@export var button: Button 
@export var input_marker: Marker2D
@export var output_marker: Marker2D
@export var line2d_container: Node2D
@export var connected_nodes: Array[Node] : set = set_connections # 连接的其他节点数组

var line2d_scene = preload("res://scenes/ui/components/custom_node/jza_line_2d.tscn")


signal node_pressed

# 父树的引用（由 JzaGraphTree 设置）
var parent_tree: JzaGraphTree = null

# 存储上一次的位置
var _last_position: Vector2 = Vector2.ZERO
var _last_input_marker_position: Vector2 = Vector2.ZERO
var _last_output_marker_position: Vector2 = Vector2.ZERO

func _enter_tree():
	# 初始化位置并启用变换通知
	_last_position = position
	set_notify_transform(true)
	
	# 为 markers 设置通知
	if input_marker:
		input_marker.set_notify_transform(true)
		_last_input_marker_position = input_marker.position
	if output_marker:
		output_marker.set_notify_transform(true)
		_last_output_marker_position = output_marker.position

func _ready() -> void:
	refresh_connections()

func _process(_delta: float) -> void:
	# 每帧检查 markers 的位置变化
	var needs_update = false
	
	# 检查 input_marker 位置变化
	if input_marker and input_marker.position != _last_input_marker_position:
		_last_input_marker_position = input_marker.position
		needs_update = true
	
	# 检查 output_marker 位置变化
	if output_marker and output_marker.position != _last_output_marker_position:
		_last_output_marker_position = output_marker.position
		needs_update = true
	
	# 如果 markers 位置变化，通知树
	if needs_update:
		_notify_tree_position_changed()

func _notification(what: int) -> void:
	# 监听节点自身变换改变的通知
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if position != _last_position:
			_last_position = position
			# 节点位置改变时通知树
			_notify_tree_position_changed()

func _notify_tree_position_changed() -> void:
	"""通知父树位置已改变"""
	if parent_tree:
		parent_tree.on_node_position_changed(self)

func set_texture(p_texture):
	texture = p_texture
	if p_texture:
		texture_rect.texture = p_texture

func set_button(p_available):
	if button:
		available = p_available
		button.disabled = not p_available

func set_connections(p_connected_nodes):
	"""设置连接的节点（仅设置关系，不刷新显示）"""
	# 验证连接
	var valid_nodes: Array[Node] = []
	for node in p_connected_nodes:
		if node and node is JzaGraphTreeNode:
			# 检查：不能连接自身
			if node == self:
				push_warning("JzaGraphTreeNode: 不能连接自身")
				continue
			
			# 检查：不能双向连接
			if node.connected_nodes.has(self):
				push_warning("JzaGraphTreeNode: 不能创建双向连接，节点 %s 已经连接到当前节点" % node.name)
				continue
			
			valid_nodes.append(node)
	
	connected_nodes = valid_nodes
	# 刷新连接线显示
	refresh_connections()

func refresh_connections():
	"""刷新连接线的显示（仅更新视觉，不改变连接关系）"""
	if not line2d_container or not output_marker:
		return
	
	# 清理所有已存在的 Line2D 子节点
	for child in line2d_container.get_children():
		child.queue_free()
	
	# 为每个连接的节点创建单独的 Line2D
	for node in connected_nodes:
		if node and node is JzaGraphTreeNode and node.input_marker:
			# 实例化新的 Line2D 场景
			var new_line = line2d_scene.instantiate()
			line2d_container.add_child(new_line)
			
			# 设置连接线的起点和终点
			new_line.clear_points()
			new_line.add_point(output_marker.global_position)
			new_line.add_point(node.input_marker.global_position)

func _on_button_pressed() -> void:
	node_pressed.emit()
