extends Control

# 自定义弹出菜单
class_name JzaPopupMenu

# 信号定义
signal option_selected(option_id: int, option_text: String)
signal menu_closed

# 节点引用
@onready var custom_menu: PanelContainer = $CustomMenu
@onready var vbox_container: VBoxContainer = $CustomMenu/VBoxContainer

# 菜单选项按钮列表
var option_buttons: Array[Button] = []
var is_menu_visible: bool = false

func _ready():
	# 连接所有按钮的信号
	_connect_button_signals()
	
	# 设置初始状态
	custom_menu.visible = false
	
	# 连接输入事件以处理点击外部关闭
	set_process_input(true)

func _connect_button_signals():
	"""连接所有选项按钮的信号"""
	option_buttons.clear()
	
	for child in vbox_container.get_children():
		if child is Button:
			option_buttons.append(child)
			# 连接按钮的 pressed 信号
			if not child.pressed.is_connected(_on_option_pressed):
				child.pressed.connect(_on_option_pressed.bind(child))

func _input(event):
	"""处理全局输入事件，用于右键呼出菜单和点击外部关闭菜单"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键点击显示菜单
			if not is_menu_visible:
				show_menu(event.global_position)
			else:
				hide_menu()
		elif is_menu_visible:
			# 检查点击是否在菜单区域外
			var menu_rect = custom_menu.get_global_rect()
			var mouse_pos = event.global_position
			
			if not menu_rect.has_point(mouse_pos):
				hide_menu()

func show_menu(menu_position: Vector2):
	"""在指定位置显示菜单"""
	# 设置菜单位置
	custom_menu.position = menu_position
	
	# 确保菜单不会超出屏幕边界
	_adjust_menu_position()
	
	# 显示菜单
	custom_menu.visible = true
	is_menu_visible = true
	
	# 将菜单移到最前面
	move_child(custom_menu, get_child_count() - 1)

func hide_menu():
	"""隐藏菜单"""
	custom_menu.visible = false
	is_menu_visible = false
	menu_closed.emit()

func _adjust_menu_position():
	"""调整菜单位置，确保不会超出屏幕边界"""
	var screen_size = get_viewport().get_visible_rect().size
	var menu_size = custom_menu.size
	var menu_pos = custom_menu.position
	
	# 检查右边界
	if menu_pos.x + menu_size.x > screen_size.x:
		menu_pos.x = screen_size.x - menu_size.x
	
	# 检查下边界
	if menu_pos.y + menu_size.y > screen_size.y:
		menu_pos.y = screen_size.y - menu_size.y
	
	# 确保不会超出左上角
	menu_pos.x = max(0, menu_pos.x)
	menu_pos.y = max(0, menu_pos.y)
	
	custom_menu.position = menu_pos

func _on_option_pressed(button: Button):
	"""处理选项按钮点击事件"""
	var option_id = option_buttons.find(button)
	var option_text = button.text
	
	# 发射信号
	option_selected.emit(option_id, option_text)
	print("选项ID ", option_id, " 被点击: ", option_text)
	# 隐藏菜单
	hide_menu()

# 公共接口方法
func add_menu_option(text: String, icon: Texture2D = null):
	"""添加新的菜单选项"""
	var button = Button.new()
	button.text = text
	if icon:
		button.icon = icon
	
	vbox_container.add_child(button)
	option_buttons.append(button)
	
	# 连接信号
	button.pressed.connect(_on_option_pressed.bind(button))

func add_separator():
	"""添加分隔符"""
	var separator = HSeparator.new()
	vbox_container.add_child(separator)

func clear_menu():
	"""清空所有菜单选项"""
	for child in vbox_container.get_children():
		child.queue_free()
	option_buttons.clear()

func set_option_enabled(option_id: int, enabled: bool):
	"""设置指定选项的启用状态"""
	if option_id >= 0 and option_id < option_buttons.size():
		option_buttons[option_id].disabled = not enabled

func set_option_style(option_id: int, style_normal: StyleBox = null, style_hover: StyleBox = null, style_pressed: StyleBox = null):
	"""为指定选项设置自定义样式"""
	if option_id >= 0 and option_id < option_buttons.size():
		var button = option_buttons[option_id]
		if style_normal:
			button.add_theme_stylebox_override("normal", style_normal)
		if style_hover:
			button.add_theme_stylebox_override("hover", style_hover)
		if style_pressed:
			button.add_theme_stylebox_override("pressed", style_pressed)
