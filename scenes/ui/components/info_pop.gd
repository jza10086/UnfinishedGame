extends PanelContainer

@export var rich_label: RichTextLabel
@export var circle_texture_bar: TextureProgressBar


# 悬浮窗控制变量
var is_hovering: bool = false
var hover_check: bool = false
var hover_delay: float = 0.1  # 悬浮延迟（秒）
var hover_timer: float = 0.0  # 悬浮计时器


func set_houver_check(enabled: bool) -> void:
	"""启用或禁用悬浮检测"""
	hover_check = enabled
	if enabled:
		hover_timer = 0.0  # 重置计时器
		set_process(true)
	else:
		set_process(false)

# 设置 alt_mode 和进度条显示
func set_alt_mode(enabled: bool, _total_delay: float = 0.5):
	"""设置 alt_mode 并显示进度条"""
	print("InfoPop: 设置 alt_mode =", enabled, ", 延迟 =", _total_delay)
	if enabled and circle_texture_bar:
		circle_texture_bar.visible = true
		circle_texture_bar.value = 0
		print("InfoPop: 进度条显示")
	elif circle_texture_bar:
		circle_texture_bar.visible = false

# 设置进度条数值
func set_progress(value: float):
	"""设置进度条的值 (0-100)"""
	if circle_texture_bar:
		circle_texture_bar.value = value


# 在鼠标指针处显示InfoPop，确保不会超出视图
func show_label_by_mouse(text: String):
	"""在鼠标位置显示InfoPop，自动调整位置防止超出屏幕"""
	# 获取鼠标位置
	var mouse_pos = get_global_mouse_position()
	
	# 显示并调整位置
	visible = true
	global_position = mouse_pos
	_adjust_position()

	# 设置文本
	rich_label.bbcode_text = text

# 在指定位置显示InfoPop
func show_label_by_node(text: String, target_position: Vector2):
	"""在指定位置显示InfoPop，自动调整位置防止超出屏幕"""
	# 显示并调整位置
	visible = true
	global_position = target_position
	_adjust_position()

	# 设置文本
	rich_label.bbcode_text = text

#region 内部方法

func _ready():
	
	# 连接鼠标进入和离开事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(delta):
	# 只在启用悬浮检测时进行检查
	if not hover_check:
		return
	
	# 如果鼠标不在InfoPop区域内，开始计时
	if not is_hovering:
		hover_timer += delta
		# 达到延迟时间后才销毁
		if hover_timer >= hover_delay:
			hover_check = false
			queue_free()
	else:
		# 鼠标在区域内时重置计时器
		hover_timer = 0.0

func _on_mouse_entered():
	"""鼠标进入InfoPop区域"""
	is_hovering = true

func _on_mouse_exited():
	"""鼠标离开InfoPop区域"""
	is_hovering = false
	
func _adjust_position():
	"""调整位置，确保不会超出屏幕边界"""
	var screen_size = get_viewport().get_visible_rect().size
	var popup_size = size
	var popup_pos = global_position
	
	# 检查右边界
	if popup_pos.x + popup_size.x > screen_size.x:
		popup_pos.x = screen_size.x - popup_size.x
	
	# 检查下边界
	if popup_pos.y + popup_size.y > screen_size.y:
		popup_pos.y = screen_size.y - popup_size.y
	
	# 确保不会超出左上角
	popup_pos.x = max(0, popup_pos.x)
	popup_pos.y = max(0, popup_pos.y)
	
	global_position = popup_pos

#endregion
