extends Node
# PlanetJsonLoader - 行星数据JSON加载器

# 存储行星类型数据
var planet_types: Dictionary = {}
var planet_types_files: Array = ["res://game_data/json/stellar/planet_type/planet_types.json"]

func _ready() -> void:
	load_all_planet_types()

#region JSON处理函数
# 验证并转换资源字典，将字符串键名转换为对应的枚举值
func validate_and_convert_resources(resource_dict: Dictionary, planet_type: String, field_name: String = "basic_resources"):
	var converted_dict = {}
	
	for key in resource_dict.keys():
		var key_str = str(key).to_upper()
		
		# 动态检查键名是否匹配 GlobalEnum.ResourceType 中的任何枚举值
		var enum_value = null
		var found = false
		
		# 获取所有枚举键名
		var enum_keys = GlobalEnum.ResourceType.keys()
		for i in range(enum_keys.size()):
			if key_str == enum_keys[i]:
				enum_value = GlobalEnum.ResourceType.values()[i]
				found = true
				break
		
		if not found:
			var valid_types = GlobalEnum.ResourceType.keys()
			push_error("PlanetJsonLoader: 行星类型 " + planet_type + " 的 " + field_name + " 字段中包含无效的资源类型 '" + str(key) + "'。有效的资源类型：" + str(valid_types))
			return null
		
		converted_dict[enum_value] = resource_dict[key]
	
	return converted_dict

# 通用JSON文件读取函数
func load_json_file(file_path: String, file_type: String = "JSON") -> Dictionary:
	var path_to_use = file_path
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path_to_use):
		push_error("PlanetJsonLoader: 找不到" + file_type + "文件: " + path_to_use)
		return {}
	
	# 打开并读取文件
	var file = FileAccess.open(path_to_use, FileAccess.READ)
	if file == null:
		push_error("PlanetJsonLoader: 无法打开" + file_type + "文件: " + path_to_use)
		return {}
		
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("PlanetJsonLoader: 解析" + file_type + "文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	return json.get_data()

# 加载行星类型数据
func load_planet_types(file_path: String) -> bool:
	# 使用通用JSON读取函数
	var data = load_json_file(file_path, "行星类型JSON")
	if data.is_empty():
		return false
	
	if not data.has("planets") or not data["planets"] is Dictionary:
		push_error("PlanetJsonLoader: 行星类型JSON文件格式错误：缺少planets对象")
		return false
	
	# 处理行星数据
	var planets_object = data["planets"]
	var loaded_count = 0
	
	for planet_type in planets_object.keys():
		var planet_data = planets_object[planet_type]
		
		# 检查必要字段
		if not planet_data.has("describe") or not planet_data.has("tscn") or not planet_data.has("size") or not planet_data.has("basic_resources"):
			push_error("PlanetJsonLoader: 行星类型 " + planet_type + " 缺少必要字段")
			continue
		
		# 检查group字段，如果没有则添加默认值
		if not planet_data.has("group"):
			planet_data["group"] = ["planet"]
		elif not planet_data["group"] is Array:
			push_error("PlanetJsonLoader: 行星类型 " + planet_type + " 的group字段必须是数组")
			planet_data["group"] = ["planet"]
		
		# 验证并转换资源数据
		if planet_data.has("basic_resources") and planet_data["basic_resources"] is Dictionary:
			var validated_resources = validate_and_convert_resources(planet_data["basic_resources"], planet_type)
			if validated_resources != null:
				planet_data["basic_resources"] = validated_resources
			else:
				continue # 如果资源验证失败，跳过这个行星
		
		# 检查是否已存在
		if planet_types.has(planet_type):
			push_warning("PlanetJsonLoader: 发现重复的行星类型: " + planet_type)
			continue
		
		# 存储行星类型数据
		planet_types[planet_type] = planet_data
		loaded_count += 1
	
	print("PlanetJsonLoader: 从文件 " + file_path + " 成功加载 " + str(loaded_count) + " 个行星类型")
	return true

# 读取指定路径数组中的所有行星类型JSON文件
func load_all_planet_types(paths: Array = planet_types_files):
	for path in paths:
		# 检查是否为JSON文件
		if path.ends_with(".json") and FileAccess.file_exists(path):
			if load_planet_types(path):
				pass
			else:
				print("PlanetJsonLoader: 加载行星类型JSON文件失败: " + path)
		else:
			push_error("PlanetJsonLoader: 路径无效或不是JSON文件: " + path)
	
	print("PlanetJsonLoader: 总共加载了 " + str(planet_types.size()) + " 个行星类型")

# 清空行星类型数据
func clear_planet_types():
	planet_types.clear()
	print("PlanetJsonLoader: 已清空所有行星类型数据")


#endregion

#region 数据获取函数
# 获取指定类型的行星数据
func get_planet_type(planet_type: String) -> Dictionary:
	if planet_types.has(planet_type):
		return planet_types[planet_type].duplicate(true)
	else:
		push_error("PlanetJsonLoader: 找不到行星类型: " + planet_type)
		return {}

# 获取所有行星类型列表
func get_all_planet_types() -> Array:
	return planet_types.keys()

# 检查行星类型是否存在
func has_planet_type(planet_type: String) -> bool:
	return planet_types.has(planet_type)

# 获取行星类型数量
func get_planet_types_count() -> int:
	return planet_types.size()


#endregion
