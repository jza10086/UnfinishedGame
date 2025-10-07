extends UnitAction
class_name FleetMoveAction

var fleet: Node3D
var target_stellar: Node3D
var fleet_id: int
var target_stellar_id: int
var complete_moving_path: Array = [] # 完整的移动路径（恒星系ID数组）
var current_moving_path: Array = []  # 当前移动路径（恒星系ID数组）
var complete_moving_pos_path: Array = [] # 完整的位置路径
var current_moving_pos_path: Array = []  # 当前位置路径
var path_preview_nodes: Array = []  # 存储路径预览节点的数组

func _init(p_fleet_id: int, p_target_stellar_id: int) -> void:
	fleet_id = p_fleet_id
	target_stellar_id = p_target_stellar_id
	
	# 获取目标恒星系名称用于显示
	var target_stellar_obj = GlobalNodes.managers.StellarManager.get_stellar_by_id(target_stellar_id)
	var target_stellar_name = target_stellar_obj.name if target_stellar_obj else "未知恒星系"
	var fleet_obj = GlobalNodes.managers.FleetManager.get_fleet_by_id(fleet_id)
	var fleet_name = fleet_obj.name if fleet_obj else "未知舰队"
	action_name = "FleetMoveAction: " + fleet_name + " 前往 " + target_stellar_name

func undo() -> void:
	# 撤销操作
	clear_path_previews()

func pre_execute() -> void:
	# 获取同一个fleet的所有FleetMoveAction
	var existing_move_actions = GlobalNodes.managers.ActionManager.get_actions(fleet, "FleetMoveAction")
	
	# 移除现有的FleetMoveAction
	if existing_move_actions.size() > 0:
		print("移除现有的FleetMoveAction，确保只有一个活动的移动操作")
		GlobalNodes.managers.ActionManager.remove_action(existing_move_actions[0])
	
	# 更新完整路径预览
	update_path_previews()


func removed() -> void:
	# 清理路径预览
	clear_path_previews()

func execute() -> void:
	# 设置舰队移动路径（位置路径）
	fleet.moving_pos_path = current_moving_pos_path
	
	# 计算舰队移动后的实际位置（恒星系）
	var moves_made = current_moving_path.size() - 1  # 减去起点
	var current_stellar_index = 0
	
	# 找到当前舰队所在恒星系在complete_moving_path中的索引
	var current_stellar_id = fleet.get_current_stellar_id()
	for i in range(complete_moving_path.size()):
		if complete_moving_path[i] == current_stellar_id:
			current_stellar_index = i
			break
	
	# 计算移动后的位置
	var new_stellar_index = current_stellar_index + moves_made
	if new_stellar_index < complete_moving_path.size():
		var new_stellar_id = complete_moving_path[new_stellar_index]
		fleet.set_current_stellar_id(new_stellar_id)
		print("舰队移动到 ID: ", new_stellar_id)
	
	# 更新complete_moving_path，移除已经经过的恒星系
	if moves_made > 0 and complete_moving_path.size() > moves_made:
		for i in range(moves_made):
			if complete_moving_path.size() > 1:  # 保留至少一个元素（当前位置）
				complete_moving_path.remove_at(0)
				complete_moving_pos_path.remove_at(0)
	
	# 检查是否到达最终目标
	if complete_moving_path.size() <= 1 or fleet.get_current_stellar_id() == target_stellar_id:
		_update_state(ActionState.COMPLETED)
	else:
		# 重新计算下一回合的移动路径
		calculate_current_moving_path()
	
	update_path_previews()

func validate() -> Array:
	# 验证fleet_id是否有效
	if fleet_id <= 0:
		print("舰队ID无效: ", fleet_id)
		return [false, ""]

	
	fleet = GlobalNodes.managers.FleetManager.get_fleet_by_id(fleet_id)
	target_stellar = GlobalNodes.managers.StellarManager.get_stellar_by_id(target_stellar_id)
	executer = fleet



	# 验证舰队是否存在
	if not fleet:
		print("舰队不存在 ID: ", fleet_id)
		return [false, ""]
	
	# 验证目标恒星系是否存在
	if not target_stellar:
		print("目标恒星系不存在 ID: ", target_stellar_id)
		return [false, ""]
	



	# 检查是否有有效路径
	calculate_complete_moving_pos_path()
	if complete_moving_path.is_empty():
		return [false, ""]
	
	# 计算当前回合的移动路径
	calculate_current_moving_path()
	if current_moving_path.is_empty():
		return [false, ""]
	
	return [true, ""]

func _on_on_unit_executed() -> void:
	# 更新舰队当前恒星系
	fleet.set_current_stellar_id(target_stellar_id)
	print("舰队移动完成 ID: ", target_stellar_id)
	# 清理路径预览
	clear_path_previews()
	_finished()

func calculate_complete_moving_pos_path() -> void:
	# 获取当前恒星系对象引用
	var current_stellar_id = fleet.get_current_stellar_id()
	var current_stellar_obj = GlobalNodes.managers.StellarManager.get_stellar_by_id(current_stellar_id)
	
	var path_result = GlobalNodes.managers.StellarManager.calculate_stellar_path(current_stellar_obj, target_stellar)
	if path_result.distance == -1:
		print("找不到路径 ID: " + str(current_stellar_id) + " -> " + str(target_stellar_id))
		return
	
	# 保存恒星系ID路径
	complete_moving_path = path_result.path.duplicate()
	
	# 构建位置路径
	var moving_pos_path = []
	for stellar_id in complete_moving_path:
		var stellar_obj = GlobalNodes.managers.StellarManager.get_stellar_by_id(stellar_id)
		moving_pos_path.append(GlobalNodes.managers.StellarManager.get_stellar_position(stellar_obj))
	
	complete_moving_pos_path = moving_pos_path
	
func calculate_current_moving_path() -> void:
	# 确保已经计算了完整路径
	if complete_moving_path.is_empty():
		return
	
	# 获取舰队的移动点数
	var fleet_move_points = fleet.move_point
	
	# 当前路径从当前位置开始，最多移动move_point个恒星系
	var max_moves = min(fleet_move_points, complete_moving_path.size() - 1)
	
	# 构建当前移动的恒星系路径
	current_moving_path = []
	for i in range(max_moves + 1):  # +1 包含起点
		if i < complete_moving_path.size():
			current_moving_path.append(complete_moving_path[i])
	
	# 构建当前移动的位置路径
	current_moving_pos_path = []
	for i in range(current_moving_path.size()):
		if i < complete_moving_pos_path.size():
			current_moving_pos_path.append(complete_moving_pos_path[i])

func append_path_to_target(new_target_stellar_id: int) -> bool:
	# 获取新目标恒星系对象并验证ID有效性
	var new_target_stellar = GlobalNodes.managers.StellarManager.get_stellar_by_id(new_target_stellar_id)
	if not new_target_stellar:
		print("新目标恒星系不存在，ID: ", new_target_stellar_id)
		return false
	
	# 如果complete_moving_path为空，则从当前舰队位置开始计算到新目标的路径
	if complete_moving_path.is_empty():
		var current_stellar_id = fleet.get_current_stellar_id()
		var current_stellar_obj = GlobalNodes.managers.StellarManager.get_stellar_by_id(current_stellar_id)
		var initial_path_result = GlobalNodes.managers.StellarManager.calculate_stellar_path(current_stellar_obj, new_target_stellar)
		if initial_path_result.distance == -1:
			print("找不到路径 ID: " + str(current_stellar_id) + " -> " + str(new_target_stellar_id))
			return false
		
		# 设置新的完整路径
		complete_moving_path = initial_path_result.path.duplicate()
		
		# 构建位置路径
		var moving_pos_path = []
		for stellar_id in complete_moving_path:
			var stellar_obj = GlobalNodes.managers.StellarManager.get_stellar_by_id(stellar_id)
			moving_pos_path.append(GlobalNodes.managers.StellarManager.get_stellar_position(stellar_obj))
		complete_moving_pos_path = moving_pos_path
		
		target_stellar = new_target_stellar
		target_stellar_id = new_target_stellar_id
		action_name = "FleetMoveAction: " + fleet.name + " 前往 " + new_target_stellar.name
		
		# 重新计算当前移动路径
		calculate_current_moving_path()
		return true
	
	# 从当前路径的最后一个恒星系到新目标计算路径
	var current_end_stellar_id = complete_moving_path[-1]
	var current_end_stellar = GlobalNodes.managers.StellarManager.get_stellar_by_id(current_end_stellar_id)
	
	var path_result = GlobalNodes.managers.StellarManager.calculate_stellar_path(current_end_stellar, new_target_stellar)
	if path_result.distance == -1:
		print("找不到路径 ID: " + str(current_end_stellar_id) + " -> " + str(new_target_stellar_id))
		return false
	
	# 追加新路径（去除重复的起点）
	if path_result.path.size() > 1:
		for i in range(1, path_result.path.size()):
			complete_moving_path.append(path_result.path[i])
			var stellar_obj = GlobalNodes.managers.StellarManager.get_stellar_by_id(path_result.path[i])
			complete_moving_pos_path.append(GlobalNodes.managers.StellarManager.get_stellar_position(stellar_obj))
	
	# 更新目标
	target_stellar = new_target_stellar
	target_stellar_id = new_target_stellar_id
	action_name = "FleetMoveAction: " + fleet.name + " 前往 " + new_target_stellar.name
	
	# 重新计算当前移动路径
	calculate_current_moving_path()
	
	print("路径追加成功: 新的完整路径长度为 ", complete_moving_path.size())
	update_path_previews()
	_update_state(ActionState.CHANGED)
	return true

# 路径预览管理方法（仿照FleetMoveCommand.gd）
func update_path_previews():
	# 使用complete_moving_pos_path进行预览显示
	# 计算需要的路径段数
	var needed_segments = 0
	if complete_moving_pos_path.size() >= 2:
		needed_segments = complete_moving_pos_path.size() - 1
	
	var current_segments = path_preview_nodes.size()
	
	# 如果需要更多路径段，创建新的
	if needed_segments > current_segments:
		for i in range(current_segments, needed_segments):
			var start_position = complete_moving_pos_path[i]
			var end_position = complete_moving_pos_path[i + 1]
			
			start_position += Vector3(0, 10, 0)
			end_position += Vector3(0, 10, 0)
			
			# 从VFXPool获取path_3d实例
			var path_3d = VFXPool.get_path_3d()
			
			# 将路径预览添加到场景树中
			if fleet and fleet.get_tree():
				fleet.get_tree().current_scene.add_child(path_3d)
				
				# 使用3d_path的create_visual_path方法创建可视化路径
				path_3d.create_visual_path(start_position, end_position)
				
				# 将路径预览节点添加到数组中便于管理
				path_preview_nodes.append(path_3d)
	
	# 如果路径段过多，回收多余的
	elif needed_segments < current_segments:
		var excess_count = current_segments - needed_segments
		for i in range(excess_count):
			var path_node = path_preview_nodes.pop_back()
			if is_instance_valid(path_node):
				if path_node.get_parent():
					path_node.get_parent().remove_child(path_node)
				VFXPool.return_path_3d(path_node)
	
	# 更新现有路径段的位置
	for i in range(min(needed_segments, path_preview_nodes.size())):
		var start_position = complete_moving_pos_path[i]
		var end_position = complete_moving_pos_path[i + 1]
		
		start_position += Vector3(0, 10, 0)
		end_position += Vector3(0, 10, 0)
		
		var path_node = path_preview_nodes[i]
		if is_instance_valid(path_node):
			path_node.create_visual_path(start_position, end_position)

# 清理路径预览
func clear_path_previews():
	for path_node in path_preview_nodes:
		if is_instance_valid(path_node):
			if path_node.get_parent():
				path_node.get_parent().remove_child(path_node)
			VFXPool.return_path_3d(path_node)
	path_preview_nodes.clear()

# 显示当前移动路径的预览
func show_current_path_preview():
	# 先清理现有预览
	clear_path_previews()
	
	# 如果有当前移动路径，则显示预览
	if current_moving_pos_path.size() >= 2:
		# 临时保存complete_moving_pos_path
		var temp_complete_pos_path = complete_moving_pos_path.duplicate()
		# 用current_moving_pos_path替换complete_moving_pos_path来显示预览
		complete_moving_pos_path = current_moving_pos_path.duplicate()
		# 更新预览
		update_path_previews()
		# 恢复complete_moving_pos_path
		complete_moving_pos_path = temp_complete_pos_path
