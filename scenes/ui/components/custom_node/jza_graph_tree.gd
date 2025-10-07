@tool
class_name JzaGraphTree
extends Node2D

@export var node_container: Node2D
@export var _refresh_button: bool = false:
	set(value):
		# 当你在编辑器里点击勾选框时，这个set函数就会被调用
		# 我们只在 value 为 true 时（即勾选时）执行
		if value:
			load_nodes_from_container()
			# 注意：你也可以在这里将 _refresh_button 立即设回 false，
			# 这样勾选框就不会保持勾选状态，但这属于进阶用法，非必需。

var nodes: Array = []  # 存储所有节点


func _ready() -> void:
	load_nodes_from_container()

func load_nodes_from_container() -> void:
	"""
	从node_container中获取所有JzaGraphTreeNode类型的子节点并存储
	"""
	# 清空现有节点数组
	nodes.clear()
	
	# 遍历node_container的所有子节点
	for child in node_container.get_children():
		if child is JzaGraphTreeNode:
			# 将节点添加到数组中
			nodes.append(child)
			# 设置节点的父树引用
			child.parent_tree = self
			print("JzaGraphTree: 加载节点 " + str(child.name))
			
	on_node_position_changed(null)
	print("JzaGraphTree: 共加载 " + str(nodes.size()) + " 个节点")


func get_all_nodes() -> Array:
	"""
	获取所有已加载的节点
	返回: JzaGraphTreeNode节点数组
	"""
	return nodes


func on_node_position_changed(_changed_node: JzaGraphTreeNode) -> void:
	"""
	当某个节点位置改变时，刷新所有相关的连接线
	- _changed_node: 位置发生变化的节点
	"""
	# 刷新所有节点的连接线
	for node in nodes:
		if node is JzaGraphTreeNode:
			node.refresh_connections()
