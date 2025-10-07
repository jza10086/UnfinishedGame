class_name ColonyResource
extends Resource

# Colony持有的tile信息全局变量
# 数据结构：{coord: {tile_type: alt_tile_index}}
var colony_ground_tiles: Dictionary = {}
var colony_building_tiles: Dictionary = {}

# Tile类型统计缓存
# 数据结构：{tile_type: count}
var colony_tile_type_counts: Dictionary = {}

# 槽位系统
# 数据结构：[{tile_type: {alt_tile_index: X, remain_turns: X}}]
var slot_array: Array = []

var is_changed: bool = true

var father_node: Node = null  # 持有该ColonyResource的节点引用

func _init(p_father_node: Node) -> void:
	self.father_node = p_father_node
	for i in range(5):
		slot_array.append({})  # 初始化5个空槽位


#region tile函数

func add_tile(tile_type: String, coord: Vector2i, layer: Dictionary, alt_tile_index: int = 0) -> bool:
	"""
	添加一个tile到colony

	注意手动更新统计
	
	参数:
	- tile_type: tile类型 (如 "grass", "mine", "factory" 等)
	- coord: tile坐标 (Vector2i)
	- layer: 目标层字典 (colony_ground_tiles 或 colony_building_tiles)
	- alt_tile_index: 替代tile索引，默认为0
	
	返回: 添加成功返回true，失败返回false
	"""
	
	# 验证layer参数
	if layer != colony_ground_tiles and layer != colony_building_tiles:
		print("Colony: 无效的layer参数")
		return false
	
	# 验证tile类型
	if not _validate_tile_type(tile_type):
		print("Colony: 无效的tile类型: ", tile_type)
		return false
	
	layer[coord] = {}
	# 添加tile到指定坐标
	layer[coord][tile_type] = alt_tile_index
	
	is_changed = true

	return true

func remove_tile(coord: Vector2i, layer: Dictionary) -> bool:
	"""
	从colony移除指定坐标的tile

	注意手动更新统计
	
	参数:
	- coord: tile坐标 (Vector2i)
	- layer: 目标层字典 (colony_ground_tiles 或 colony_building_tiles)
	
	返回: 移除成功返回true，失败返回false
	"""
	
	# 验证layer参数
	if layer != colony_ground_tiles and layer != colony_building_tiles:
		print("Colony: 无效的layer参数")
		return false
	
	# 检查并移除坐标
	if not layer.erase(coord):
		print("Colony: 坐标 ", coord, " 没有tile，无法移除")
		return false
	
	is_changed = true

	print("Colony: 成功移除坐标 ", coord, " 的tile")
	return true

func get_tile(coord: Vector2i, layer: Dictionary) -> Dictionary:
	"""
	获取指定坐标的tile信息
	
	参数:
	- coord: tile坐标 (Vector2i)
	- layer: 目标层字典 (colony_ground_tiles 或 colony_building_tiles)
	
	返回: {tile_type: alt_tile_index} 字典，如果没有tile则返回空字典
	"""
	
	# 验证layer参数
	if layer != colony_ground_tiles and layer != colony_building_tiles:
		print("Colony: 无效的layer参数")
		return {}
	
	# 检查坐标是否存在
	if not _is_coord_occupied(coord, layer):
		return {}
	
	# 返回指定坐标的tile信息
	return layer[coord].duplicate()

# 辅助函数

func _is_coord_occupied(coord: Vector2i, layer: Dictionary) -> bool:
	"""检查指定坐标在指定层中是否已被占用"""

	# 检查指定layer中的坐标是否被占用
	if layer.has(coord):
		return true

	return false

func _validate_tile_type(tile_type: String) -> bool:
	# 尝试从TileJsonLoader获取tile数据来验证
	var tile_data = TileJsonLoader.get_tile_by_type(tile_type)
	if tile_data.is_empty():
		print("Colony: TileJsonLoader中未找到tile类型: ", tile_type)
		return false
	
	return true

#endregion


#region slot函数

func add_slot() -> int:
	"""
	在array末尾添加一个空槽位
	
	返回: 新添加槽位的索引
	"""
	var new_index = slot_array.size()
	slot_array.append({})
	print("Colony: 添加新槽位，索引: ", new_index)
	return new_index

func set_slot(slot_index: int, tile_type: String, alt_tile_index: int = 0, remain_turns: int = 0) -> bool:
	"""
	设置槽位的tile数据
	
	参数:
	- slot_index: 槽位索引
	- tile_type: tile类型
	- alt_tile_index: 替代tile索引，默认为0
	- remain_turns: 剩余回合数，默认为0
	
	返回: 设置成功返回true，失败返回false
	"""
	if slot_index < 0 or slot_index >= slot_array.size():
		push_error("Colony: 无效的槽位索引: ", slot_index)
		return false
	
	slot_array[slot_index] = {
		tile_type: {
			"alt_tile_index": alt_tile_index,
			"remain_turns": remain_turns
		}
	}
	return true

func remove_slot(slot_index: int) -> bool:
	"""
	移除一个槽位（必须为空）
	
	参数:
	- slot_index: 槽位索引
	
	返回: 移除成功返回true，失败返回false
	"""
	if slot_index < 0 or slot_index >= slot_array.size():
		print("Colony: 无效的槽位索引: ", slot_index)
		return false
	
	# 检查槽位是否为空
	if not slot_array[slot_index].is_empty():
		print("Colony: 槽位 ", slot_index, " 不为空，无法移除")
		return false
	
	slot_array.remove_at(slot_index)
	print("Colony: 移除槽位 ", slot_index)
	return true

func clear_slot(slot_index: int) -> bool:
	"""
	清空槽位（将槽位设置为空）
	
	参数:
	- slot_index: 槽位索引
	
	返回: 清空成功返回true，失败返回false
	"""
	if slot_index < 0 or slot_index >= slot_array.size():
		print("Colony: 无效的槽位索引: ", slot_index)
		return false
	
	slot_array[slot_index] = {}
	print("Colony: 清空槽位 ", slot_index)
	return true

func get_slot(slot_index: int) -> Dictionary:
	"""
	返回槽位的tile数据
	
	参数:
	- slot_index: 槽位索引
	
	返回: 槽位数据字典 {tile_type: {alt_tile_index: X, remain_turns: X}}，如果索引无效则返回空字典
	"""
	
	if slot_index < 0 or slot_index >= slot_array.size():
		print("Colony: 无效的槽位索引: ", slot_index)
		return {}
	
	return slot_array[slot_index].duplicate(true)

func get_slot_array() -> Array:
	"""返回槽位数组的副本"""
	return slot_array.duplicate(true)
#endregion


#region tile统计

func calculate_all_tile_type_counts():
	"""重新计算所有tile类型的数量并更新缓存"""
	# 清空缓存
	colony_tile_type_counts.clear()
	
	# 统计地形tile类型
	var ground_counts = _calculate_layer_tile_counts(colony_ground_tiles)
	
	# 统计建筑tile类型
	var building_counts = _calculate_layer_tile_counts(colony_building_tiles)
	
	# 合并统计结果到缓存
	# 先添加地形tile统计
	for tile_type in ground_counts.keys():
		colony_tile_type_counts[tile_type] = ground_counts[tile_type]
	
	# 再添加建筑tile统计（如果已存在则累加）
	for tile_type in building_counts.keys():
		if colony_tile_type_counts.has(tile_type):
			colony_tile_type_counts[tile_type] += building_counts[tile_type]
		else:
			colony_tile_type_counts[tile_type] = building_counts[tile_type]

func _calculate_layer_tile_counts(layer: Dictionary) -> Dictionary:
	"""
	统计指定layer中各tile类型的数量
	参数:
	- layer: 要统计的layer字典 (colony_ground_tiles 或 colony_building_tiles)
	返回格式: {tile_type: count, ...}
	"""
	var result = {}
	
	# 遍历所有坐标
	for coord in layer.keys():
		var coord_tiles = layer[coord]
		if coord_tiles is Dictionary:
			# 遍历该坐标的所有tile类型
			for tile_type in coord_tiles.keys():
				if result.has(tile_type):
					result[tile_type] += 1
				else:
					result[tile_type] = 1
	
	return result

func calculate_tile_resources() -> Dictionary:
	"""
	根据tile_type_counts统计tile的resource合计
	返回格式: {resource_type: total_amount}
	"""
	var total_resources = {}
	
	# 确保统计数据是最新的
	if colony_tile_type_counts.is_empty():
		calculate_all_tile_type_counts()
	
	# 遍历所有tile类型及其数量
	for tile_type in colony_tile_type_counts.keys():
		var tile_count = colony_tile_type_counts[tile_type]
		
		# 跳过数量为0的tile
		if tile_count <= 0:
			continue
			
		# 从TileJsonLoader获取tile数据
		var tile_data = TileJsonLoader.get_tile_by_type(tile_type)
		
		# 检查tile是否有resource字段
		if tile_data.has("resource") and tile_data["resource"] is Dictionary:
			var tile_resources = tile_data["resource"]
			
			# 为每种资源类型计算总产出（tile数量 * 单个tile产出）
			for resource_type in tile_resources.keys():
				var resource_per_tile = tile_resources[resource_type]
				var total_resource = resource_per_tile * tile_count
				
				# 累加到总资源中
				if total_resources.has(resource_type):
					total_resources[resource_type] += total_resource
				else:
					total_resources[resource_type] = total_resource

	return total_resources

#endregion
