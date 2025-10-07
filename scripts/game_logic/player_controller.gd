extends Node
# PlayerController - 处理玩家交互逻辑的核心控制器
# 负责管理选中状态、处理单位之间的交互、响应玩家输入

# 当前选中的对象
var current_selected_unit: Unit = null
# 前一个选中的对象（用于多步操作）
var previous_selected_unit: Unit = null

# 输入状态跟踪
var is_left_mouse_pressed: bool = false
var is_right_mouse_pressed: bool = false

func _ready():
	# 监听全局输入事件（用于处理点击空白区域）
	set_process_unhandled_input(true)

#region 命令判断逻辑 - Command Logic

# 处理左键点击单位
func handle_left_click_unit(unit: Unit):
	
	# 清除之前选中单位的高亮
	if current_selected_unit != null:
		current_selected_unit.set_highlight_visible(false)
	
	# 更新选中状态
	previous_selected_unit = current_selected_unit
	current_selected_unit = unit
	
	# 设置新选中单位的高亮
	unit.set_highlight_visible(true)
	
	# 根据单位类型执行相应逻辑
	if unit is Fleet:
		handle_fleet_left_click(unit)
	elif unit is Stellar:
		handle_stellar_left_click(unit)

# 处理右键点击单位
func handle_right_click_unit(unit: Unit):
	# 检查是否有已选中的单位
	if current_selected_unit == null:
		print("右键无效: 无选中单位")
		return
	
	# 处理Fleet到Stellar的移动指令
	if current_selected_unit is Fleet and unit is Stellar:
		# 检查是否按住Shift键进行路径追加
		if Input.is_key_pressed(KEY_SHIFT):
			handle_fleet_append_path_command(current_selected_unit, unit)
		else:
			handle_fleet_to_stellar_command(current_selected_unit, unit)
	elif current_selected_unit is Fleet and unit is Fleet:
		print("右键攻击: ", current_selected_unit.name, " → ", unit.name)
		handle_fleet_to_fleet_command(current_selected_unit, unit)
	else:
		print("右键无效: 不支持的交互组合")

# 处理点击空白区域
func handle_click_empty_area():
	if current_selected_unit != null:
		print("取消选中: ", current_selected_unit.name)
		
		# 清除高亮
		current_selected_unit.set_highlight_visible(false)
		
		previous_selected_unit = current_selected_unit
		current_selected_unit = null
		
		# 通过GlobalSignalBus发送取消选择信号
		GlobalSignalBus.unit_deselected.emit()
		
		# TODO: 清除高亮效果、关闭UI等

# 处理右键点击空白区域
func handle_right_click_empty_area():
	# 右键点击空白区域不会取消选中
	pass

#endregion

#region 具体命令 - Specific Commands

# 处理舰队左键选中
func handle_fleet_left_click(fleet: Fleet):
	# 通过GlobalSignalBus发送选择信号
	GlobalSignalBus.unit_selected.emit(fleet)
	
	print("选中舰队: ", fleet.name)

# 处理恒星系左键选中
func handle_stellar_left_click(stellar: Stellar):
	# 通过GlobalSignalBus发送选择信号
	GlobalSignalBus.unit_selected.emit(stellar)
	
	print("选中恒星系: ", stellar.name)

# 处理舰队移动到恒星系命令
func handle_fleet_to_stellar_command(fleet: Fleet, target_stellar: Stellar):
	var action = FleetMoveAction.new(fleet.fleet_id, target_stellar.stellar_id)
	GlobalNodes.managers.ActionManager.add_action(action)


# 处理舰队追加路径到恒星系命令
func handle_fleet_append_path_command(fleet: Fleet, target_stellar: Stellar):
	
	GlobalNodes.managers.ActionManager.get_actions(fleet,
	"FleetMoveAction")[0].append_path_to_target(target_stellar.stellar_id)

# 处理舰队攻击舰队命令
func handle_fleet_to_fleet_command(_attacking_fleet: Fleet, _target_fleet: Fleet):
	# TODO: 调用战斗系统
	pass

# 处理舰队创建命令
func handle_fleet_create_command(_fleet_name: String, _stellar_name: String):
	pass

#endregion


#region 核心逻辑 - Core Logic

# 处理点击空白区域的输入
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 左键点击空白区域，取消选中
			handle_click_empty_area()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键点击空白区域，不取消选中，只是提示
			handle_right_click_empty_area()

# 中央交互处理函数 - 连接到所有Unit的selected信号
func on_unit_selected(unit: Unit, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_left_click_unit(unit)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click_unit(unit)

# 获取当前选中的单位
func get_current_selected_unit() -> Unit:
	return current_selected_unit

# 检查是否有选中的单位
func has_selected_unit() -> bool:
	return current_selected_unit != null

# 强制取消选中
func clear_selection():
	if current_selected_unit != null:
		handle_click_empty_area()

#endregion





#region player action

func set_current_researching_tech(faction_id: int, tech_type: StringName):
	var action = SingleSetCurrentResearchingTechAction.new(faction_id,tech_type)
	GlobalNodes.managers.ActionManager.add_action(action)




#endregion
