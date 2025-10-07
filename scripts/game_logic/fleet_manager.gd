extends Manager
#舰队管理器
@export var fleets_container: Node
@onready var fleet_scene = preload("res://scenes/game_object/fleet/fleet.tscn")
# 创建一个字典用于保存舰队数据，使用ID作为键
var fleets: Dictionary = {}  # 键为fleet_id（int），值为fleet节点

# ID管理
var next_fleet_id: int = 100000  # 下一个可用的6位数ID，从100000开始


func _ready() -> void:
	super._ready()
	
	# 连接回合阶段信号
	GlobalSignalBus.turn_phase.connect(_on_turn_phase)

#region 舰队管理函数
func clear_all():
	# 清空舰队数据
	fleets.clear()
	print("已清空所有舰队数据")
#endregion

#region 舰队操作函数
func create_fleet(fleet_name: String) -> Node:
	# 创建新的舰队节点
	var new_fleet = fleet_scene.instantiate()
	new_fleet.name = fleet_name
	# 分配五位数ID
	new_fleet.fleet_id = next_fleet_id
	next_fleet_id += 1
	
	# 设置默认所有者为System faction
	var system_faction_id = 1000
	new_fleet.set_faction_owner(system_faction_id)
	
	# 添加舰队，使用ID作为键
	fleets[new_fleet.fleet_id] = new_fleet
	fleets_container.add_child(new_fleet)
	
	print("创建舰队: ", fleet_name, " (ID:", new_fleet.fleet_id, ")")
	return new_fleet

# 移除舰队
func remove_fleet(fleet_name: String) -> bool:
	if not fleets.has(fleet_name):
		print("舰队不存在: ", fleet_name)
		return false
	
	var fleet = fleets[fleet_name]
	
	# 从字典中移除
	fleets.erase(fleet_name)
	
	# 从场景树中移除
	if fleet.get_parent():
		fleet.get_parent().remove_child(fleet)
	
	# 释放内存
	fleet.queue_free()
	
	print("成功移除舰队: ", fleet_name)
	return true
#endregion



#region 舰队信息获取函数
# 通过ID获取舰队 - 主要方法
func get_fleet_by_id(fleet_id: int) -> Node:
	if fleets.has(fleet_id):
		return fleets[fleet_id]
	else:
		push_error("找不到舰队 ID: " + str(fleet_id))
		return null

# 获取所有舰队ID
func get_all_fleet_ids() -> Array:
	return fleets.keys()

# 获取舰队数量
func get_fleet_count() -> int:
	return fleets.size()

# 检测恒星系的舰队
func get_fleets_by_stellar() -> Dictionary:
	var stellar_groups: Dictionary = {}
	
	# 遍历所有舰队，按当前恒星系分组，使用ID
	for fleet_id in fleets.keys():
		var fleet = fleets[fleet_id]
		var current_stellar = fleet.get_current_stellar()
		
		# 如果该恒星系还没有记录，创建新数组
		if not stellar_groups.has(current_stellar):
			stellar_groups[current_stellar] = []
		
		# 将舰队添加到对应恒星系的数组中
		stellar_groups[current_stellar].append(fleet)
	
	return stellar_groups

# 检测存在多个舰队的恒星系
func get_stellar_with_multiple_fleets() -> Dictionary:
	var all_stellar_groups = get_fleets_by_stellar()
	var multiple_fleet_stellars: Dictionary = {}
	
	# 筛选出有多个舰队的恒星系
	for stellar_name in all_stellar_groups.keys():
		var fleet_list = all_stellar_groups[stellar_name]
		if fleet_list.size() > 1:
			multiple_fleet_stellars[stellar_name] = fleet_list
	print("检测到存在多个舰队的恒星系: ", multiple_fleet_stellars)
	return multiple_fleet_stellars


#endregion

#region 舰队移动处理函数
# 循环检测并处理所有舰队的移动，直到所有舰队都没有剩余移动路径
func process_all_fleet_movements() -> void:
	var queue_num = AnimationSequencer.get_max_queue_num() + 1  # 获取当前最大队列编号并加1
	var _total_movements = 0
	var movement_occurred = true
	var safety_counter = 0
	var max_iterations = 1000  # 防止无限循环的安全计数器
	
	while movement_occurred and safety_counter < max_iterations:
		movement_occurred = false
		safety_counter += 1
		var current_round_movements = 0
		
		# 直接遍历所有舰队，对有移动路径的舰队执行一步移动
		for fleet in fleets.values():
			if fleet and fleet._check_fleet_moveable():
				fleet.fleet_move(queue_num)
				movement_occurred = true
				_total_movements += 1
				current_round_movements += 1
		
		if current_round_movements == 0:
			break
		
		queue_num += 1
	
	if safety_counter >= max_iterations:
		push_warning("舰队移动处理达到最大迭代次数，可能存在问题")
	

func get_fleet_owner(fleet_id: int) -> int:
	"""获取舰队所有者"""
	var fleet = get_fleet_by_id(fleet_id)
	if fleet:
		return fleet.get_faction_owner()
	return -1

func set_fleet_owner(fleet_id: int, new_faction_id: int) -> bool:
	"""设置舰队所有权，直接操作faction数据"""
	var fleet = get_fleet_by_id(fleet_id)
	if not fleet:
		push_warning("无法找到ID为 " + str(fleet_id) + " 的舰队")
		return false
	
	var old_faction_id = fleet.get_faction_owner()
	
	# 如果所有者没有变化，直接返回
	if old_faction_id == new_faction_id:
		return true
	
	# 从旧阵营的舰队列表中移除
	var old_faction = GlobalNodes.managers.FactionManager.get_faction(old_faction_id)
	if old_faction and old_faction.fleets.has(fleet_id):
		old_faction.fleets.erase(fleet_id)
	
	# 添加到新阵营的舰队列表
	var new_faction = GlobalNodes.managers.FactionManager.get_faction(new_faction_id)
	if new_faction:
		new_faction.fleets.append(fleet_id)
	
	# 设置舰队的所有者
	fleet.set_faction_owner(new_faction_id)
	
	print("舰队 ", fleet.name, " (ID:", fleet_id, ") 所有权从 ", old_faction_id, " 转移到 ", new_faction_id)
	return true

#endregion


# 回合阶段响应
func _on_turn_phase(phase: GlobalSignalBus.TurnPhase) -> void:
	match phase:
		GlobalSignalBus.TurnPhase.FleetMove:
			process_all_fleet_movements()
			await get_tree().process_frame
			GlobalSignalBus.turn_phase_completed.emit()
			print("FleetManager: 舰队移动阶段完成")
		_:
			# 其他阶段不处理
			pass
