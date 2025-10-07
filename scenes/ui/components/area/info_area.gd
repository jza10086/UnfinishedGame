extends Control
class_name InfoArea

@export var alt_mode: bool = false
var alt_mode_delay = 0.5

# 悬浮提示信息
var hover_message: String = ""

# 是否启用悬浮提示
var hover_enabled: bool = false

# info_pop场景预加载
var info_pop = preload("res://scenes/ui/components/info_pop.tscn")

# 当前弹窗实例
var current_info_popup: Control = null

# alt_mode 相关计时器
var alt_mode_timer: Timer = null
var is_mouse_over: bool = false
var alt_mode_timeout_reached: bool = false  # 标记计时器是否已超时

func _ready():
	# 连接鼠标事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 创建 alt_mode 计时器
	if alt_mode:
		alt_mode_timer = Timer.new()
		alt_mode_timer.wait_time = alt_mode_delay
		alt_mode_timer.one_shot = true
		alt_mode_timer.timeout.connect(_on_alt_mode_timer_timeout)
		add_child(alt_mode_timer)

# API 1: 设置悬浮提示文本
func set_text(text: String):
	hover_message = text

# API 2: 设置是否启用悬浮提示
func set_enabled(enabled: bool):
	hover_enabled = enabled

# 实时更新进度条
func _process(_delta):
	# 只在 alt_mode 且计时器运行时更新 info_pop 的进度条
	if alt_mode and alt_mode_timer and not alt_mode_timer.is_stopped() and current_info_popup:
		# 计算进度百分比 (0-100)
		var elapsed_time = alt_mode_delay - alt_mode_timer.time_left
		var progress = (elapsed_time / alt_mode_delay) * 100.0
		
		# 通过 info_pop 更新进度条
		current_info_popup.set_progress(progress)

# 鼠标进入事件
func _on_mouse_entered():
	is_mouse_over = true
	
	if not hover_enabled or hover_message == "":
		return
	
	# 如果已有InfoPop，先清理
	if GlobalNodes.UIManager.info_pop:
		GlobalNodes.UIManager.info_pop.queue_free()

	# 创建InfoPop实例
	current_info_popup = info_pop.instantiate()
	GlobalNodes.UIManager.add_child(current_info_popup)
	GlobalNodes.UIManager.info_pop = current_info_popup
	
	# 计算弹窗位置（区域右下角）
	var popup_position = global_position + size
	current_info_popup.show_label_by_node(hover_message, popup_position)
	
	# 如果启用了 alt_mode，设置 info_pop 的 alt_mode 并启动计时器
	if alt_mode and alt_mode_timer:
		alt_mode_timeout_reached = false
		alt_mode_timer.start()
		
		# 通知 info_pop 启用 alt_mode 和进度显示
		current_info_popup.set_alt_mode(true, alt_mode_delay)

# 鼠标离开事件
func _on_mouse_exited():
	is_mouse_over = false
	
	# 如果有InfoPop实例，根据 alt_mode 决定是否启用悬浮检测
	if current_info_popup:
		if not alt_mode:
			# 非 alt_mode 模式：直接启用悬浮检测
			current_info_popup.set_houver_check(true)
		else:
			# alt_mode 模式：只有在计时器已超时的情况下才启用悬浮检测
			if alt_mode_timeout_reached:
				current_info_popup.set_houver_check(true)
				print("alt_mode: 计时器已超时且鼠标离开，启用悬浮检测")
			else:
				# 超时前鼠标离开：直接销毁 info_pop
				current_info_popup.queue_free()
				GlobalNodes.UIManager.info_pop = null
				print("alt_mode: 超时前鼠标离开，直接销毁 info_pop")
		current_info_popup = null  # 清除引用
	
	# 重置 alt_mode 相关状态
	if alt_mode and alt_mode_timer:
		alt_mode_timer.stop()
		alt_mode_timeout_reached = false

# alt_mode 计时器超时回调
func _on_alt_mode_timer_timeout():
	# 设置超时状态为 true，但不在此时启用悬浮检测
	alt_mode_timeout_reached = true
	print("alt_mode 计时器超时，标记超时状态")
