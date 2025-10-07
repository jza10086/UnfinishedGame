extends Node
# TriggerJsonLoader - 触发器数据JSON加载器

var trigger_files: Array = ["res://game_data/json/trigger/triggers.json"]
var trigger_types: Dictionary = {}

func _ready() -> void:
	load_all_triggers()

#region JSON处理函数
# 通用JSON文件读取函数
func load_json_file(file_path: String, file_type: String = "JSON") -> Dictionary:
	var path_to_use = file_path
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path_to_use):
		push_error("TriggerJsonLoader: 找不到" + file_type + "文件: " + path_to_use)
		return {}
	
	# 打开并读取文件
	var file = FileAccess.open(path_to_use, FileAccess.READ)
	if file == null:
		push_error("TriggerJsonLoader: 无法打开" + file_type + "文件: " + path_to_use)
		return {}
		
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("TriggerJsonLoader: 解析" + file_type + "文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	return json.get_data()

# 加载触发器数据
func load_triggers(file_path: String) -> bool:
	# 使用通用JSON读取函数
	var data = load_json_file(file_path, "触发器JSON")
	if data.is_empty():
		return false
	
	if not data.has("triggers") or not data["triggers"] is Dictionary:
		push_error("TriggerJsonLoader: 触发器JSON文件格式错误：缺少triggers对象")
		return false
	
	# 处理触发器数据
	var triggers_object = data["triggers"]
	var loaded_count = 0
	
	for trigger_type in triggers_object.keys():
		var trigger_data = triggers_object[trigger_type]
		
		# 检查是否已存在
		if trigger_types.has(trigger_type):
			push_warning("TriggerJsonLoader: 发现重复的触发器类型: " + trigger_type)
			continue
		
		# 存储触发器数据
		trigger_types[trigger_type] = trigger_data
		loaded_count += 1
	
	print("TriggerJsonLoader: 从文件 " + file_path + " 成功加载 " + str(loaded_count) + " 个触发器")
	return true

# 读取指定路径数组中的所有触发器JSON文件
func load_all_triggers(paths: Array = trigger_files):
	for path in paths:
		# 检查是否为JSON文件
		if path.ends_with(".json") and FileAccess.file_exists(path):
			if load_triggers(path):
				pass
			else:
				print("TriggerJsonLoader: 加载触发器JSON文件失败: " + path)
		else:
			push_error("TriggerJsonLoader: 路径无效或不是JSON文件: " + path)
	
	print("TriggerJsonLoader: 总共加载了 " + str(trigger_types.size()) + " 个触发器")

# 清空触发器数据
func clear_triggers():
	trigger_types.clear()
	print("TriggerJsonLoader: 已清空所有触发器数据")

# 重新加载所有触发器数据
func reload_triggers():
	clear_triggers()
	load_all_triggers()
#endregion

#region 数据获取函数
# 获取指定类型的触发器数据
func get_trigger(trigger_type: StringName) -> Dictionary:
	if trigger_types.has(trigger_type):
		return trigger_types[trigger_type].duplicate(true)
	else:
		push_error("TriggerJsonLoader: 找不到触发器类型: " + trigger_type)
		return {}

#endregion
