extends Manager

# UnitsManager - 负责管理所有游戏单位的连接和信号绑定
# 监听Stellars和Fleets容器，自动连接新加入的单位到PlayerController


# 容器节点引用
@export var stellars_container: Node
@export var fleets_container: Node

func _ready():
	super._ready()
	validate_and_setup()

# 验证节点引用并设置容器监听
func validate_and_setup():
	var validation_success = true
	
	# 验证Stellars容器
	if not stellars_container:
		printerr("UnitsManager: Stellars容器节点引用无效")
		validation_success = false
	
	# 验证Fleets容器
	if not fleets_container:
		printerr("UnitsManager: Fleets容器节点引用无效")
		validation_success = false
	
	# 如果验证失败，停止初始化
	if not validation_success:
		printerr("UnitsManager: 节点验证失败，终止初始化")
		return
	
	# 设置Stellars容器监听
	setup_container_monitoring(stellars_container, "Stellar")
	connect_existing_units(stellars_container, "Stellar")
	
	# 设置Fleets容器监听
	setup_container_monitoring(fleets_container, "Fleet")
	connect_existing_units(fleets_container, "Fleet")
	
	print("UnitsManager: 初始化完成")

# 设置容器监听
func setup_container_monitoring(container: Node, unit_type: String):
	# 连接child_entered_tree信号
	if not container.child_entered_tree.is_connected(_on_unit_added):
		container.child_entered_tree.connect(_on_unit_added.bind(unit_type))
	
	# 连接child_exiting_tree信号（可选，用于清理）
	if not container.child_exiting_tree.is_connected(_on_unit_removed):
		container.child_exiting_tree.connect(_on_unit_removed.bind(unit_type))

# 连接容器中现有的单位
func connect_existing_units(container: Node, unit_type: String):
	for child in container.get_children():
		if is_valid_unit(child, unit_type):
			connect_unit_to_player_controller(child)

# 检查节点是否是有效的单位
func is_valid_unit(node: Node, unit_type: String) -> bool:
	if unit_type == "Stellar":
		return node is Stellar
	elif unit_type == "Fleet":
		return node is Fleet
	return false

# 单位添加回调
func _on_unit_added(unit: Node, unit_type: String):
	# 验证单位类型
	if not is_valid_unit(unit, unit_type):
		return
	
	# 延迟连接，确保单位完全初始化
	call_deferred("connect_unit_to_player_controller", unit)

# 单位移除回调
func _on_unit_removed(unit: Node, _unit_type: String):
	# 如果这个单位正在被PlayerController选中，清除选中状态
	if GlobalNodes.PlayerController:
		var current_selected = GlobalNodes.PlayerController.get_current_selected_unit()
		if current_selected == unit:
			GlobalNodes.PlayerController.clear_selection()

# 连接单位到PlayerController
func connect_unit_to_player_controller(unit: Node):
	if not GlobalNodes.PlayerController:
		printerr("UnitsManager: PlayerController未找到，无法连接单位")
		return
	
	if not unit.has_signal("selected"):
		printerr("UnitsManager: 单位 ", unit.name, " 没有selected信号")
		return
	
	# 检查是否已经连接
	if unit.selected.is_connected(GlobalNodes.PlayerController.on_unit_selected):
		return
	
	# 连接selected信号到PlayerController
	unit.selected.connect(GlobalNodes.PlayerController.on_unit_selected)

# 手动重新扫描并连接所有单位（调试用）
func rescan_and_connect_all():
	validate_and_setup()

# 获取连接状态信息（调试用）
func get_connection_status() -> Dictionary:
	var status = {
		"player_controller_found": GlobalNodes.PlayerController != null,
		"stellars_container_found": stellars_container != null,
		"fleets_container_found": fleets_container != null,
		"connected_stellars": 0,
		"connected_fleets": 0
	}
	
	if stellars_container and GlobalNodes.PlayerController:
		for child in stellars_container.get_children():
			if child is Stellar and child.has_signal("selected") and child.selected.is_connected(GlobalNodes.PlayerController.on_unit_selected):
				status.connected_stellars += 1
	
	if fleets_container and GlobalNodes.PlayerController:
		for child in fleets_container.get_children():
			if child is Fleet and child.has_signal("selected") and child.selected.is_connected(GlobalNodes.PlayerController.on_unit_selected):
				status.connected_fleets += 1
	
	return status
