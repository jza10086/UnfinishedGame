# Attach this script to the SubViewportContainer node.
# PanAndZoomView.gd

extends SubViewportContainer

# 将 SubViewport/ContentRoot 节点拖拽到这里
@onready var content_root: Control = $SubViewport/ContentRoot

# 缩放设置
@export var zoom_min: float = 0.2
@export var zoom_max: float = 3.0
@export var zoom_factor: float = 1.1

var is_dragging: bool = false
var zoom_level: Vector2 = Vector2.ONE

func _ready() -> void:
	# 初始化缩放
	content_root.scale = zoom_level

# Control 节点使用 _gui_input 来处理输入事件
func _gui_input(event: InputEvent) -> void:
	
	# 1. 处理鼠标滚轮缩放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
			# 标记事件已处理, 防止传递给其他控件
			accept_event() 
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
			accept_event()
			
	# 2. 处理拖动开始/结束
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = event.is_pressed()
			accept_event()

	# 3. 处理拖动过程
	if event is InputEventMouseMotion and is_dragging:
		# event.relative 是鼠标移动的向量
		# 直接使用像素值，不受缩放影响，保持固定的拖动速度
		content_root.position += event.relative
		accept_event()

# 以鼠标位置为中心进行缩放的函数
func apply_zoom(zoom_change: float) -> void:
	# 限制缩放级别
	var new_zoom_level = zoom_level * zoom_change
	new_zoom_level.x = clampf(new_zoom_level.x, zoom_min, zoom_max)
	new_zoom_level.y = clampf(new_zoom_level.y, zoom_min, zoom_max)

	# 如果缩放级别没有变化（达到了最大/最小值），则不执行任何操作
	if new_zoom_level == zoom_level:
		return

	# 获取鼠标在容器内的局部位置
	var mouse_pos = get_local_mouse_position()
	
	# 计算鼠标位置在内容空间中的位置（缩放前）
	var content_mouse_pos = (mouse_pos - content_root.position) / zoom_level
	
	# 更新缩放级别
	zoom_level = new_zoom_level
	content_root.scale = zoom_level
	
	# 计算新的内容位置，使鼠标位置保持在同一个内容点上
	content_root.position = mouse_pos - content_mouse_pos * zoom_level

func zoom_in() -> void:
	apply_zoom(zoom_factor)

func zoom_out() -> void:
	apply_zoom(1.0 / zoom_factor)
