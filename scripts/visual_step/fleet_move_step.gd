extends VisualStepBase
class_name FleetMoveStep

var fleet_node: Fleet
var target_pos: Vector3
var description: String

# 使用单一计数器追踪所有并行动画
var animations_to_wait_for: int = 0

# 保持对所有ShipMoveStep实例的引用，防止RefCounted自动释放
var ship_move_steps: Array = []

func _init(p_fleet_node: Fleet, p_target_pos: Vector3):
	self.fleet_node = p_fleet_node
	self.target_pos = p_target_pos
	self.description = "Orchestrate Fleet %s movement" % fleet_node.name

func execute():
	if not is_instance_valid(fleet_node):
		emit_signal("finished")
		return
	
	# 1. 启动 Fleet 节点自身的动画（移动碰撞体、图标等）
	_animate_fleet_center_node()
	
	# 2. 为每艘独立的 top_level 舰船创建移动任务
	_animate_all_ships_to_world_position()
	
	# 如果没有任何动画需要等待，立即完成
	if animations_to_wait_for == 0:
		emit_signal("finished")

# 这个函数只移动舰队的逻辑节点，代表其在地图上的位置
func _animate_fleet_center_node():
	animations_to_wait_for += 1
	var tween = fleet_node.create_tween()
	# 动画时长可以与其他动画协调
	tween.tween_property(fleet_node, "global_position", target_pos, 1.5)
	tween.finished.connect(_on_one_animation_completed)

# 为每艘船创建独立的、基于世界坐标的移动步骤
func _animate_all_ships_to_world_position():
	if fleet_node.ships.is_empty():
		return
		
	# 编队排列逻辑
	var ships_per_column = 3
	var ship_spacing = 5.0
	var total_columns = int((fleet_node.ships.size() + ships_per_column - 1) / float(ships_per_column))
	
	for i in range(fleet_node.ships.size()):
		var ship = fleet_node.ships[i] # ship 现在是 top_level 节点
		animations_to_wait_for += 1
		
		# 1. 计算舰船在编队中的局部偏移位置
		var col = int(i / float(ships_per_column))
		var row = i % ships_per_column
		var ships_in_current_column = min(ships_per_column, fleet_node.ships.size() - col * ships_per_column)
		var x_offset = (col - (total_columns - 1) * 0.5) * ship_spacing
		var z_offset = (row - (ships_in_current_column - 1) * 0.5) * ship_spacing
		var ship_local_offset = Vector3(x_offset, 0, z_offset)
		
		# 2. 核心：计算出舰船最终的世界坐标
		#    这是通过将舰队的目标中心位置与舰船的局部偏移相加得到的。
		var ship_world_target_pos = target_pos + ship_local_offset
		
		# 3. 创建一个全功能的 ShipMoveStep 实例
		#    这个实例将处理单艘船从当前世界位置到目标世界位置的完整动画。
		var ship_move_step = ShipMoveStep.new(ship, ship_world_target_pos)
		
		# 重要：保持对ShipMoveStep的引用，防止RefCounted自动释放
		ship_move_steps.append(ship_move_step)
		
		ship_move_step.finished.connect(_on_one_animation_completed, CONNECT_ONE_SHOT)
		
		# 使用异步调用来确保execute()方法被正确执行
		_start_ship_move_step(ship_move_step)

# 异步辅助方法，用于启动ShipMoveStep
func _start_ship_move_step(ship_move_step: ShipMoveStep):
	ship_move_step.execute()

# 统一的回调函数，每当一个动画（舰队本体或任何一艘船的）完成时调用
func _on_one_animation_completed():
	animations_to_wait_for -= 1
	if animations_to_wait_for <= 0:
		# 清理ShipMoveStep引用
		ship_move_steps.clear()
		emit_signal("finished")
