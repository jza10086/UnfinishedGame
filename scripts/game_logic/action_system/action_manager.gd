extends Manager
# Action系统主管理器
class_name MainActionManager

# Action队列字典（按类别分组）
var action_queues: Dictionary = {"main": [],"fleet": [],"init": []}

# Action ID生成相关
var current_turn: int = 1  # 当前回合数
var turn_action_counter: int = 0  # 当前回合创建的action计数

func _ready():
	super._ready()
	# 连接回合阶段信号
	GlobalSignalBus.turn_phase.connect(_on_turn_phase)

#region action队列操作

# 添加Action
func add_action(action: Action, queue_name: String = "main") -> void:
	# 验证action有效性
	if not action:
		push_error("MainActionManager: 无效的action")
		return

	var validate_once_result = action.validate_once()
	if not validate_once_result[0]:
		print("MainActionManager: Action ", action.get_action_name(), " validate_once验证失败：", validate_once_result[1])
		return

	var validate_result = action.validate()
	if not validate_result[0]:
		print("MainActionManager: Action ", action.get_action_name(), " validate验证失败：", validate_result[1])
		return

	# 自动生成并设置Action ID
	var generated_id = _generate_action_id()
	action.set_action_id(generated_id)	

	# 连接action_progress_updated信号
	action.action_progress_updated.connect(_on_action_progress_updated)

	# 预执行
	action.pre_execute()

	# 添加到队列
	action_queues[queue_name].append(action)

	# 发射队列变化信号
	GlobalSignalBus.action_queue_changed.emit()

	print("MainActionManager: 已添加Action ", action.get_action_name(), " 到队列 ", queue_name, "，ID: ", generated_id)

# 移除Action
func remove_action(action: Action, queue_name: String = "main") -> void:
	if not action:
		push_error("MainActionManager: 无效的Action")
		return

	action.removed()

	# 断开信号连接
	if action.action_progress_updated.is_connected(_on_action_progress_updated):
		action.action_progress_updated.disconnect(_on_action_progress_updated)

	# 从队列中移除
	action_queues[queue_name].erase(action)
	
	# 发射队列变化信号
	GlobalSignalBus.action_queue_changed.emit()

# 清空指定队列中的所有Action
func clear_all_actions(queue_name: String = "main") -> void:
	if not action_queues.has(queue_name):
		push_error("MainActionManager: 队列 '%s' 不存在" % queue_name)
		return
	
	# 获取队列副本以避免在迭代时修改队列
	var actions_to_remove = action_queues[queue_name].duplicate()
	
	# 逐个移除Action（这样能确保信号正确断开连接）
	for action in actions_to_remove:
		remove_action(action)
	
	print("MainActionManager: 已清空队列 '%s' 中的 %d 个Action" % [queue_name, actions_to_remove.size()])

# 执行所有Action
func execute_all_actions():
	
	for queue_name in action_queues.keys():
		execute_queue(queue_name)

	print("MainActionManager: 所有队列执行完成")
	await get_tree().process_frame
	GlobalSignalBus.turn_phase_completed.emit()

func execute_queue(queue_name: String) -> void:
	if not action_queues.has(queue_name):
		push_error("MainActionManager: 队列 '%s' 不存在" % queue_name)
		return
	
	# 创建action队列的副本，避免在遍历时修改集合

	var actions_to_execute = action_queues[queue_name].duplicate()
	
	for action in actions_to_execute:
		if action in action_queues[queue_name]:
			action.execute()
	
	print("MainActionManager: 队列 '%s' 执行完成" % queue_name)

# 撤销指定Action
func cancel_action(action: Action) -> void:
	action._update_state(Action.ActionState.CANCELLED)


#endregion

# 生成Action ID
func _generate_action_id() -> String:
	turn_action_counter += 1
	# 格式：4位回合数 + 6位计数器（补零）
	return "%04d%06d" % [current_turn, turn_action_counter]

# 统一的Action查询方法
# executer: 执行者节点，为null时不筛选执行者
# action_type: Action类型名称，为空字符串时不筛选类型  
# queue_name: 队列名称，默认为"main"
# 返回: 符合条件的Action数组
func get_actions(executer: Object = null, action_type: String = "", queue_name: String = "main") -> Array:
	var matching_actions: Array = []
	
	if not action_queues.has(queue_name):
		push_error("MainActionManager: 队列 '%s' 不存在" % queue_name)
		return matching_actions
	
	# 遍历指定队列中的所有Action
	for action in action_queues[queue_name]:
		var executer_match: bool = true
		var type_match: bool = true
		
		# 检查执行者是否匹配（如果提供了执行者参数）
		if executer != null:
			executer_match = (action.executer == executer)
		
		# 检查Action类型是否匹配（如果提供了类型参数）
		if action_type != "":
			type_match = (action.get_script().get_global_name() == action_type)
		
		# 只有当所有条件都匹配时才添加到结果中
		if executer_match and type_match:
			matching_actions.append(action)
	
	return matching_actions

# action_progress_updated信号回调
func _on_action_progress_updated(action: Action, new_state: Action.ActionState) -> void:
	match new_state:
		Action.ActionState.PENDING:
			print("MainActionManager: ", action.get_action_name(), "待执行.")
		Action.ActionState.EXECUTING:
			print("MainActionManager: ", action.get_action_name(), "正在执行.")
		Action.ActionState.COMPLETED:
			print("MainActionManager: ", action.get_action_name(), "执行完成.")
			remove_action(action)
		Action.ActionState.FAILED:
			print("MainActionManager: ", action.get_action_name(), "执行失败.")
		Action.ActionState.CANCELLED:
			print("MainActionManager: ", action.get_action_name(), "已撤销.")
			action.cancel()
			remove_action(action)
		Action.ActionState.CHANGED:
			print("MainActionManager: ", action.get_action_name(), "状态已改变.")
			GlobalSignalBus.action_queue_changed.emit()

# 回合阶段响应
func _on_turn_phase(phase: GlobalSignalBus.TurnPhase) -> void:
	match phase:
		GlobalSignalBus.TurnPhase.Action:
			# 在行动阶段开始时更新回合数
			if GlobalNodes.managers.TurnManager != null:
				var new_turn = GlobalNodes.managers.TurnManager.current_turn
				set_current_turn(new_turn)
			execute_all_actions()
		_:
			# 其他阶段不处理
			pass

# 设置当前回合数（通常由TurnManager调用）
func set_current_turn(turn: int) -> void:
	if turn != current_turn:
		current_turn = turn
		turn_action_counter = 0  # 新回合时重置计数器
		print("MainActionManager: 回合更新为 %d，Action计数器重置" % current_turn)
