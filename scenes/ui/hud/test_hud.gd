extends JzaPanel

@onready var select_object_label = $BottomControlBar/HBoxContainer/CurrentObject
@onready var action_queue_panel = $ActionList/ActionQueuePanel
@onready var energy_label = $TopStatusBar/VBoxContainer/HBoxContainer/VBoxContainer/ResourcesContainer/Energy/EnergyLabel
@onready var mine_label = $TopStatusBar/VBoxContainer/HBoxContainer/VBoxContainer/ResourcesContainer/Minerals/MineralsLabel
@onready var food_label = $TopStatusBar/VBoxContainer/HBoxContainer/VBoxContainer/ResourcesContainer/Food/FoodLabel
@onready var pre_energy_label = $TopStatusBar/VBoxContainer/HBoxContainer/VBoxContainer/ResourcesContainer2/Energy/EnergyLabel
@onready var pre_mine_label = $TopStatusBar/VBoxContainer/HBoxContainer/VBoxContainer/ResourcesContainer2/Minerals/MineralsLabel
@onready var pre_food_label = $TopStatusBar/VBoxContainer/HBoxContainer/VBoxContainer/ResourcesContainer2/Food/FoodLabel

var current_select_object: Node = null
var current_faction: int = 1000  # 当前faction，默认为System faction (ID: 1000)
@export var turn_manager: Node  # TurnManager的引用
@export var action_manager: MainActionManager  # ActionManager的引用

func _ready():
	GlobalSignalBus.turn_finished.connect(_on_turn_finished)
	# 连接资源更新信号
	GlobalSignalBus.resource_updated.connect(_on_resource_updated)
	GlobalSignalBus.resource_production_updated.connect(_on_resource_production_updated)
	
	# 连接单位选择信号
	GlobalSignalBus.unit_selected.connect(_on_unit_selected)
	GlobalSignalBus.unit_deselected.connect(_on_unit_deselected)
	
	$LeftBottom.visible = false
	
	# 初始化显示当前faction的资源
	print("TestHUD: 初始化，当前faction: ", current_faction)
	# 延迟请求资源更新，确保ResourceManager已经初始化
	await get_tree().process_frame
	# 通过信号请求资源更新
	GlobalSignalBus.resource_update_requested.emit(current_faction)

func init_panel(_data):
	pass

# 响应单位选择信号
func _on_unit_selected(unit: Node):
	current_select_object = unit
	_update_select_object_label()

# 响应单位取消选择信号
func _on_unit_deselected():
	current_select_object = null
	_update_select_object_label()

# 更新选中对象标签显示
func _update_select_object_label():
	if not select_object_label:
		return
		
	if current_select_object == null:
		select_object_label.text = "无选中对象"
		$LeftBottom.visible = false
	elif current_select_object is Stellar:
		var stellar = current_select_object as Stellar
		select_object_label.text = "已选中恒星系: " + stellar.name
		$LeftBottom.visible = true
	elif current_select_object is Fleet:
		var fleet = current_select_object as Fleet
		select_object_label.text = "已选中舰队: " + fleet.name
		$LeftBottom.visible = true
	else:
		select_object_label.text = "已选中: " + current_select_object.name
		$LeftBottom.visible = true

func _process(_delta: float) -> void:
	pass

func _on_current_object_exit_button_pressed() -> void:
	$LeftBottom.visible = false

# 详细信息按钮点击处理
func _on_detial_button_pressed() -> void:
	if current_select_object != null:
		$LeftBottom.visible = false
		if current_select_object is Stellar:
			GlobalNodes.UIManager.change_panel(GlobalNodes.UIManager.
			stellar_panel_scene,current_select_object)
			GlobalNodes.managers.CameraManager.focus(current_select_object.position + Vector3(0,100,15),true)
			GlobalNodes.managers.CameraManager.set_height_limit(2.5, 200.0)
		elif current_select_object is Fleet:
			# 暂时为舰队添加调试信息，后续可以添加舰队详情界面
			var fleet = current_select_object
			print("打开舰队详情: ", fleet.name)
			# TODO: 添加舰队详情界面

func _on_next_turn_button_pressed() -> void:
	var stylebox: StyleBoxFlat = $RightBottom.get_theme_stylebox("panel") as StyleBoxFlat
	print("next_turn_button_pressed")
	$RightBottom/NextTurnButton.disabled = true
	stylebox.border_color = Color(0.2,0.2,0.2,1.0)
	$RightBottom/AnimatedSprite2D.play("sand")
	await $RightBottom/AnimatedSprite2D.animation_finished
	anime1 = true
	_try_finish_button_animation()

func _on_turn_finished():
	anime2 = true
	_try_finish_button_animation()

var anime1 = false
var anime2 = false
# 保证按钮动画两个条件满足
func _try_finish_button_animation():
	if anime1 and anime2:
		var stylebox: StyleBoxFlat = $RightBottom.get_theme_stylebox("panel") as StyleBoxFlat
		$RightBottom/AnimatedSprite2D.play_backwards("sand")
		await $RightBottom/AnimatedSprite2D.animation_finished
		$RightBottom/NextTurnButton.disabled = false
		stylebox.border_color = Color(1.0,1.0,1.0,1.0)
		anime1 = false
		anime2 = false


# 响应资源更新信号
func _on_resource_updated(faction_id: int, resource_dict: Dictionary) -> void:
	# 只更新当前faction的资源显示
	if faction_id != current_faction:
		return
		
	# 更新能源显示
	if energy_label and resource_dict.has(GlobalEnum.ResourceType.ENERGY):
		energy_label.text = MathTools.format_number(resource_dict[GlobalEnum.ResourceType.ENERGY])
	
	# 更新矿物显示
	if mine_label and resource_dict.has(GlobalEnum.ResourceType.MINE):
		mine_label.text = MathTools.format_number(resource_dict[GlobalEnum.ResourceType.MINE])
	
	# 更新食物显示
	if food_label and resource_dict.has(GlobalEnum.ResourceType.FOOD):
		food_label.text = MathTools.format_number(resource_dict[GlobalEnum.ResourceType.FOOD])

# 响应预资源更新信号
func _on_resource_production_updated(faction_id: int, resource_production_dict: Dictionary) -> void:
	# 只更新当前faction的预资源显示
	if faction_id != current_faction:
		return
		
	# 更新预能源显示
	if pre_energy_label and resource_production_dict.has(GlobalEnum.ResourceType.ENERGY):
		pre_energy_label.text = MathTools.format_number(resource_production_dict[GlobalEnum.ResourceType.ENERGY])
	
	# 更新预矿物显示
	if pre_mine_label and resource_production_dict.has(GlobalEnum.ResourceType.MINE):
		pre_mine_label.text = MathTools.format_number(resource_production_dict[GlobalEnum.ResourceType.MINE])
	
	# 更新预食物显示
	if pre_food_label and resource_production_dict.has(GlobalEnum.ResourceType.FOOD):
		pre_food_label.text = MathTools.format_number(resource_production_dict[GlobalEnum.ResourceType.FOOD])

# 切换当前faction
func set_current_faction(faction_id: int) -> void:
	"""设置当前显示的faction，并立即更新资源显示"""
	current_faction = faction_id
	print("TestHUD: 切换到faction ", faction_id)
	
	# 通过信号请求更新当前faction的资源显示
	GlobalSignalBus.resource_update_requested.emit(faction_id)

# 获取当前faction
func get_current_faction() -> int:
	"""获取当前显示的faction ID"""
	return current_faction


func _on_diplomacy_button_pressed() -> void:
	GlobalNodes.UIManager.change_panel(GlobalNodes.UIManager.
	diplomatcy_panel_scene,null)
	
func cleanup():
	pass
	
func refresh():
	pass

func connect_signals():
	pass
	
func disconnect_signals():
	pass


func _on_tech_button_pressed() -> void:
	GlobalNodes.UIManager.change_panel(GlobalNodes.UIManager.
	general_tech_panel_secne,null)


func _on_core_tech_button_pressed() -> void:
	GlobalNodes.UIManager.change_panel(GlobalNodes.UIManager.
	core_tech_panel_scene,null)
