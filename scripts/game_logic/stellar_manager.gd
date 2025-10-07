extends Manager

# 创建一个字典用于保存恒星系数据，使用ID作为键
var stellars: Dictionary = {}  # 键为stellar_id（int），值为stellar节点
var stellar_scene = preload("res://scenes/game_object/stellar/stellar.tscn")

# ID管理
var next_stellar_id: int = 10000  # 下一个可用的五位数ID，从10000开始

# 恒星系更新计数器
var stellar_update_counter: int = 0
var is_waiting_for_stellar_updates: bool = false

func _ready() -> void:
	super._ready()
	
	# 连接信号
	GlobalSignalBus.connect("stellar_update_completed", _on_stellar_update_completed)

# 信号处理：当恒星系更新完成时
func _on_stellar_update_completed():
	stellar_update_counter -= 1
	print("StellarManager: 恒星系更新完成，剩余计数: ", stellar_update_counter)
	
	# 检查是否所有恒星系都完成了更新
	if is_waiting_for_stellar_updates and stellar_update_counter <= 0:
		is_waiting_for_stellar_updates = false
		print("StellarManager: 所有恒星系更新完成")
		GlobalSignalBus.all_stellar_update_completed.emit.call_deferred()
	
	
#region 恒星系管理函数
func clear_all():
	# 清空恒星系数据
	stellars.clear()
	print("已清空所有恒星系数据")
#endregion

#region 操作函数
func add_stellar(stellar: Node):
	if not stellars.has(stellar.stellar_id):
		stellars[stellar.stellar_id] = stellar
	else:
		print("恒星系已存在 ID:", stellar.stellar_id)

# 建立一个恒星系到另一个恒星系的单向连接关系
func connect_stellars(from_stellar: Node, to_stellar: Node, distance: int = 1) -> bool:
	# 检查两个恒星系是否存在
	if not stellars.has(from_stellar.stellar_id) or not stellars.has(to_stellar.stellar_id):
		push_error("尝试连接不存在的恒星系 ID: " + str(from_stellar.stellar_id) + " 或 " + str(to_stellar.stellar_id))
		return false
	
	# 建立单向连接，使用ID
	# 检查是否已经存在连接
	if from_stellar.stellar_connections.has(to_stellar.stellar_id):
		print("连接已存在 ID: " + str(from_stellar.stellar_id) + " -> " + str(to_stellar.stellar_id))
		return false
	
	# 添加连接，使用ID
	from_stellar.stellar_connections[to_stellar.stellar_id] = distance
	
	return true

func create_stellar(input_name: String, input_position: Vector3, stellar_type: String) -> Node:
	var stellar_instance = stellar_scene.instantiate()
	# 分配五位数ID
	stellar_instance.stellar_id = next_stellar_id
	next_stellar_id += 1
	
	stellar_instance.set_basic_infos(input_name, input_position, stellar_type)
	
	# 设置默认所有者为System faction
	var system_faction_id = 1000
	stellar_instance.set_faction_owner(system_faction_id)

	
	add_stellar(stellar_instance)
	
	return stellar_instance
#endregion

#region 恒星系信息获取函数
# 获取恒星系节点引用 - 使用ID作为主要方式
func get_stellar_by_id(stellar_id: int) -> Node:
	if stellars.has(stellar_id):
		return stellars[stellar_id]
	else:
		push_error("找不到恒星系 ID: " + str(stellar_id))
		return null

func get_stellar_position(stellar: Node) -> Vector3:
	if not stellars.has(stellar.stellar_id):
		push_error("尝试获取不存在的恒星系位置 ID: " + str(stellar.stellar_id))
		return Vector3.ZERO
	
	return stellar.global_position

# 获取所有恒星系ID
func get_all_stellar_ids() -> Array:
	return stellars.keys()

# 获取恒星系数量
func get_stellar_count() -> int:
	return stellars.size()

# 计算两个恒星系之间的最短距离，使用MathTools中的Dijkstra算法
func calculate_stellar_path(stellar_A: Node, stellar_B: Node) -> Dictionary:
	# 检查两个恒星系是否存在
	if not stellars.has(stellar_A.stellar_id) or not stellars.has(stellar_B.stellar_id):
		push_error("尝试计算不存在的恒星系距离 ID: " + str(stellar_A.stellar_id) + " 或 " + str(stellar_B.stellar_id))
		return {"distance": -1, "path": []}
	
	# 构建恒星系连接图（邻接表），使用ID
	var stellar_graph: Dictionary = {}
	
	# 为每个恒星系创建连接字典
	for stellar_id in stellars:
		var stellar_obj = stellars[stellar_id]
		stellar_graph[stellar_id] = stellar_obj.stellar_connections
	
	# 使用MathTools中的通用Dijkstra算法计算最短距离
	return MathTools.dijkstra(stellar_graph, stellar_A.stellar_id, stellar_B.stellar_id)

# 所有权管理函数
func set_stellar_owner(stellar_id: int, new_faction_id: int) -> bool:
	"""设置恒星系所有权，直接操作faction数据"""
	var stellar = get_stellar_by_id(stellar_id)
	if not stellar:
		push_error("StellarManager: 找不到恒星系 ID: " + str(stellar_id))
		return false
	
	var old_faction_id = stellar.get_faction_owner()
	
	# 如果所有者相同，直接返回
	if old_faction_id == new_faction_id:
		return true
	
	# 从旧所有者移除
	if old_faction_id != -1:
		var old_faction = GlobalNodes.managers.FactionManager.get_faction(old_faction_id)
		if old_faction:
			var index = old_faction.owned_stellar_ids.find(stellar_id)
			if index != -1:
				old_faction.owned_stellar_ids.remove_at(index)
	
	# 添加到新所有者
	if new_faction_id != -1:
		var new_faction = GlobalNodes.managers.FactionManager.get_faction(new_faction_id)
		if new_faction:
			if not new_faction.owned_stellar_ids.has(stellar_id):
				new_faction.owned_stellar_ids.append(stellar_id)
	
	# 设置恒星系对象的所有者
	stellar.set_faction_owner(new_faction_id)
	
	print("StellarManager: 恒星系 ", stellar.name, " (ID:", stellar_id, ") 所有权转移: ", old_faction_id, " -> ", new_faction_id)
	return true

func get_stellar_owner(stellar_id: int) -> int:
	"""获取恒星系所有者"""
	var stellar = get_stellar_by_id(stellar_id)
	if stellar:
		return stellar.get_faction_owner()
	return -1

func get_stellars_by_faction(faction_id: int) -> Array:
	"""获取指定阵营拥有的所有恒星系"""
	var faction_stellars = []
	for stellar in stellars.values():
		if stellar.get_faction_owner() == faction_id:
			faction_stellars.append(stellar)
	return faction_stellars

# 触发恒星系更新并等待完成
func trigger_stellar_update() -> void:
	"""发出stellar_update信号并等待所有恒星系完成更新"""
	print("StellarManager: 开始恒星系更新...")
	
	# 记录需要更新的恒星系数量
	var total_stellars = stellars.size()
	if total_stellars == 0:
		print("StellarManager: 没有恒星系需要更新")
		GlobalSignalBus.all_stellar_update_completed.emit()
		return
	
	# 初始化计数器
	stellar_update_counter = total_stellars
	is_waiting_for_stellar_updates = true
	
	print("StellarManager: 发出stellar_update信号，共有 ", total_stellars, " 个恒星系需要更新")
	
	# 发出stellar_update信号
	GlobalSignalBus.stellar_update.emit()
	
	print("StellarManager: 等待所有恒星系完成更新...")
	# 注意：不再使用await等待，而是通过信号机制在_on_stellar_update_completed中处理完成

#endregion
