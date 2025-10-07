extends Control

@export var ghost_node: Sprite2D
@export var building_menu: Control
@export var describe_label: RichTextLabel
@export var resource_container:Control
@export var name_label:RichTextLabel
@export var tiles:Node2D


# 当前选中的建筑类型
var selected_building_type: String = ""
# 当前选中的插槽索引
var current_selected_slot: int = -1

# 行星引用（数据源）
var planet_reference: Planet
# 殖民地引用
var colony

func _ready() -> void:
	# 连接building_menu的信号
	building_menu.building_pressed.connect(_on_building_menu_pressed)
	
	# 连接tiles的瓦片点击信号
	tiles.tile_clicked.connect(_on_tile_clicked)

func set_planet_reference(planet: Planet):
	"""设置行星引用并初始化所有相关数据"""
	planet_reference = planet
	# 设置殖民地引用
	colony = planet_reference.get_colony_resource()
	
	# 执行完整的初始化
	init_planet_panel()

	# 聚焦星球
	GlobalNodes.managers.CameraManager.focus(planet_reference.global_position + Vector3(0,10,11))


func init_planet_panel():
	"""初始化planet_panel的所有组件和数据"""
	if not planet_reference or not colony:
		print("PlanetPanel: 无法初始化，planet_reference或colony为空")
		return
	
	# 初始化building_menu数据
	init_building_menu_data()
	
	# 更新行星信息显示
	update_planet_info()
	
	# 根据colony数据初始化绘制tiles
	init_tiles_from_colony()
	
	# 设置building_menu默认标签页
	building_menu.change_tab(0)


func init_tiles_from_colony():
	"""根据colony数据初始化绘制所有tiles"""
	if not colony:
		print("PlanetPanel: colony为空，无法初始化tiles")
		return
	
	# 将colony数据传递给tiles节点进行绘制
	tiles.init_tiles_from_colony_data(colony)
	
	# 默认隐藏tiles（只在建筑建造模式时显示）
	tiles.hide()


func update_planet_info():
	"""更新行星信息显示（必须有planet_reference）"""
	if not planet_reference:
		print("PlanetPanel: 无法更新行星信息，planet_reference为空")
		return
	
	# 更新行星名称
	if name_label:
		name_label.text = planet_reference.name
	
	# 更新行星描述
	if describe_label:
		describe_label.text = planet_reference.describe
	
	# 更新资源显示
	if resource_container:
		var bonus_resource = planet_reference.get_bonus_resource()
		resource_container.set_resources(bonus_resource)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			clear_selection()

#region 通用建筑操作

func _on_building_menu_pressed(menu_type: String, index: int, slot_data):
	"""处理来自building_menu的信号"""
	
	match menu_type:
		"existing":
			handle_existing_building_pressed(index, slot_data)
		"available":
			handle_available_building_pressed(index, slot_data)
		_:
			print("未知的menu_type: ", menu_type)

func init_building_menu_data():
	"""初始化building_menu的数据（必须有planet_reference）"""
	# 获取可用建筑tile_type列表
	var available_tile_types = get_available_building_tile_types()
	
	# 获取colony的完整slot_array
	var colony_slot_array = get_existing_building_tile_types()
	
	# 传递数据给building_menu
	building_menu.set_building_data(available_tile_types, colony_slot_array)

#endregion

#region 可用建筑操作

func get_available_building_tile_types() -> Array:
	"""获取可用建筑tile_type列表"""
	var building_tiles = TileJsonLoader.get_tiles_by_unit_group("building")
	var tile_types = []
	
	for tile_data in building_tiles:
		var tile_type = tile_data.get("type", "")
		tile_types.append(tile_type)
	
	return tile_types

func handle_available_building_pressed(_index: int, slot_data):
	"""处理可选建筑点击"""
	var tile_type = slot_data.get("tile_type", "")
	
	# 设置选中的建筑类型
	selected_building_type = tile_type
	
	# 设置ghost纹理
	var texture = TileJsonLoader.get_tile_texture(tile_type)
	ghost_node.texture = texture
	ghost_node.visible = true

func clear_selection():
	"""清空建筑选择状态"""
	selected_building_type = ""
	current_selected_slot = -1
	
	ghost_node.visible = false
	
	# 退出建筑建造模式，隐藏tiles
	tiles.hide()


#endregion

#region 现存建筑操作

func handle_existing_building_pressed(index: int, slot_data):
	"""处理已建造建筑点击"""
	print("PlanetPanel点击了已建造建筑，索引: ", index, ", 数据: ", slot_data)
	
	# 设置当前选中的插槽
	current_selected_slot = index
	
	# 检查slot_data是否代表空slot
	if slot_data == null or slot_data == "" or (typeof(slot_data) == TYPE_STRING and slot_data.is_empty()):
		# 空slot，进入建筑建造模式
		# 显示tiles以便建造建筑
		tiles.show()
		# 切换到可用建筑选项卡
		building_menu.change_tab(1)
		
func get_existing_building_tile_types() -> Array:
	"""获取已建造建筑tile_type列表（必须有planet_reference）"""

	# 检查行星是否已殖民
	if not planet_reference.colonized:
		return []

	var tile_types = []

	var slot_array = colony.get_slot_array()

	for i in range(slot_array.size()):
		var slot_data = slot_array[i]
		
		if slot_data.is_empty():
			tile_types.append("")  # 空slot
		else:
			var tile_data_keys = slot_data.keys()
			var tile_type = tile_data_keys[0]  # 获取第一个tile_type
			tile_types.append(tile_type)
	
	return tile_types

#endregion

func _on_tile_clicked(tile_coord: Vector2i) -> void:

	"""处理tiles的瓦片点击事件"""
	# 检查是否有选中的插槽和建筑类型
	if current_selected_slot == -1 or selected_building_type.is_empty():
		return
	
	
	# 调用创建建筑Action的函数
	create_building_action(tile_coord, selected_building_type)

	building_menu.change_tab(0)

func create_building_action(coord: Vector2i, tile_type: String) -> void:
	"""创建BuildingCreateAction并添加到ActionManager"""
	
	# 获取planet的faction_id
	var faction_id = planet_reference.get_faction_owner()
	
	# 执行pre_validate验证
	var pre_validate_result = BuildingCreateAction.pre_validate(faction_id, tile_type)
	if not pre_validate_result[0]:
		print("PlanetPanel: pre_validate验证失败: ", pre_validate_result[1])
		# 清除选择状态
		clear_selection()
		return
	
	# 创建BuildingCreateAction
	var building_action = BuildingCreateAction.new(
		faction_id,
		colony,
		tile_type,
		coord,
		current_selected_slot
	)
	
	# 添加到ActionManager
	GlobalNodes.managers.ActionManager.add_action(building_action)
	
	print("PlanetPanel: 已创建建筑Action - 类型: ", tile_type, ", 坐标: ", coord, ", 槽位: ", current_selected_slot)
	
	# 清除选择状态
	clear_selection()
	
	# 刷新界面显示
	init_planet_panel()
