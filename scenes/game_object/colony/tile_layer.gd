extends TileMapLayer

## 根据tile_type在指定坐标生成瓦片
## @param tile_type: 瓦片类型，从TileJsonLoader获取数据
## @param coord: 瓦片坐标
## @param alt_tile_index: 可选的alt_tile索引，如果为-1则随机选择
func generate_tile_at_coord(tile_type: String, coord: Vector2i, alt_tile_index: int = 0) -> bool:
	# 从TileJsonLoader获取瓦片数据
	var tile_data = TileJsonLoader.get_tile_by_type(tile_type)
	if tile_data == {}:
		push_error("GroundLayer: 无法找到瓦片类型: " + tile_type)
		return false
	
	# 获取必要的数据
	var tile_id = tile_data.get("tile_id", -1)
	var tile_coord_dict = tile_data.get("tile_coord", {})
	var tile_coord = Vector2(-1, -1)
	if tile_coord_dict.has("x") and tile_coord_dict.has("y"):
		tile_coord = Vector2(tile_coord_dict["x"], tile_coord_dict["y"])
	
	var alt_tile_array = tile_data.get("alt_tile", [])
	var alt_tile_id = 0
	if alt_tile_index < alt_tile_array.size():
		# 使用指定的alt_tile索引
		alt_tile_id = alt_tile_array[alt_tile_index]
	else:
		# 默认值
		alt_tile_id = alt_tile_array[0]
	
	if tile_id < 0 or tile_coord == Vector2(-1, -1):
		push_error("GroundLayer: 瓦片类型 " + tile_type + " 的数据无效")
		return false
	
	# 生成瓦片
	set_cell(coord, tile_id, Vector2i(tile_coord.x, tile_coord.y), alt_tile_id)
	
	return true
