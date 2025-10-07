extends PanelContainer

@export var existing_building_menu: Control  # slot_menu类型
@export var available_building_menu: Control  # slot_menu类型
@export var tab_container:TabContainer

func change_tab(index:int):
	tab_container.current_tab = index


# 信号：向外部发送slot点击事件
signal building_pressed(menu_type: String, index: int, slot_data)

func _ready() -> void:
	# 连接两个slot_menu的信号
	existing_building_menu.slot_pressed_with_tag.connect(_on_existing_slot_pressed)
	available_building_menu.slot_pressed_with_tag.connect(_on_available_slot_pressed)

func set_building_data(available_tile_types: Array, colony_slot_array: Array):
	"""
	设置建筑数据
	available_tile_types: 可用建筑的tile_type数组
	colony_slot_array: colony的完整slot_array数据
	"""
	setup_available_buildings(available_tile_types)
	setup_existing_buildings(colony_slot_array)

func get_building_data_by_tile_type(tile_type: String) -> Dictionary:
	"""根据tile_type获取完整的建筑数据"""
	var tile_data = TileJsonLoader.get_tile_by_type(tile_type)
	var texture = TileJsonLoader.get_tile_texture(tile_type)
	
	return {
		"tile_type": tile_type,
		"texture": texture,
		"data": tile_data
	}

#region 可用建筑操作
func setup_available_buildings(tile_types: Array):
	"""设置可用建筑列表"""
	# 清空现有slots
	available_building_menu.clear_all_slots()
	
	# 为每个tile_type创建slot
	for tile_type in tile_types:
		var texture = TileJsonLoader.get_tile_texture(tile_type)
		# 使用统一的create_slot接口：状态=已占用(2)，纹理，显示文本，数据
		available_building_menu.create_slot(2, texture, "", tile_type)

func _on_available_slot_pressed(_menu_tag: String, index: int, slot_data, _slot_state):
	"""处理可用建筑slot点击"""
	print("Building_menu: 可用建筑slot被点击 - 索引:", index, " 数据:", slot_data)
	
	# 获取完整的建筑数据
	var building_data = get_building_data_by_tile_type(slot_data)
	
	# 向外部发送信号，传递完整的建筑数据
	building_pressed.emit("available", index, building_data)


#endregion

#region 现存建筑操作
func setup_existing_buildings(colony_slot_array: Array):
	"""根据colony的slot_array设置已建造建筑列表"""
	# 清空现有slots
	existing_building_menu.clear_all_slots()
	
	# 为每个slot创建对应的slot实例
	for i in range(colony_slot_array.size()):
		var slot_data = colony_slot_array[i]
		
		if slot_data.is_empty():
			# 空slot：状态=空闲(0)
			existing_building_menu.create_slot(0, null, "", "")
		else:
			# 获取slot中的建筑信息
			var tile_type = slot_data.keys()[0]  # 获取第一个tile_type
			var tile_info = slot_data[tile_type]
			var remain_turns = tile_info.get("remain_turns", 0)
			
			# 根据剩余回合数判断状态
			var slot_state: int
			if remain_turns > 0:
				slot_state = 1  # RESERVED - 建造中
			else:
				slot_state = 2  # OCCUPIED - 建造完成
			
			# 获取纹理
			var texture = TileJsonLoader.get_tile_texture(tile_type)
			
			# 创建slot，传递tile_type作为数据
			existing_building_menu.create_slot(slot_state, texture, str(remain_turns), tile_type)



func _on_existing_slot_pressed(_menu_tag: String, index: int, slot_data, slot_state):
	"""处理已建造建筑slot点击"""
	print("Building_menu: 已建造建筑slot被点击 - 索引:", index, " 数据:", slot_data, " 状态", slot_state)
	
	# 向外部发送信号
	building_pressed.emit("existing", index, slot_data)

#endregion
