extends Node
# TileJsonLoader - 地形块数据JSON加载器

# 存储地形块类型数据
var tile_types: Dictionary = {}
var tile_types_files: Array = [
"res://game_data/json/tile/tile_type.json",
"res://game_data/json/tile/building_tile_type.json"]

func _ready() -> void:
	load_all_tile_data()

#region JSON处理函数
# 验证并转换资源字典，将字符串键名转换为对应的枚举值
func validate_and_convert_resources(resource_dict: Dictionary, tile_type: String, field_name: String = "resource"):
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
			push_error("TileJsonLoader: 地形块类型 " + tile_type + " 的 " + field_name + " 字段中包含无效的资源类型 '" + str(key) + "'。有效的资源类型：" + str(valid_types))
			return null
		
		converted_dict[enum_value] = resource_dict[key]
	
	return converted_dict

# 通用JSON文件读取函数
func load_json_file(file_path: String, file_type: String = "JSON") -> Dictionary:
	var path_to_use = file_path
	
	# 检查文件是否存在
	if not FileAccess.file_exists(path_to_use):
		push_error("TileJsonLoader: 找不到" + file_type + "文件: " + path_to_use)
		return {}
	
	# 打开并读取文件
	var file = FileAccess.open(path_to_use, FileAccess.READ)
	if file == null:
		push_error("TileJsonLoader: 无法打开" + file_type + "文件: " + path_to_use)
		return {}
		
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("TileJsonLoader: 解析" + file_type + "文件失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return {}
	
	return json.get_data()

# 加载地形块类型数据
func load_tile_types(file_path: String) -> bool:
	# 使用通用JSON读取函数
	var data = load_json_file(file_path, "地形块类型JSON")
	if data.is_empty():
		return false
	
	# 检查是否包含tiles对象
	if not data.has("tiles") or not data["tiles"] is Dictionary:
		push_error("TileJsonLoader: 地形块类型JSON文件格式错误：缺少tiles对象")
		return false
	
	# 获取tiles数据
	var tiles_data = data["tiles"]
	
	# 遍历tiles数据
	var loaded_count = 0
	for tile_type in tiles_data.keys():
		var tile_data = tiles_data[tile_type]
		if not tile_data is Dictionary:
			push_error("TileJsonLoader: 地形块类型 " + tile_type + " 的数据必须是字典")
			continue
		
		# 检查必要字段
		if not tile_data.has("tileset_path") or not tile_data.has("tile_id") or not tile_data.has("tile_coord"):
			push_error("TileJsonLoader: 地形块类型 " + tile_type + " 缺少必要字段")
			continue
		
		# 验证tile_coord结构（必须是字典，包含x和y）
		var tile_coord = tile_data["tile_coord"]
		if not tile_coord is Dictionary or not tile_coord.has("x") or not tile_coord.has("y"):
			push_error("TileJsonLoader: 地形块类型 " + tile_type + " 的tile_coord字段必须是包含x和y的字典")
			continue
		
		# 验证并转换资源数据
		if tile_data.has("resource") and tile_data["resource"] is Dictionary:
			var validated_resources = validate_and_convert_resources(tile_data["resource"], tile_type)
			if validated_resources != null:
				tile_data["resource"] = validated_resources
			else:
				continue # 如果资源验证失败，跳过这个瓦片
		
		# 验证并转换成本数据（如果存在）
		if tile_data.has("cost") and tile_data["cost"] is Dictionary:
			var validated_cost = validate_and_convert_resources(tile_data["cost"], tile_type, "cost")
			if validated_cost != null:
				tile_data["cost"] = validated_cost
			else:
				continue # 如果成本验证失败，跳过这个瓦片
		
		# 检查是否已存在
		if tile_types.has(tile_type):
			push_warning("TileJsonLoader: 发现重复的地形块类型: " + tile_type)
			continue
		
		# 存储地形块类型数据
		tile_types[tile_type] = tile_data
		loaded_count += 1
	
	print("TileJsonLoader: 从文件 " + file_path + " 成功加载 " + str(loaded_count) + " 个地形块类型")
	return true

# 读取指定路径数组中的所有地形块类型JSON文件
func load_all_tile_types(paths: Array = tile_types_files):
	for path in paths:
		# 检查是否为JSON文件
		if path.ends_with(".json") and FileAccess.file_exists(path):
			if load_tile_types(path):
				pass
			else:
				print("TileJsonLoader: 加载地形块类型JSON文件失败: " + path)
		else:
			push_error("TileJsonLoader: 路径无效或不是JSON文件: " + path)
	
	print("TileJsonLoader: 总共加载了 " + str(tile_types.size()) + " 个地形块类型")

# 加载所有地形块相关数据
func load_all_tile_data():
	load_all_tile_types()

# 清空所有数据
func clear_all_data():
	tile_types.clear()
	print("TileJsonLoader: 已清空所有地形块数据")


#endregion

#region 地形块类型数据获取函数
# 获取指定类型的地形块数据（返回副本，确保数据只读）
func get_tile_by_type(tile_type: String) -> Dictionary:
	if tile_types.has(tile_type):
		return tile_types[tile_type].duplicate(true)  # 深拷贝，确保返回的是副本
	else:
		push_error("TileJsonLoader: 找不到地形块类型: " + tile_type)
		return {}

# 获取指定unit_group的所有地形块数据（返回副本）
func get_tiles_by_unit_group(unit_group: String) -> Array:
	var result = []
	for tile_type in tile_types.keys():
		var tile_data = tile_types[tile_type]
		if tile_data.has("unit_group") and tile_data["unit_group"] == unit_group:
			var tile_data_copy = tile_data.duplicate(true)  # 深拷贝
			tile_data_copy["type"] = tile_type  # 添加type字段用于识别
			result.append(tile_data_copy)
	return result

# 根据瓦片类型名称获取纹理
func get_tile_texture(tile_type: String) -> Texture2D:
	var tile_data = get_tile_by_type(tile_type)
	if tile_data.is_empty():
		return null
	
	# 提取必要数据，相信配置的准确性
	var tileset_path = tile_data.get("tileset_path", "")
	var tile_coord = tile_data.get("tile_coord", {})
	var tile_id = tile_data.get("tile_id", 0)
	
	# 加载tileset
	var tileset = load(tileset_path) as TileSet
	if not tileset:
		return null
	
	# 构建坐标并直接获取纹理
	var coord = Vector2i(int(tile_coord.get("x", 0)), int(tile_coord.get("y", 0)))
	
	# 直接通过source_id获取源并提取纹理
	var source = tileset.get_source(tile_id) as TileSetAtlasSource
	if not source:
		return null
	
	# 直接获取纹理，相信tile_id的准确性
	var texture_region = source.get_tile_texture_region(coord)
	var atlas_texture = source.texture
	
	if atlas_texture and texture_region.size > Vector2i.ZERO:
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = atlas_texture
		atlas_tex.region = texture_region
		return atlas_tex
	
	return null

#endregion
