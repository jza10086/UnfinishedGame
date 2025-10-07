extends Control

# --- 可配置的变量 ---
@export var scroll_speed: float = 80.0
@export var pause_duration: float = 1.5

# --- 节点引用 ---
@export var control_node: Control
@export var pause_timer: Timer

# --- 状态机 ---
enum State {
	STATIC,           # 静止（文本未超出）
	PAUSED_AT_START,  # 在起点暂停
	SCROLLING_TO_END, # 向终点滚动
	PAUSED_AT_END,    # 在终点暂停
	SCROLLING_TO_START # 向起点滚动
}

var current_state: State = State.STATIC
var area_x_size: float = 0.0
var node_x_size: float = 0.0

func _ready():
	resized.connect(_on_self_resized)
	# 连接计时器超时信号
	pause_timer.timeout.connect(_on_pause_timer_timeout)

	

# 用于检测是否需要滚动
func check_x_size():

	# 初始化area尺寸
	area_x_size = self.size.x

	control_node.set_deferred("size:x", 0.0)
	
	# 直接获取 control_node 的宽度
	node_x_size = control_node.size.x

	
	# 核心逻辑：检测节点是否超出容器
	if node_x_size > area_x_size:
		# 如果超出，开启滚动模式，从"在起点暂停"状态开始循环
		set_process(true)
		_change_state(State.PAUSED_AT_START)
		control_node.position.x = 0
	else:
		# 如果未超出，设置为静止状态，禁用process
		set_process(false)
		_change_state(State.STATIC)


func _process(delta: float):
	# 根据当前状态执行相应的操作
	match current_state:
		State.SCROLLING_TO_END:
			# 向左移动
			control_node.position.x -= scroll_speed * delta
			# 防止超出终点位置
			var end_pos_x = area_x_size - node_x_size
			if control_node.position.x <= end_pos_x:
				control_node.position.x = end_pos_x
				_change_state(State.PAUSED_AT_END)
				
		State.SCROLLING_TO_START:
			# 向右移动
			control_node.position.x += scroll_speed * delta
			# 防止超出起点位置
			if control_node.position.x >= 0:
				control_node.position.x = 0
				_change_state(State.PAUSED_AT_START)


# 状态切换的中央控制器
func _change_state(new_state: State):
	current_state = new_state
	
	match current_state:
		State.STATIC:
			# 确保计时器停止
			if not pause_timer.is_stopped():
				pause_timer.stop()
		State.PAUSED_AT_START:
			# 在起点开始计时
			pause_timer.start(pause_duration)
		State.PAUSED_AT_END:
			# 在终点开始计时
			pause_timer.start(pause_duration)
		State.SCROLLING_TO_END:
			pass # 立即开始滚动，无需额外操作
		State.SCROLLING_TO_START:
			pass # 立即开始滚动，无需额外操作

# 当暂停计时器结束时被调用
func _on_pause_timer_timeout():
	# 根据暂停前的状态，切换到下一个滚动状态
	if current_state == State.PAUSED_AT_START:
		_change_state(State.SCROLLING_TO_END)
	elif current_state == State.PAUSED_AT_END:
		_change_state(State.SCROLLING_TO_START)


func _on_self_resized():

	control_node.position.x = 0
	# 检测尺寸
	check_x_size()
