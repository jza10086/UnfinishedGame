extends Node2D

# 信号：当鼠标左键点击时发出，传递tile坐标
signal tile_clicked(tile_coord: Vector2i)

# 高亮层
@export var highlight_layer: TileMapLayer 
# 地形层
@export var ground_layer: TileMapLayer 
# 建筑层
@export var building_layer: TileMapLayer

# 当前鼠标所在的tile坐标
var current_tile_coord: Vector2i = Vector2i(-9999, -9999)
# 用来存储上一帧鼠标所在的单元格，避免重复处理
var last_hovered_cell: Vector2i = Vector2i(-9999, -9999)

func _input(event: InputEvent) -> void:
	# 处理鼠标左键点击
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 获取点击位置的tile坐标
			var clicked_coord = get_clicked_tile_coord(event.global_position)
			if clicked_coord != Vector2i(-9999, -9999):
				# 发出信号，传递tile坐标
				tile_clicked.emit(clicked_coord)

func _process(_delta: float) -> void:
	# 实时检测鼠标位置并转换为tile坐标
	update_mouse_tile_position()

func update_mouse_tile_position():
	"""检测鼠标位置并转换记录为tile坐标"""
	# 1. 获取鼠标在 TileMap 局部坐标系下的位置
	var mouse_pos: Vector2 = highlight_layer.get_local_mouse_position()
	
	# 2. 将局部位置转换为地图单元格坐标
	var current_hovered_cell: Vector2i = highlight_layer.local_to_map(mouse_pos)
	
	# 3. 如果鼠标悬停的单元格没有变化，就什么也不做
	if current_hovered_cell == last_hovered_cell:
		return
	
	# 4. 检查主地图层在该位置是否真的有图块
	if ground_layer.get_cell_source_id(current_hovered_cell) != -1:
		# 5. 更新当前tile坐标
		current_tile_coord = current_hovered_cell
		# 6. 在新的位置绘制高亮
		highlight_layer.highlight_cell(current_hovered_cell)
	else:
		# 7. 如果没有图块，设置为无效坐标
		current_tile_coord = Vector2i(-9999, -9999)
		# 8. 清除高亮
		highlight_layer.clear_highlight()

	# 9. 更新最后悬停的单元格位置
	last_hovered_cell = current_hovered_cell

## 获取鼠标点击位置的图块坐标
## @param global_mouse_pos: 鼠标的全局位置
## @return: 图块坐标，如果没有点击到图块则返回Vector2i(-9999, -9999)
func get_clicked_tile_coord(global_mouse_pos: Vector2) -> Vector2i:
	# 将全局坐标转换为地图层的局部坐标
	var local_pos = highlight_layer.to_local(global_mouse_pos)
	
	# 将局部坐标转换为地图单元格坐标
	var tile_coord = highlight_layer.local_to_map(local_pos)
	
	# 检查该位置是否有图块
	if ground_layer.get_cell_source_id(tile_coord) != -1:
		return tile_coord
	else:
		return Vector2i(-9999, -9999)

## 清空所有图层的瓦片
func clear_all_layers() -> void:
	"""清空所有图层的瓦片"""
	ground_layer.clear()
	building_layer.clear()
	highlight_layer.clear()


## 根据colony数据初始化绘制所有tiles
## @param colony_data: ColonyResource对象
func init_tiles_from_colony_data(colony_data) -> void:
	"""根据colony数据初始化绘制所有tiles"""
	if not colony_data:
		push_error("Tiles: colony_data为空，无法初始化tiles")
		return
	
	# 首先清空所有图层
	clear_all_layers()
	
	# 绘制地形tiles (colony_ground_tiles)
	for coord in colony_data.colony_ground_tiles.keys():
		var coord_data = colony_data.colony_ground_tiles[coord]
		for tile_type in coord_data.keys():
			var alt_tile_index = coord_data[tile_type]
			var success = _place_tile_at_coord(tile_type, coord, ground_layer, alt_tile_index)
			if not success:
				push_error("Tiles: 绘制地形tile失败 - 类型:" + tile_type + " 坐标:" + str(coord))
	
	# 绘制建筑tiles (colony_building_tiles)
	for coord in colony_data.colony_building_tiles.keys():
		var coord_data = colony_data.colony_building_tiles[coord]
		for tile_type in coord_data.keys():
			var alt_tile_index = coord_data[tile_type]
			var success = _place_tile_at_coord(tile_type, coord, building_layer, alt_tile_index)
			if not success:
				push_error("Tiles: 绘制建筑tile失败 - 类型:" + tile_type + " 坐标:" + str(coord))
	

## 在指定坐标和层放置瓦片的内部函数
## @param tile_type: 瓦片类型
## @param coord: 坐标
## @param layer: 目标层
## @param alt_tile_index: 可选的alt_tile索引，默认为0
## @return: 是否成功放置
func _place_tile_at_coord(tile_type: String, coord: Vector2i, layer: TileMapLayer, alt_tile_index: int = 0) -> bool:
	"""在指定坐标和层放置瓦片"""
	var success = layer.generate_tile_at_coord(tile_type, coord, alt_tile_index)
	if not success:
		push_error("Tiles: 在坐标 " + str(coord) + " 放置瓦片失败: " + tile_type)
	
	return success
