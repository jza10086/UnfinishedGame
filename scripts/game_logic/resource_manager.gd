extends Manager

# 资源名称映射
var resource_names: Dictionary = {
	GlobalEnum.ResourceType.ENERGY: "能源",
	GlobalEnum.ResourceType.MINE: "矿物",
	GlobalEnum.ResourceType.FOOD: "食物"
}

# 阵营资源字典：{faction_id: {resource_type: amount}}
var faction_resources: Dictionary = {}
# 阵营预资源字典：{faction_id: {resource_type: amount}}
var faction_resource_productions: Dictionary = {}

func _ready() -> void:
	super._ready()
	
	# 连接GlobalSignalBus的简化信号
	GlobalSignalBus.resource_modify_request.connect(_on_resource_modify_request)
	GlobalSignalBus.resource_query_request.connect(_on_resource_query_request)
	GlobalSignalBus.resource_production_modify_request.connect(_on_resource_production_modify_request)
	GlobalSignalBus.resource_production_compare_request.connect(_on_resource_production_compare_request)
	
	# 连接资源更新请求信号
	GlobalSignalBus.resource_update_requested.connect(_on_resource_update_requested)
	
	# 延迟初始化System faction资源
	call_deferred("initialize_system_faction_resources")

func initialize_system_faction_resources():
	
	var system_faction_id = 1000
	var system_faction = GlobalNodes.managers.FactionManager.get_faction(system_faction_id)
	if system_faction:
		# 为System faction设置初始资源
		system_faction.resources[GlobalEnum.ResourceType.ENERGY] = 10000.0
		system_faction.resources[GlobalEnum.ResourceType.MINE] = 10000.0
		system_faction.resources[GlobalEnum.ResourceType.FOOD] = 10000.0
		system_faction.resources[GlobalEnum.ResourceType.TECH] = 1000.0
		
		print("ResourceManager: 为System faction初始化资源")
		update_resources(system_faction_id)

# 获取指定faction的资源管理对象
func get_faction_resource(faction_id: int) -> FactionResource:
	
	return GlobalNodes.managers.FactionManager.get_faction(faction_id)

# 设置资源数量
func set_resource(faction_id: int, resource_type: GlobalEnum.ResourceType, amount: float) -> bool:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		push_error("ResourceManager: 找不到faction " + str(faction_id))
		return false
	
	faction_resource.resources[resource_type] = amount
	update_resources(faction_id)
	return true

# 获取资源数量
func get_resource(faction_id: int, resource_type: GlobalEnum.ResourceType) -> float:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		return 0.0
	
	return faction_resource.get_resource(resource_type)

# 修改资源（允许负数）
func change_resource(faction_id: int, resource_type: GlobalEnum.ResourceType, amount: float) -> bool:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		push_error("ResourceManager: 找不到faction " + str(faction_id))
		return false
	
	faction_resource.resources[resource_type] += amount
	update_resources(faction_id)
	return true

# 批量修改资源（允许负数）
func change_multi_resource(faction_id: int, resource_changes: Dictionary) -> bool:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		push_error("ResourceManager: 找不到faction " + str(faction_id))
		return false
	
	# 检查所有资源是否足够（如果是减少操作）
	for resource_type in resource_changes:
		var change_amount = resource_changes[resource_type]
		if change_amount < 0:  # 减少资源
			var current_amount = faction_resource.get_resource(resource_type)
			if current_amount + change_amount < 0:
				print("ResourceManager: faction ", faction_id, " 资源 ", resource_type, " 不足")
				return false
	
	# 应用所有更改
	for resource_type in resource_changes:
		var change_amount = resource_changes[resource_type]
		faction_resource.resources[resource_type] += change_amount
	
	update_resources(faction_id)
	return true

# 单项资源检查
func check_resource(faction_id: int, resource_type: GlobalEnum.ResourceType, amount: float) -> bool:
	var current_amount = get_resource(faction_id, resource_type)
	return current_amount >= amount

# 获取所有资源信息
func get_all_resources(faction_id: int) -> Dictionary:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		return {}
	
	return faction_resource.get_all_resources()

# 发送资源更新信号
func update_resources(faction_id: int) -> void:
	var resources = get_all_resources(faction_id)
	GlobalSignalBus.resource_updated.emit(faction_id, resources)

# =============================================================================
# 预资源系统
# =============================================================================

# 设置预资源数量
func set_resource_production(faction_id: int, resource_type: GlobalEnum.ResourceType, amount: float) -> bool:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		push_error("ResourceManager: 找不到faction " + str(faction_id))
		return false
	
	faction_resource.resource_productions[resource_type] = amount
	update_resource_productions(faction_id)
	return true

# 获取预资源数量
func get_resource_production(faction_id: int, resource_type: GlobalEnum.ResourceType) -> float:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		return 0.0
	
	return faction_resource.get_resource_production(resource_type)

# 修改预资源
func change_resource_production(faction_id: int, resource_type: GlobalEnum.ResourceType, amount: float) -> bool:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		push_error("ResourceManager: 找不到faction " + str(faction_id))
		return false
	
	faction_resource.resource_productions[resource_type] += amount
	update_resource_productions(faction_id)
	return true

# 批量修改预资源
func change_multi_resource_production(faction_id: int, resource_changes: Dictionary) -> bool:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		push_error("ResourceManager: 找不到faction " + str(faction_id))
		return false
	
	# 检查所有预资源是否足够（如果是减少操作）
	for resource_type in resource_changes:
		var change_amount = resource_changes[resource_type]
		if change_amount < 0:  # 减少预资源
			var current_amount = faction_resource.get_resource_production(resource_type)
			if current_amount + change_amount < 0:
				print("ResourceManager: faction ", faction_id, " 预资源 ", resource_type, " 不足")
				return false
	
	# 应用所有更改
	for resource_type in resource_changes:
		var change_amount = resource_changes[resource_type]
		faction_resource.resource_productions[resource_type] += change_amount
	
	update_resource_productions(faction_id)
	return true

# 获取所有预资源信息
func get_all_resource_productions(faction_id: int) -> Dictionary:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		return {}
	
	return faction_resource.get_all_resource_productions()

# 发送预资源更新信号
func update_resource_productions(faction_id: int) -> void:
	var resource_productions = get_all_resource_productions(faction_id)
	GlobalSignalBus.resource_production_updated.emit(faction_id, resource_productions)

# 比对预资源与当前资源（包含额外预添加资源）
func compare_resource_productions_with_current(faction_id: int, additional_resources: Dictionary = {}) -> bool:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		return false
	
	# 检查所有资源类型
	for resource_type in GlobalEnum.ResourceType.values():
		var current_amount = faction_resource.get_resource(resource_type)
		var pre_amount = faction_resource.get_resource_production(resource_type)
		var additional_amount = additional_resources.get(resource_type, 0.0)
		
		var final_amount = current_amount + pre_amount + additional_amount
		
		if final_amount < 0:
			return false
	
	return true

# 重置预资源为零
func reset_resource_productions(faction_id: int) -> bool:
	var faction_resource = get_faction_resource(faction_id)
	if not faction_resource:
		return false
	
	for resource_type in GlobalEnum.ResourceType.values():
		faction_resource.resource_productions[resource_type] = 0.0
	
	update_resource_productions(faction_id)
	return true

# =============================================================================
# 简化信号处理系统
# =============================================================================

# 处理资源修改请求
func _on_resource_modify_request(faction_id: int, resource_dict: Dictionary, result_array: Array) -> void:
	# resource_dict: {GlobalEnum.ResourceType: amount} - 正数为增加，负数为消耗
	# result_array: [bool] - 操作结果，由函数填写
	print("资源修改请求 - 阵营:", faction_id, " 资源:", resource_dict)
	# 执行资源修改
	var success = change_multi_resource(faction_id, resource_dict)
	
	# 设置操作结果
	result_array[0] = success

# 处理资源查询请求  
func _on_resource_query_request(faction_id: int, resource_dict: Dictionary, result_array: Array) -> void:
	# resource_dict: {GlobalEnum.ResourceType: amount} - 查询是否有足够的资源
	# result_array: [bool] - 查询结果，由函数填写
	print("资源查询请求 - 阵营:", faction_id, " 资源:", resource_dict)
	
	# 检查所有资源是否足够
	for resource_type in resource_dict:
		var required_amount = resource_dict[resource_type]
		if not check_resource(faction_id, resource_type, required_amount):
			result_array[0] = false
			return
	
	# 所有资源都足够
	result_array[0] = true

# 处理预资源修改请求
func _on_resource_production_modify_request(faction_id: int, resource_dict: Dictionary, result_array: Array) -> void:
	# resource_dict: {GlobalEnum.ResourceType: amount} - 正数为增加，负数为消耗
	# result_array: [bool] - 操作结果，由函数填写
	print("预资源修改请求 - 阵营:", faction_id, " 资源:", resource_dict)
	# 执行预资源修改
	var success = change_multi_resource_production(faction_id, resource_dict)
	
	# 设置操作结果
	result_array[0] = success

# 处理预资源比对请求
func _on_resource_production_compare_request(faction_id: int, additional_resources: Dictionary, result_array: Array) -> void:
	# additional_resources: 额外的预添加资源字典
	# result_array: [bool] - 比对结果，由函数填写
	print("预资源比对请求 - 阵营:", faction_id, " 额外资源:", additional_resources)
	# 执行预资源比对
	var compare_result = compare_resource_productions_with_current(faction_id, additional_resources)
	
	# 设置比对结果
	result_array[0] = compare_result

# 处理资源更新请求
func _on_resource_update_requested(faction_id: int) -> void:
	"""响应资源更新请求信号，发出当前资源状态"""
	print("ResourceManager: 收到资源更新请求，faction: ", faction_id)
	
	# 发送当前资源状态
	if get_faction_resource(faction_id):
		var resources = get_all_resources(faction_id)
		GlobalSignalBus.resource_updated.emit(faction_id, resources)
		print("ResourceManager: 发送资源更新信号，faction: ", faction_id, " 资源: ", resources)
	else:
		print("ResourceManager: 未找到faction ", faction_id, " 的资源数据")
	
	# 发送预资源状态
	if get_faction_resource(faction_id):
		var resource_productions = get_all_resource_productions(faction_id)
		GlobalSignalBus.resource_production_updated.emit(faction_id, resource_productions)
		print("ResourceManager: 发送预资源更新信号，faction: ", faction_id, " 预资源: ", resource_productions)
	else:
		print("ResourceManager: 未找到faction ", faction_id, " 的预资源数据")
