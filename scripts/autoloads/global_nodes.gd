extends Node

var managers: Dictionary = {}

# UI相关
var UIManager: Node
var TestHUD: Node
var PlayerController: Node

# 初始化方法，由main_mode调用
func initialize_from_main(main_node: Node) -> void:
	# 获取UI引用
	UIManager = main_node.UIManager
	
	# 获取PlayerController引用
	PlayerController = main_node.PlayerController
	
	# 获取UI子节点
	if UIManager:
		TestHUD = UIManager.get_node_or_null("TestHUD")
	
	print("GlobalNodes: UI引用已初始化")
	print("GlobalNodes: 管理器将通过Manager基类自动注册到managers字典")
	
func add_manager(manager_name: String, node: Node):
	managers[manager_name] = node
	print("GlobalNodes: 注册管理器 - ", manager_name)

# 便捷方法获取管理器（可选，提供更简洁的语法）
func get_manager(manager_name: String) -> Node:
	if managers.has(manager_name):
		return managers[manager_name]
	else:
		push_error("GlobalNodes: 找不到管理器 - " + manager_name)
		return null
