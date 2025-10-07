extends Node
# TechJsonLoader - 科技数据JSON加载器

# 存储科技数据
var techs: Dictionary = {}
var tech_files: Array = [
	"res://game_data/json/tech/default_tech_types.json",
	"res://game_data/json/tech/default_core_tech_types.json"
]

func _ready() -> void:
	load_all_techs()

#region JSON处理函数
# 通用JSON文件读取函数
func load_json_file(file_path: String, file_type: String = "JSON") -> Dictionary:
	var path_to_use = file_path
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path_to_use):
		push_error("TechJsonLoader: 找不到" + file_type + "文件: " + path_to_use)
		return {}
	
	# 打开并读取文件
	var file = FileAccess.open(path_to_use, FileAccess.READ)
	if file == null:
		push_error("TechJsonLoader: 无法打开" + file_type + "文件: " + path_to_use)
		return {}
		
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("TechJsonLoader: 解析" + file_type + "文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	return json.get_data()

# 加载科技数据
func load_techs(file_path: String) -> bool:
	# 使用通用JSON读取函数
	var data = load_json_file(file_path, "科技JSON")
	if data.is_empty():
		return false
	
	if not data.has("techs") or not data["techs"] is Dictionary:
		push_error("TechJsonLoader: 科技JSON文件格式错误：缺少techs对象")
		return false
	
	# 处理科技数据
	var techs_object = data["techs"]
	var loaded_count = 0
	
	for tech_type in techs_object.keys():
		var tech_data = techs_object[tech_type]
		
		# 检查必要字段
		if not tech_data.has("tech_category") or not tech_data.has("tier") or not tech_data.has("cost"):
			push_error("TechJsonLoader: 科技 " + tech_type + " 缺少必要字段")
			continue
		
		# 转换tech_category为枚举值
		var category_str = tech_data["tech_category"]
		if category_str == "GENERAL":
			tech_data["tech_category"] = GlobalEnum.TechCategory.GENERAL
		elif category_str == "CORE":
			tech_data["tech_category"] = GlobalEnum.TechCategory.CORE
		else:
			push_error("TechJsonLoader: 科技 " + tech_type + " 的tech_category值无效: " + category_str)
			continue
		
		# 设置默认值
		if not tech_data.has("describe"):
			tech_data["describe"] = ""
		if not tech_data.has("tags"):
			tech_data["tags"] = []
		if not tech_data.has("icon_path"):
			tech_data["icon_path"] = ""
		if not tech_data.has("requirements"):
			tech_data["requirements"] = {"tech": [], "event": [], "race": []}
		if not tech_data.has("unlocks"):
			tech_data["unlocks"] = {"tech": [], "building": [], "unit": [], "resource": []}
		if not tech_data.has("locks"):
			tech_data["locks"] = []
		if not tech_data.has("weight"):
			# 只有GENERAL类型的科技需要weight字段
			if tech_data.get("tech_category") == GlobalEnum.TechCategory.GENERAL:
				tech_data["weight"] = [
					{
						"rule": "default",
						"type": "base",
						"bonus": 1.0,
						"multiplier": 0.0
					}
				]
			else:
				# CORE类型科技不需要weight字段
				tech_data["weight"] = []
		if not tech_data.has("bonus"):
			tech_data["bonus"] = []
		else:
			# 转换bonus数组中的target字段为枚举值
			for bonus_entry in tech_data["bonus"]:
				if bonus_entry.has("target"):
					var target_str = bonus_entry["target"]
					match target_str:
						"PLANET":
							bonus_entry["target"] = GlobalEnum.UnitType.PLANET
						"FLEET":
							bonus_entry["target"] = GlobalEnum.UnitType.FLEET
						"STELLAR":
							bonus_entry["target"] = GlobalEnum.UnitType.STELLAR
						_:
							push_error("TechJsonLoader: 科技 " + tech_type + " 的bonus.target值无效: " + target_str)

		# 检查是否已存在
		if techs.has(tech_type):
			push_warning("TechJsonLoader: 发现重复的科技: " + tech_type)
			continue
		
		# 存储科技数据
		techs[tech_type] = tech_data
		loaded_count += 1
	
	print("TechJsonLoader: 从文件 " + file_path + " 成功加载 " + str(loaded_count) + " 个科技")
	return true

# 读取指定路径数组中的所有科技JSON文件
func load_all_techs(paths: Array = tech_files):
	for path in paths:
		# 检查是否为JSON文件
		if path.ends_with(".json") and FileAccess.file_exists(path):
			if load_techs(path):
				pass
			else:
				print("TechJsonLoader: 加载科技JSON文件失败: " + path)
		else:
			push_error("TechJsonLoader: 路径无效或不是JSON文件: " + path)
	
	print("TechJsonLoader: 总共加载了 " + str(techs.size()) + " 个科技")

# 清空科技数据
func clear_techs():
	techs.clear()
	print("TechJsonLoader: 已清空所有科技数据")

#endregion

#region 数据获取函数
# 获取指定科技的数据
func get_tech(tech_type: StringName) -> Dictionary:
	if techs.has(tech_type):
		return techs[tech_type].duplicate(true)
	else:
		push_error("TechJsonLoader: 找不到科技: " + tech_type)
		return {}

# 获取所有科技名称列表
func get_all_tech_types() -> Array:
	return techs.keys()

# 按等级获取科技
func get_techs_by_tier(tier: int) -> Array:
	var result = []
	for tech_type in techs.keys():
		if techs[tech_type]["tier"] == tier:
			result.append(tech_type)
	return result

# 按类型获取科技
func get_techs_by_type(p_tech_type: StringName) -> Array:
	var result = []
	for tech_type in techs.keys():
		if techs[tech_type]["tech_type"] == p_tech_type:
			result.append(tech_type)
	return result
#endregion
