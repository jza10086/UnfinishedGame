extends Node
# BonusJsonLoader - 加成类型数据JSON加载器

# 存储加成类型数据
var bonus_types: Dictionary = {}
var bonus_types_files: Array = ["res://game_data/json/bonus/bonus_type.json"]

func _ready() -> void:
	load_all_bonus_types()

#region JSON处理函数
# 验证并转换资源字典，将字符串键名转换为对应的枚举值
func validate_and_convert_resources(resource_dict: Dictionary, bonus_type: String, field_name: String = "resources"):
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
			push_error("BonusJsonLoader: 加成类型 " + bonus_type + " 的 " + field_name + " 字段中包含无效的资源类型 '" + str(key) + "'。有效的资源类型：" + str(valid_types))
			return null
		
		converted_dict[enum_value] = resource_dict[key]
	
	return converted_dict

# 验证并转换bonus_type枚举
func validate_and_convert_bonus_type(bonus_type_str: String, type_name: String) -> BonusResource.BonusType:
	var bonus_type_upper = bonus_type_str.to_upper()
	
	# 检查是否匹配 BonusResource.BonusType 枚举
	var enum_keys = ["BASIC", "BONUS", "MULTIPLIER"]  # BonusResource.BonusType 的枚举值
	var enum_values = [BonusResource.BonusType.BASIC, BonusResource.BonusType.BONUS, BonusResource.BonusType.MULTIPLIER]
	
	for i in range(enum_keys.size()):
		if bonus_type_upper == enum_keys[i]:
			return enum_values[i]
	
	push_error("BonusJsonLoader: 加成类型 " + type_name + " 的 bonus_type 字段包含无效值 '" + bonus_type_str + "'。有效值：" + str(enum_keys))
	return BonusResource.BonusType.BASIC  # 默认返回BASIC

# 通用JSON文件读取函数
func load_json_file(file_path: String, file_type: String = "JSON") -> Dictionary:
	var path_to_use = file_path
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path_to_use):
		push_error("BonusJsonLoader: 找不到" + file_type + "文件: " + path_to_use)
		return {}
	
	# 打开并读取文件
	var file = FileAccess.open(path_to_use, FileAccess.READ)
	if file == null:
		push_error("BonusJsonLoader: 无法打开" + file_type + "文件: " + path_to_use)
		return {}
		
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("BonusJsonLoader: 解析" + file_type + "文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	return json.get_data()

# 加载加成类型数据
func load_bonus_types(file_path: String) -> bool:
	# 使用通用JSON读取函数
	var data = load_json_file(file_path, "加成类型JSON")
	if data.is_empty():
		return false
	
	if not data.has("bonus_types") or not data["bonus_types"] is Dictionary:
		push_error("BonusJsonLoader: 加成类型JSON文件格式错误：缺少bonus_types对象")
		return false
	
	# 处理加成数据
	var bonus_objects = data["bonus_types"]
	var loaded_count = 0
	
	for bonus_type in bonus_objects.keys():
		var bonus_data = bonus_objects[bonus_type]
		
		# 检查必要字段
		if not bonus_data.has("describe") or not bonus_data.has("bonus_type") or not bonus_data.has("resources"):
			push_error("BonusJsonLoader: 加成类型 " + bonus_type + " 缺少必要字段")
			continue
		
		# 设置默认值
		if not bonus_data.has("stackable"):
			bonus_data["stackable"] = false
		if not bonus_data.has("duration_turns"):
			bonus_data["duration_turns"] = -1
		
		# 验证并转换bonus_type枚举
		var converted_bonus_type = validate_and_convert_bonus_type(bonus_data["bonus_type"], bonus_type)
		bonus_data["bonus_type"] = converted_bonus_type
		
		# 验证并转换资源数据
		if bonus_data.has("resources") and bonus_data["resources"] is Dictionary:
			var validated_resources = validate_and_convert_resources(bonus_data["resources"], bonus_type)
			if validated_resources != null:
				bonus_data["resources"] = validated_resources
			else:
				continue # 如果资源验证失败，跳过这个加成
		
		# 检查是否已存在
		if bonus_types.has(bonus_type):
			push_warning("BonusJsonLoader: 发现重复的加成类型: " + bonus_type)
			continue
		
		# 存储加成类型数据
		bonus_types[bonus_type] = bonus_data
		loaded_count += 1
	
	print("BonusJsonLoader: 从文件 " + file_path + " 成功加载 " + str(loaded_count) + " 个加成类型")
	return true

# 读取指定路径数组中的所有加成类型JSON文件
func load_all_bonus_types(paths: Array = bonus_types_files):
	for path in paths:
		# 检查是否为JSON文件
		if path.ends_with(".json") and FileAccess.file_exists(path):
			if load_bonus_types(path):
				pass
			else:
				print("BonusJsonLoader: 加载加成类型JSON文件失败: " + path)
		else:
			push_error("BonusJsonLoader: 路径无效或不是JSON文件: " + path)
	
	print("BonusJsonLoader: 总共加载了 " + str(bonus_types.size()) + " 个加成类型")

# 清空加成类型数据
func clear_bonus_types():
	bonus_types.clear()
	print("BonusJsonLoader: 已清空所有加成类型数据")

#endregion

#region 数据获取函数

# 获取指定类型的加成数据
func get_bonus_type(bonus_type: String) -> Dictionary:
	if bonus_types.has(bonus_type):
		return bonus_types[bonus_type].duplicate(true)
	else:
		push_error("BonusJsonLoader: 找不到加成类型: " + bonus_type)
		return {}

# 获取所有加成类型列表
func get_all_bonus_types() -> Array:
	return bonus_types.keys()

#endregion
