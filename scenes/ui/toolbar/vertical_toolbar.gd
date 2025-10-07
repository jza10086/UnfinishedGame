extends Control

# 展开动画相关变量
@onready var background: Panel = $Background
@onready var tool_container: HBoxContainer = $Background/ToolContainer
@onready var tool_button_container: VBoxContainer = $Background/ToolContainer/ToolButtonContainer
@onready var tool_label_container: VBoxContainer = $Background/ToolContainer/ToolLabelContainer

var tween: Tween
var is_expanded: bool = false
var collapsed_width: float  # 从编辑器获取折叠时的宽度
var expanded_width: float   # 从编辑器获取展开时的宽度
var animation_duration: float = 0.075  # 动画持续时间

# 鼠标检测相关
var mouse_in_area: bool = false
var expand_delay_timer: Timer

func _ready():
	# 从编辑器获取宽度数据
	get_widths_from_editor()
	# 初始化工具栏为折叠状态
	setup_initial_state()
	setup_mouse_detection()
	setup_timer()


func get_widths_from_editor():
	"""从编辑器中的场景数据获取宽度"""
	# 折叠宽度：从ToolButtonContainer的宽度获取 + 边距*2
	collapsed_width = tool_button_container.size.x + 8*2
	
	# 展开宽度：从Background的宽度获取
	expanded_width = background.size.x
	
	# 确保有合理的默认值
	if collapsed_width <= 0:
		collapsed_width = 64.0
	if expanded_width <= collapsed_width:
		expanded_width = 145.0  # 从场景文件中的设置获取
	
	print("从编辑器获取宽度 - 折叠: ", collapsed_width, ", 展开: ", expanded_width)

func setup_initial_state():
	"""设置初始折叠状态"""
	# 设置Background为折叠宽度
	background.size.x = collapsed_width
	# 通过clip_contents自动隐藏超出部分

func setup_timer():
	"""设置延迟计时器"""
	expand_delay_timer = Timer.new()
	expand_delay_timer.wait_time = 0.1  # 100ms延迟
	expand_delay_timer.one_shot = true
	add_child(expand_delay_timer)
	expand_delay_timer.timeout.connect(_on_expand_delay_timeout)

func setup_mouse_detection():
	"""设置鼠标检测"""
	# 为整个工具栏添加鼠标检测
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 确保可以接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_PASS

func _on_mouse_entered():
	"""鼠标进入时准备展开工具栏"""
	mouse_in_area = true
	expand_delay_timer.start()

func _on_expand_delay_timeout():
	"""延迟后展开工具栏"""
	if mouse_in_area and not is_expanded:
		expand_toolbar()

func _on_mouse_exited():
	"""鼠标离开时收缩工具栏"""
	mouse_in_area = false
	expand_delay_timer.stop()
	if is_expanded:
		collapse_toolbar()

func expand_toolbar():
	"""展开工具栏动画"""
	is_expanded = true
	
	# 停止之前的动画
	if tween:
		tween.kill()
	
	tween = create_tween()
	
	# 只需要动画Background的宽度
	tween.tween_property(background, "size:x", expanded_width, animation_duration)
	
	# 设置缓动效果
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

func collapse_toolbar():
	"""收缩工具栏动画"""
	is_expanded = false
	
	# 停止之前的动画
	if tween:
		tween.kill()
	
	tween = create_tween()
	
	# 只需要动画Background的宽度
	tween.tween_property(background, "size:x", collapsed_width, animation_duration)
	
	# 设置缓动效果
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)

# 可选：手动控制展开/收缩的方法
func toggle_toolbar():
	"""手动切换工具栏状态"""
	if is_expanded:
		collapse_toolbar()
	else:
		expand_toolbar()

# 可选：设置展开宽度
func set_expanded_width(width: float):
	"""设置展开时的宽度"""
	expanded_width = width

# 可选：设置折叠宽度
func set_collapsed_width(width: float):
	"""设置折叠时的宽度"""
	collapsed_width = width
	if not is_expanded:
		background.size.x = collapsed_width

# 可选：设置动画持续时间
func set_animation_duration(duration: float):
	"""设置动画持续时间"""
	animation_duration = duration
