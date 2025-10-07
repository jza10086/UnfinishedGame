extends Node
# StellarJsonLoader - 恒星系数据JSON加载器

# 存储恒星系类型数据和名称数据
var stellar_types: Dictionary = {}
var available_names: Dictionary = {}
var stellar_types_files: Array = ["res://game_data/json/stellar/stellar_type/stellar_types.json"]
var stellar_name_files: Array = ["res://game_data/json/name/stellar_names/stellar_names.json"]

# 追踪已生成的unique恒星类型
var generated_unique_types: Array = []

func _ready() -> void:
	load_all_stellar_data()

#region JSON处理函数
# 通用JSON文件读取函数
func load_json_file(file_path: String, file_type: String = "JSON") -> Dictionary:
	var path_to_use = file_path
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path_to_use):
		push_error("StellarJsonLoader: 找不到" + file_type + "文件: " + path_to_use)
		return {}
	
	# 打开并读取文件
	var file = FileAccess.open(path_to_use, FileAccess.READ)
	if file == null:
		push_error("StellarJsonLoader: 无法打开" + file_type + "文件: " + path_to_use)
		return {}
		
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("StellarJsonLoader: 解析" + file_type + "文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	return json.get_data()

# 加载JSON文件中的所有名称到available_names字典中
func load_names_from_json(json_file_path: String) -> bool:
	var file_name = json_file_path.get_file().get_basename()
	# 如果已经加载过，直接返回成功
	if available_names.has(file_name):
		return true
	
	# 使用通用JSON读取函数
	var data = load_json_file(json_file_path, "恒星名称JSON")
	if data.is_empty():
		return false
	if not data.has("stellar_names") or data["stellar_names"].size() == 0:
		push_error("StellarJsonLoader: JSON文件中没有包含stellar_names数组或数组为空")
		return false
	
	# 检查并处理重复名称
	var name_set = {}
	var names_array = data["stellar_names"]
	var unique_names = []
	var duplicate_names = []
	
	# 检查文件内部的重复
	for stellar_name in names_array:
		if name_set.has(stellar_name):
			duplicate_names.append(stellar_name)
		else:
			name_set[stellar_name] = true
			unique_names.append(stellar_name)
	
	if duplicate_names.size() > 0:
		print("StellarJsonLoader: JSON文件 " + file_name + " 中存在重复名称，已跳过: " + str(duplicate_names))
		
	# 检查与其他已加载文件的重复
	var final_names = []
	var conflicts = []
	
	for stellar_name in unique_names:
		var name_exists = false
		for other_file_name in available_names:
			var other_names = available_names[other_file_name]
			if stellar_name in other_names:
				name_exists = true
				conflicts.append(stellar_name)
				break
		
		if not name_exists:
			final_names.append(stellar_name)
	
	if conflicts.size() > 0:
		print("StellarJsonLoader: JSON文件 " + file_name + " 中的名称与其他文件重复，已跳过: " + str(conflicts))
	
	if final_names.size() == 0:
		push_error("StellarJsonLoader: JSON文件 " + file_name + " 中没有可用的唯一名称")
		return false
		
	# 获取名称列表并存储（使用文件名作为键）
	available_names[file_name] = final_names
	return true

# 读取指定路径数组中的所有名称JSON文件
func load_all_names(paths: Array = stellar_name_files):
	for path in paths:
		# 检查是否为JSON文件
		if path.ends_with(".json") and FileAccess.file_exists(path):
			if load_names_from_json(path):
				pass
			else:
				print("StellarJsonLoader: 加载JSON文件失败: " + path)
		else:
			push_error("StellarJsonLoader: 路径无效或不是JSON文件: " + path)

# 加载恒星系类型数据
func load_stellar_types(file_path: String) -> bool:
	# 使用通用JSON读取函数
	var data = load_json_file(file_path, "恒星系类型JSON")
	if data.is_empty():
		return false
	
	if not data.has("stellars") or not data["stellars"] is Dictionary:
		push_error("StellarJsonLoader: 恒星系类型JSON文件格式错误：缺少stellars对象")
		return false
	
	# 处理恒星系数据
	var stellars_object = data["stellars"]
	var loaded_count = 0
	
	for stellar_type in stellars_object.keys():
		var stellar_data = stellars_object[stellar_type]
		
		# 检查必要字段
		if not stellar_data.has("describe") or not stellar_data.has("size") or not stellar_data.has("weight") or not stellar_data.has("unique") or not stellar_data.has("planets"):
			push_error("StellarJsonLoader: 恒星系类型 " + stellar_type + " 缺少必要字段")
			continue
		
		# 验证planets结构（必须是字典）
		var planets = stellar_data["planets"]
		if not planets is Dictionary:
			push_error("StellarJsonLoader: 恒星系类型 " + stellar_type + " 的planets字段必须是字典")
			continue
		
		# 检查是否已存在
		if stellar_types.has(stellar_type):
			push_warning("StellarJsonLoader: 发现重复的恒星系类型: " + stellar_type)
			continue
		
		# 存储恒星系类型数据
		stellar_types[stellar_type] = stellar_data
		loaded_count += 1
	
	print("StellarJsonLoader: 从文件 " + file_path + " 成功加载 " + str(loaded_count) + " 个恒星系类型")
	return true

# 读取指定路径数组中的所有恒星系类型JSON文件
func load_all_stellar_types(paths: Array = stellar_types_files):
	for path in paths:
		# 检查是否为JSON文件
		if path.ends_with(".json") and FileAccess.file_exists(path):
			if load_stellar_types(path):
				pass
			else:
				print("StellarJsonLoader: 加载恒星系类型JSON文件失败: " + path)
		else:
			push_error("StellarJsonLoader: 路径无效或不是JSON文件: " + path)
	
	print("StellarJsonLoader: 总共加载了 " + str(stellar_types.size()) + " 个恒星系类型")

# 加载所有恒星系相关数据
func load_all_stellar_data():
	load_all_names()
	load_all_stellar_types()

# 清空所有数据
func clear_all_data():
	available_names.clear()
	stellar_types.clear()
	generated_unique_types.clear()
	print("StellarJsonLoader: 已清空所有恒星系数据")


#endregion

#region 名称获取函数
# 从提供的名称数组中获取一个名称并将其删除
func get_unique_stellar_name(names_array_name: String = "stellar_names") -> String:
	if not available_names.has(names_array_name):
		push_error("StellarJsonLoader: 找不到名称数组: " + names_array_name)
		return "未命名恒星_" + str(Time.get_unix_time_from_system() + randi())
		
	var names_array = available_names[names_array_name]
	if names_array.size() == 0:
		print("StellarJsonLoader: 名称数组为空，返回随机名称")
		return "未命名恒星_" + str(Time.get_unix_time_from_system() + randi())
	# 随机选择一个索引
	var index = randi() % names_array.size()
	
	# 获取该索引的名称
	var selected_name = names_array[index]
	
	# 从数组中删除该名称
	names_array.remove_at(index)
	
	# 返回选择的名称
	return selected_name
#endregion

#region 恒星系类型数据获取函数
# 获取指定类型的恒星系数据
func get_stellar_type(stellar_type: String) -> Dictionary:
	if stellar_types.has(stellar_type):
		return stellar_types[stellar_type]
	else:
		push_error("StellarJsonLoader: 找不到恒星系类型: " + stellar_type)
		return {}

# 获取恒星系的特殊名称（如果有的话）
func get_stellar_special_name(stellar_type: String) -> String:
	if stellar_types.has(stellar_type):
		var stellar_data = stellar_types[stellar_type]
		if stellar_data.has("special_name") and stellar_data["special_name"] != "":
			return stellar_data["special_name"]
	return ""

# 为指定的恒星系类型获取合适的名称
# 如果是unique类型且有special_name，则使用special_name
# 否则使用随机名称
func get_stellar_name_for_type(stellar_type: String, names_array_name: String = "stellar_names") -> String:
	if stellar_types.has(stellar_type):
		var stellar_data = stellar_types[stellar_type]
		# 检查是否为unique类型且有特殊名称
		if stellar_data.has("unique") and stellar_data["unique"] == true:
			var special_name = get_stellar_special_name(stellar_type)
			if special_name != "":
				print("StellarJsonLoader: 使用特殊名称: ", special_name, " 用于恒星系类型: ", stellar_type)
				return special_name
	
	# 否则使用随机名称
	return get_unique_stellar_name(names_array_name)

# 使用加权随机选择恒星类型，支持unique类型处理
func get_random_stellar_type() -> String:
	if stellar_types.is_empty():
		push_error("StellarJsonLoader: 没有可用的恒星系类型数据")
		return ""
	
	# 首先检查是否有需要生成的unique类型
	var pending_unique_types: Array = []
	for stellar_type in stellar_types:
		var stellar_data = stellar_types[stellar_type]
		if stellar_data.has("unique") and stellar_data["unique"] == true:
			if not generated_unique_types.has(stellar_type):
				pending_unique_types.append(stellar_type)
	
	# 如果有待生成的unique类型，优先生成它们
	if pending_unique_types.size() > 0:
		# 从待生成的unique类型中随机选择一个
		var selected_unique = pending_unique_types[randi() % pending_unique_types.size()]
		generated_unique_types.append(selected_unique)
		print("StellarJsonLoader: 生成unique恒星类型: ", selected_unique)
		return selected_unique
	
	# 创建类型名称和权重字典（排除已生成的unique类型）
	var item_weights: Dictionary = {}
	
	for stellar_type in stellar_types:
		var stellar_data = stellar_types[stellar_type]
		# 跳过已生成的unique类型
		if stellar_data.has("unique") and stellar_data["unique"] == true and generated_unique_types.has(stellar_type):
			continue
		
		item_weights[stellar_type] = stellar_data["weight"]
	
	# 检查是否还有可选择的类型
	if item_weights.is_empty():
		push_error("StellarJsonLoader: 没有可用的恒星系类型（所有unique类型已生成）")
		return ""
	
	# 使用 MathTools.weight_rand 进行加权随机选择
	var selected_type = MathTools.weight_rand(item_weights)
	
	if selected_type == null:
		push_error("StellarJsonLoader: 加权随机选择恒星系类型失败")
		# 返回第一个可用类型作为后备
		return item_weights.keys()[0]
	
	return selected_type

# 重置unique恒星类型状态（用于重新生成地图时）
func reset_unique_stellar_types():
	generated_unique_types.clear()
	print("StellarJsonLoader: 已重置unique恒星类型状态")

# 获取unique恒星类型的统计信息
func get_unique_stellar_stats() -> Dictionary:
	var stats = {
		"total_unique_types": 0,
		"generated_unique_types": generated_unique_types.size(),
		"pending_unique_types": [],
		"generated_list": generated_unique_types.duplicate()
	}
	
	# 统计总unique类型数量和待生成的类型
	for stellar_type in stellar_types:
		var stellar_data = stellar_types[stellar_type]
		if stellar_data.has("unique") and stellar_data["unique"] == true:
			stats["total_unique_types"] += 1
			if not generated_unique_types.has(stellar_type):
				stats["pending_unique_types"].append(stellar_type)
	
	return stats

# 获取所有恒星系类型列表
func get_all_stellar_types() -> Array:
	return stellar_types.keys()

# 检查恒星系类型是否存在
func has_stellar_type(stellar_type: String) -> bool:
	return stellar_types.has(stellar_type)

# 获取恒星系类型数量
func get_stellar_types_count() -> int:
	return stellar_types.size()
#endregion
