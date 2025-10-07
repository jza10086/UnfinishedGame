extends Node
# ShipJsonLoader - 舰船数据JSON加载器

# 存储舰船类型数据
var ship_types: Dictionary = {}
var ship_types_files: Array = ["res://game_data/json/ship/ship_data.json"]

func _ready() -> void:
	load_all_ship_types()

#region JSON处理函数
# 通用JSON文件读取函数
func load_json_file(file_path: String, file_type: String = "JSON") -> Dictionary:
	var path_to_use = file_path
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path_to_use):
		push_error("ShipJsonLoader: 找不到" + file_type + "文件: " + path_to_use)
		return {}
	
	# 打开并读取文件
	var file = FileAccess.open(path_to_use, FileAccess.READ)
	if file == null:
		push_error("ShipJsonLoader: 无法打开" + file_type + "文件: " + path_to_use)
		return {}
		
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("ShipJsonLoader: 解析" + file_type + "文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	return json.get_data()

# 加载舰船类型数据
func load_ship_types(file_path: String) -> bool:
	# 使用通用JSON读取函数
	var data = load_json_file(file_path, "舰船类型JSON")
	if data.is_empty():
		return false
	
	# 检查JSON结构是否包含ships对象
	if not data.has("ships"):
		push_error("ShipJsonLoader: 舰船类型JSON文件格式错误，缺少ships对象: " + file_path)
		return false
	
	var ships_object = data["ships"]
	if not ships_object is Dictionary:
		push_error("ShipJsonLoader: ships字段不是对象格式: " + file_path)
		return false
	
	# 处理舰船数据
	var loaded_count = 0
	for ship_type in ships_object.keys():
		var ship_data = ships_object[ship_type]
		
		# 现在只处理单个对象格式
		if not ship_data is Dictionary:
			push_error("ShipJsonLoader: 舰船数据格式错误，应为字典类型")
			continue
		
		# 检查必要字段
		if not validate_ship_data(ship_data):
			continue
		
		# 检查是否已存在
		if ship_types.has(ship_type):
			push_warning("ShipJsonLoader: 发现重复的舰船类型: " + ship_type)
			continue
		
		# 存储舰船类型数据
		ship_types[ship_type] = ship_data
		loaded_count += 1
	
	print("ShipJsonLoader: 从文件 " + file_path + " 成功加载 " + str(loaded_count) + " 个舰船类型")
	return true

# 验证舰船数据的必要字段
func validate_ship_data(ship_data: Dictionary) -> bool:
	var required_fields = ["describe", "health", "atk", "def", "size", "model_path"]
	
	for field in required_fields:
		if not ship_data.has(field):
			push_error("ShipJsonLoader: 舰船数据缺少必要字段: " + field + " in " + str(ship_data))
			return false
	
	return true

# 读取指定路径数组中的所有舰船类型JSON文件
func load_all_ship_types(paths: Array = ship_types_files):
	for path in paths:
		# 检查是否为JSON文件
		if path.ends_with(".json") and FileAccess.file_exists(path):
			load_ship_types(path)
		else:
			push_error("ShipJsonLoader: 无效的JSON文件路径: " + path)
	
	print("ShipJsonLoader: 总共加载了 " + str(ship_types.size()) + " 个舰船类型")

# 清空舰船类型数据
func clear_ship_types():
	ship_types.clear()
	print("ShipJsonLoader: 已清空所有舰船类型数据")


#endregion

#region 数据获取函数
# 获取指定类型的舰船数据
func get_ship_type(ship_type: String) -> Dictionary:
	if ship_types.has(ship_type):
		return ship_types[ship_type]
	else:
		push_error("ShipJsonLoader: 找不到舰船类型: " + ship_type)
		return {}

# 获取所有舰船类型列表
func get_all_ship_types() -> Array:
	return ship_types.keys()

# 根据舰队容量限制获取可用舰船类型
func get_available_ship_types_by_size(max_size: int) -> Array:
	var available_types = []
	for ship_type in ship_types:
		var ship_data = ship_types[ship_type]
		if ship_data["size"] <= max_size:
			available_types.append(ship_type)
	return available_types

# 计算舰船建造成本（可以根据需要扩展）
func get_ship_cost(ship_type: String) -> int:
	if not ship_types.has(ship_type):
		return 0
	
	var ship_data = ship_types[ship_type]
	# 简单的成本计算公式：基于攻击力、血量、防御力和大小
	var base_cost = ship_data["atk"] + ship_data["health"] * 0.5 + ship_data["def"] * 2
	var size_multiplier = ship_data["size"]
	return int(base_cost * size_multiplier)

# 获取舰船类型统计信息
func get_ship_type_stats() -> Dictionary:
	var stats = {
		"total_types": ship_types.size(),
		"by_size": {},
		"avg_stats": {
			"health": 0.0,
			"atk": 0.0,
			"def": 0.0
		}
	}
	
	if ship_types.size() == 0:
		return stats
	
	var total_health = 0.0
	var total_atk = 0.0
	var total_def = 0.0
	
	# 按尺寸分类统计
	for ship_type in ship_types:
		var ship_data = ship_types[ship_type]
		var size = ship_data["size"]
		
		if not stats["by_size"].has(size):
			stats["by_size"][size] = 0
		stats["by_size"][size] += 1
		
		# 累计属性值
		total_health += ship_data["health"]
		total_atk += ship_data["atk"]
		total_def += ship_data["def"]
	
	# 计算平均值
	var type_count = ship_types.size()
	stats["avg_stats"]["health"] = total_health / type_count
	stats["avg_stats"]["atk"] = total_atk / type_count
	stats["avg_stats"]["def"] = total_def / type_count
	
	return stats

# 检查舰船类型是否存在
func has_ship_type(ship_type: String) -> bool:
	return ship_types.has(ship_type)

# 获取舰船类型数量
func get_ship_types_count() -> int:
	return ship_types.size()
#endregion
