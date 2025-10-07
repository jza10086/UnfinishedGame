extends JzaPanel

@export var planet_panel: Control
@export var button_container: Control
@export var resource_container: Control
@export var stellar_label: RichTextLabel
@export var resource_container_panel:Control


var button_scene: PackedScene = preload("res://scenes/ui/panel/stellar_panel_button.tscn")


# 当前恒星系引用
var current_stellar: Stellar

# 行星数组引用
var stellar_planets: Array = []

func cleanup():
	pass

func refresh():
	pass

func connect_signals():
	pass

func disconnect_signals():
	pass

# 1. 接受一个stellar对象，初始化相关信息
func set_stellar_reference(stellar: Stellar):
	"""设置恒星系引用并初始化相关信息"""
	current_stellar = stellar

	# 获取恒星系的行星数组
	_get_stellar_planets()
	
	# 清理现有按钮（除了原始按钮）
	clear_dynamic_buttons()
	
	# 根据行星数量创建按钮
	if stellar_planets.size() > 0:
		create_indexed_buttons()

	
# 2. 获取stellar的planets数组
func _get_stellar_planets():
	"""获取当前恒星系的planets数组"""
	if not current_stellar:
		push_error("StellarPanel: 无法获取行星数组，current_stellar为空")
		stellar_planets = []
		return
	
	# 设置行星数组引用
	stellar_planets = current_stellar.planets

# 清理动态创建的按钮
func clear_dynamic_buttons():
	# 遍历容器的所有子节点，移除所有按钮
	for child in button_container.get_children():
		child.queue_free()

# 3. 动态创建按钮并绑定索引回调
func create_indexed_buttons():
	
	# 为每个行星创建按钮
	for i in range(stellar_planets.size()):
		# 实例化按钮场景
		var btn_instance = button_scene.instantiate()
		
		# 设置按钮文本为对应行星的名称
		if btn_instance.has_method("set_text"):
			btn_instance.text = stellar_planets[i].name
		
		# 连接 pressed 信号，绑定对应的行星索引
		btn_instance.pressed.connect(Callable(self, "_on_indexed_button_pressed").bind(i))
		
		# 添加到容器中
		button_container.add_child(btn_instance)
	
	
# 按钮点击回调函数
func _on_indexed_button_pressed(index: int):
	"""处理索引按钮点击事件"""
	
	# 检查索引是否有效
	if index >= stellar_planets.size():
		print("StellarPanel: 索引超出范围，行星数量: ", stellar_planets.size())
		return
	
	# 获取对应的行星
	var selected_planet = stellar_planets[index]
	
	# 切换到对应行星的数据
	init_planet_panel(selected_planet)

# 4. 初始化planet_panel
func init_planet_panel(planet: Planet = null):
	
	if not planet:
		push_error("planet无效")
		return
	
	# 隐藏stellar总览
	hide_stellar_overview()
	
	# 设置planet引用，让planet_panel根据planet初始化
	planet_panel.set_planet_reference(planet)

func show_stellar_overview():
	"""显示stellar总览信息"""
	if not current_stellar:
		print("StellarPanel: 无法显示stellar总览，current_stellar为空")
		return
	
	# 显示stellar_label和resource_container
	stellar_label.show()
	resource_container_panel.show()
	
	# 隐藏planet_panel
	planet_panel.hide()
	
	# 设置stellar_label显示stellar名称
	stellar_label.text = current_stellar.name
	
	# 设置resource_container显示stellar资源
	resource_container.set_resources(current_stellar.get_bonus_resource())

func hide_stellar_overview():
	"""隐藏stellar总览信息"""
	# 隐藏stellar_label和resource_container
	stellar_label.hide()
	resource_container_panel.hide()
	
	# 显示planet_panel
	planet_panel.show()
	
func init_panel(data):
	set_stellar_reference(data)
	# 默认显示stellar总览
	show_stellar_overview()

func _on_exit_button_pressed() -> void:
	disconnect_signals()
	GlobalNodes.UIManager.back_to_main()
	GlobalNodes.managers.CameraManager.reset_height_limit()
	GlobalNodes.managers.CameraManager.focus(current_stellar.position + Vector3(0,200,15),true,1.0,2,7)
	
	


func _on_back_button_pressed() -> void:
	show_stellar_overview()
	GlobalNodes.managers.CameraManager.focus(current_stellar.position + Vector3(0,100,15),true,1.0,2,7)
