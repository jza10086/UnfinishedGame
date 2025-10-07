extends Control

# 左侧选项卡容器组件 - 简化版本
@onready var tab_container: TabContainer = $HBoxContainer/TabContainer
@onready var button_container: VBoxContainer = $HBoxContainer/ScrollContainer/ButtonContainer
@onready var default_button: Button = $HBoxContainer/ScrollContainer/ButtonContainer/Button

var tab_buttons: Array[BaseButton] = []  # 存储所有选项卡按钮的数组
var button_group: ButtonGroup = ButtonGroup.new()

signal tab_changed(tab_index: int)

func _ready():
	setup_tabs()

func setup_tabs():
	"""简化的标签页设置"""
	tab_buttons.clear()
	
	# 获取预设Tab
	var preset_tabs = {}
	for child in tab_container.get_children():
		if child is Control:
			preset_tabs[child.name] = child
	
	# 处理预设按钮
	for button in button_container.get_children().filter(func(child): return child is BaseButton):
		if button == default_button:
			button.visible = false
			continue
			
		# 检查是否有匹配的预设Tab
		if preset_tabs.has(button.name):
			_setup_button_at_index(button, preset_tabs[button.name].get_index())
		else:
			print("删除预设按钮: ", button.name, " - 未找到对应Tab")
			button.queue_free()
	
	# 激活第一个有效按钮并切换到对应tab
	for i in range(tab_buttons.size()):
		if tab_buttons[i] != null and tab_buttons[i] != default_button:
			tab_buttons[i].button_pressed = true
			tab_container.current_tab = i
			break

func _setup_button(button: BaseButton, index: int):
	"""设置按钮属性"""
	# 确保数组足够大
	while tab_buttons.size() <= index:
		tab_buttons.append(null)
	
	tab_buttons[index] = button
	button.toggle_mode = true
	button.button_group = button_group
	button.disabled = false
	
	# 连接信号前先断开可能存在的连接
	if button.pressed.is_connected(_on_tab_button_pressed):
		button.pressed.disconnect(_on_tab_button_pressed)
	
	button.pressed.connect(_on_tab_button_pressed.bind(index))

func _setup_button_at_index(button: BaseButton, index: int):
	"""在指定索引位置设置按钮"""
	_setup_button(button, index)

func create_tab_button(tab_name: String, tab_scene: PackedScene = null) -> Button:
	"""创建新的标签按钮"""
	var button = default_button.duplicate() if default_button else Button.new()
	
	# 清除旧连接
	if button.pressed.is_connected(_on_tab_button_pressed):
		button.pressed.disconnect(_on_tab_button_pressed)
	
	button_container.add_child(button)
	button.text = tab_name
	button.visible = true
	
	_setup_button(button, tab_buttons.size())
	
	# 创建Tab内容
	var tab_content = tab_scene.instantiate() if tab_scene else _create_default_tab(tab_name)
	tab_container.add_child(tab_content)
	
	return button

func _create_default_tab(tab_name: String) -> Control:
	"""创建默认Tab内容"""
	var tab = Control.new()
	tab.name = tab_name
	
	var label = Label.new()
	label.text = "这是 " + tab_name + " 的内容"
	label.anchors_preset = Control.PRESET_CENTER
	tab.add_child(label)
	
	return tab

func _on_tab_button_pressed(index: int):
	"""按钮点击处理"""
	tab_container.current_tab = index
	tab_changed.emit(index)

func add_tab(tab_content: Control, tab_name: String):
	"""添加新标签"""
	tab_container.add_child(tab_content)
	tab_content.name = tab_name

func remove_tab(index: int):
	"""移除标签"""
	if index < 0 or index >= tab_container.get_tab_count():
		return
	
	var tab = tab_container.get_child(index)
	tab_container.remove_child(tab)
	tab.queue_free()
	setup_tabs()
