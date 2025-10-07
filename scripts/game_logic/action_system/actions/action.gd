@abstract

extends Resource
class_name Action

# Action状态枚举
enum ActionState {
	PENDING,     # 等待执行
	EXECUTING,   # 正在执行
	COMPLETED,   # 执行完成
	FAILED,      # 执行失败
	CANCELLED,   # 已取消
	CHANGED,     # 状态已改变
}

# 执行器引用
var executer

# Action状态
var state: ActionState = ActionState.PENDING

# Action名称
var action_name: String

# Action唯一标识符（由MainActionManager自动生成）
var action_id: String = ""

# 是否可以被中断
var can_interrupt: bool = true

# 错误信息（当状态为FAILED时）
var error_message: String = ""

# 一次性验证结果缓存
var initial_validation_done: bool = false
var initial_validation_result: Array = [false, ""]

# 统一的进度更新信号
signal action_progress_updated(action,new_progress: ActionState)

#region 虚方法

# add_action前，静态方法
# static func pre_execute() -> void:

@abstract
# 一次性验证逻辑，validate()之前，返回[bool，错误信息string]]
func validate_once()

@abstract
# execute()前，add_action中，验证Action是否可以执行，返回[bool，错误信息string]]
func validate()

@abstract
# add_action中，validate()后
func pre_execute()

@abstract
# 具体执行逻辑
func execute()


# 完成回调
func _finished() -> void:
	_update_state(ActionState.COMPLETED)

#endregion

# 获取Action描述
func get_description() -> String:
	if not action_name.is_empty():
		return action_name
	else:
		return "未知Action"

# 撤销后返回消耗
func cancel() -> void:
	print("执行撤销操作，返回消耗")


# 当Action被移除时调用，清理资源或状态
func removed() -> void:
	pass

# 连接执行器信号
func connect_executer_signals() -> void:
	pass

# 获取Action名称
func get_action_name() -> String:
	return action_name



# 初始化Action
func _init():
	# 连接信号
	connect_executer_signals()
	action_name = "action基类"

# 获取错误信息
func get_error_message() -> String:
	return error_message

# 设置Action ID（由MainActionManager调用）
func set_action_id(id: String) -> void:
	action_id = id

# 统一的状态更新方法
func _update_state(new_state: ActionState, error_msg: String = "") -> void:
	# 对于CHANGED状态，不更新内部state，只发送信号
	if new_state == ActionState.CHANGED:
		action_progress_updated.emit(self, new_state)
		return  # 直接返回，不改变实际状态

	if state == new_state:
		return  # 状态没有改变，不需要更新
	
	state = new_state
	
	# 如果是失败状态，保存错误信息
	if new_state == ActionState.FAILED:
		error_message = error_msg
	
	# 发出统一的进度更新信号
	action_progress_updated.emit(self, new_state)
