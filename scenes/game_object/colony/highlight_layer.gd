extends TileMapLayer

# 高亮图块的信息
const HIGHLIGHT_SOURCE_ID: int = 0
const HIGHLIGHT_ATLAS_COORD: Vector2i = Vector2i(0, 0)

# 用来存储当前高亮的单元格
var current_highlighted_cell: Vector2i = Vector2i(-9999, -9999)

## 在指定坐标绘制高亮
## @param coord: 要高亮的坐标
func highlight_cell(coord: Vector2i) -> void:
	# 如果已经在高亮这个位置，就不需要重复绘制
	if current_highlighted_cell == coord:
		return
	
	# 清除之前的高亮
	clear_highlight()
	
	# 绘制新的高亮
	set_cell(coord, HIGHLIGHT_SOURCE_ID, HIGHLIGHT_ATLAS_COORD)
	current_highlighted_cell = coord

## 清除高亮
func clear_highlight() -> void:
	if current_highlighted_cell != Vector2i(-9999, -9999):
		set_cell(current_highlighted_cell, -1)
		current_highlighted_cell = Vector2i(-9999, -9999)
