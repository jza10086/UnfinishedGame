# 动画序列器 (Autoload 单例)
# 负责按顺序执行一个"可视步骤"队列，并等待每个步骤的动画完成。
extends Node

# 所有队列完成时发出的信号
signal all_queues_finished

var total_animation_queue: Dictionary = {}
var max_queue_num: int = 0  # 当前最大队列编号
var current_executing_queue: int = 0  # 当前正在执行的队列编号
var pending_animations_count: int = 0  # 当前队列中待完成的动画数量

func _ready() -> void:
	# 连接回合阶段信号
	GlobalSignalBus.turn_phase.connect(_on_turn_phase)

func add_animation(animation: VisualStepBase, queue_num: int = 1):
	# 检查队列编号不能大于当前最大编号+1
	if queue_num > max_queue_num + 1:
		printerr("尝试添加到未来的动画队列: ", queue_num, "，当前最大编号: ", max_queue_num)
		return
	
	# 队列编号必须大于0
	if queue_num <= 0:
		printerr("队列编号必须大于0")
		return
	
	# 如果队列不存在，创建新队列
	if not total_animation_queue.has(queue_num):
		total_animation_queue[queue_num] = []
		# 更新最大队列编号
		if queue_num > max_queue_num:
			max_queue_num = queue_num
	
	total_animation_queue[queue_num].append(animation)
	print(self.name, ": 添加动画到队列 ", queue_num, "，当前最大编号: ", max_queue_num)

func start_animation() -> void:
	
	if total_animation_queue.is_empty():
		print(self.name, ": 没有可执行的动画队列")
		_finish_all_animations()
		return
	current_executing_queue = 1
	_execute_next_queue()

func _execute_next_queue() -> void:
	# 检查当前队列是否存在
	if not total_animation_queue.has(current_executing_queue):
		print(self.name, ": 队列 ", current_executing_queue, " 不存在，跳过")
		current_executing_queue += 1
		if current_executing_queue <= max_queue_num:
			_execute_next_queue()
		else:
			_finish_all_animations()
		return
	
	var animations = total_animation_queue[current_executing_queue]
	if animations.is_empty():
		print(self.name, ": 队列 ", current_executing_queue, " 为空，跳过")
		current_executing_queue += 1
		if current_executing_queue <= max_queue_num:
			_execute_next_queue()
		else:
			_finish_all_animations()
		return
	
	print(self.name, ": 开始执行队列 ", current_executing_queue)
	pending_animations_count = animations.size()
	
	# 执行当前队列的所有动画
	for animation in animations:
		animation.finished.connect(_on_single_animation_finished, CONNECT_ONE_SHOT)
		animation.execute()

func _on_single_animation_finished() -> void:
	pending_animations_count -= 1
	if pending_animations_count <= 0:
		# 当前队列的所有动画都完成了
		print(self.name, ": 队列 ", current_executing_queue, " 执行完成")
		current_executing_queue += 1
		if current_executing_queue <= max_queue_num:
			_execute_next_queue()
		else:
			_finish_all_animations()

func _finish_all_animations() -> void:
	# 清空队列并重置
	total_animation_queue.clear()
	max_queue_num = 0
	current_executing_queue = 0
	pending_animations_count = 0
	# 发出所有队列完成信号
	all_queues_finished.emit()
	print("AnimationSequencer: 动画阶段完成")
	GlobalSignalBus.turn_phase_completed.emit.call_deferred()

# 回合阶段响应
func _on_turn_phase(phase: GlobalSignalBus.TurnPhase) -> void:
	match phase:
		GlobalSignalBus.TurnPhase.Animation:
			start_animation()
		_:
			# 其他阶段不处理
			pass

func get_max_queue_num() -> int:
	return max_queue_num
