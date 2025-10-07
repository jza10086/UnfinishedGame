extends Control
class_name GenericTable

@export var tree: Tree
@export var column_keys: Array[String] = []  # 在编辑器中配置列对应的数据键

var default_rich_text_scene: PackedScene = preload("res://scenes/ui/components/special_node/special_rich_text_label.tscn")  # 默认的RichTextLabel场景

var table_data: Array = []
var current_sort_column: int = -1
var sort_ascending: bool = true

# RichTextLabel设置
var rich_text_instances: Dictionary = {}  # 缓存RichTextLabel实例，键为"row_col"格式

# 信号
signal row_clicked(row_data: Dictionary, row_index: int)

func _ready() -> void:
	if tree:
		tree.column_title_clicked.connect(_on_column_title_clicked)
		tree.item_selected.connect(_on_item_selected)

# 简单初始化 - 只设置基本属性
func initialize() -> void:
	if tree:
		tree.hide_root = true
		tree.allow_rmb_select = true

# 设置表格列数
func set_columns(column_count: int) -> void:
	if tree:
		tree.columns = column_count

# 设置数据
func set_data(data: Array, rich_text_scene: PackedScene = null) -> void:
	table_data = data.duplicate()
	_populate_table(rich_text_scene)

# 获取数据
func get_data() -> Array:
	return table_data.duplicate()

# 更新数据
func update_data(index: int, new_data: Dictionary, rich_text_scene: PackedScene = null) -> void:
	if index >= 0 and index < table_data.size():
		table_data[index] = new_data
		_populate_table(rich_text_scene)

# 添加数据
func add_data(row_data: Dictionary, rich_text_scene: PackedScene = null) -> void:
	table_data.append(row_data)
	_populate_table(rich_text_scene)

# 清空数据
func clear_data() -> void:
	table_data.clear()
	if tree:
		tree.clear()

# 获取选中行数据
func get_selected_data() -> Dictionary:
	if not tree:
		return {}
	
	var selected_item = tree.get_selected()
	if not selected_item:
		return {}
	
	var index = selected_item.get_index()
	if index >= 0 and index < table_data.size():
		return table_data[index]
	
	return {}

# 获取选中行索引
func get_selected_index() -> int:
	if not tree:
		return -1
	
	var selected_item = tree.get_selected()
	if not selected_item:
		return -1
	
	return selected_item.get_index()

# 内部方法：填充表格
func _populate_table(rich_text_scene: PackedScene = null) -> void:
	if not tree or column_keys.is_empty():
		return
	
	# 清理之前的RichTextLabel实例
	_cleanup_rich_text_instances()
	
	tree.clear()
	rich_text_instances.clear()  # 清空实例缓存
	var root = tree.create_item()
	
	for i in range(table_data.size()):
		var row_data = table_data[i]
		var tree_item = tree.create_item(root)
		
		# 为每列设置数据
		for col_index in range(min(column_keys.size(), tree.columns)):
			var key = column_keys[col_index]
			var value = row_data.get(key, "")
			
			# 所有列都使用RichTextLabel
			_create_rich_text_cell(tree_item, col_index, str(value), i, rich_text_scene)
		
		# 存储行索引到metadata
		tree_item.set_metadata(0, i)

# 检查是否使用默认RichTextLabel场景
func is_using_rich_text_scene() -> bool:
	return default_rich_text_scene != null

# 设置默认RichTextLabel场景
func set_default_rich_text_scene(scene: PackedScene) -> void:
	default_rich_text_scene = scene
	# 重新填充表格以应用新的场景
	if not table_data.is_empty():
		_populate_table()

# 清理RichTextLabel实例
func _cleanup_rich_text_instances() -> void:
	for key in rich_text_instances.keys():
		var instance_data = rich_text_instances[key]
		if instance_data.has("scene_instance") and instance_data["scene_instance"]:
			instance_data["scene_instance"].queue_free()
	rich_text_instances.clear()

# 递归查找RichTextLabel控件
func _find_rich_text_label(node: Node) -> RichTextLabel:
	if node is RichTextLabel:
		return node
	
	for child in node.get_children():
		var result = _find_rich_text_label(child)
		if result:
			return result
	
	return null

# 自定义绘制RichTextLabel单元格
func _custom_draw_rich_text_cell(_item: TreeItem, rect: Rect2, column_index: int, row_index: int) -> void:
	if not tree:
		return
	
	var cache_key = str(row_index) + "_" + str(column_index)
	
	# 调整绘制区域
	var panel_rect = Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4))
	
	# 强制要求有RichTextLabel实例
	if not rich_text_instances.has(cache_key):
		push_error("错误: 未找到RichTextLabel实例，缓存键: " + cache_key)
		return
	
	var instance_data = rich_text_instances[cache_key]
	var rich_text_label = instance_data.get("rich_text_label")
	
	if not rich_text_label or not rich_text_label is RichTextLabel:
		push_error("错误: RichTextLabel实例无效，缓存键: " + cache_key)
		return
	
	# 使用RichTextLabel场景的样式进行绘制（包含背景）
	_draw_rich_text_label_content(rich_text_label, panel_rect)

# 绘制RichTextLabel内容
func _draw_rich_text_label_content(rich_text_label: RichTextLabel, rect: Rect2) -> void:
	# 使用RichTextLabel场景中的样式进行绘制
	_draw_rich_text_with_scene_style(rich_text_label, rect)

# 使用场景样式绘制RichTextLabel
func _draw_rich_text_with_scene_style(rich_text_label: RichTextLabel, rect: Rect2) -> void:
	var canvas_item = tree.get_canvas_item()
	
	# 设置RichTextLabel的位置和大小
	rich_text_label.position = rect.position
	rich_text_label.size = rect.size
	
	# 获取RichTextLabel的样式 - 首先尝试获取主题覆写样式
	var normal_style = null
	if rich_text_label.has_theme_stylebox_override("normal"):
		normal_style = rich_text_label.get_theme_stylebox("normal")
	elif rich_text_label.theme:
		# 从主题中获取样式
		normal_style = rich_text_label.theme.get_stylebox("normal", "RichTextLabel")
	
	# 绘制背景样式
	if normal_style:
		normal_style.draw(canvas_item, rect)
	else:
		# 使用默认样式
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.3, 0.3, 0.3, 0.8)
		style_box.draw(canvas_item, rect)
	
	# 获取字体信息
	var font = null
	var font_size = 16
	var font_color = Color.WHITE
	
	# 尝试获取主题字体
	if rich_text_label.has_theme_font_override("normal_font"):
		font = rich_text_label.get_theme_font("normal_font")
	elif rich_text_label.theme:
		font = rich_text_label.theme.get_font("normal_font", "RichTextLabel")
	
	# 尝试获取字体大小
	if rich_text_label.has_theme_font_size_override("normal_font_size"):
		font_size = rich_text_label.get_theme_font_size("normal_font_size")
	elif rich_text_label.theme:
		font_size = rich_text_label.theme.get_font_size("normal_font_size", "RichTextLabel")
	
	# 尝试获取字体颜色
	if rich_text_label.has_theme_color_override("default_color"):
		font_color = rich_text_label.get_theme_color("default_color")
	elif rich_text_label.theme:
		font_color = rich_text_label.theme.get_color("default_color", "RichTextLabel")
	
	# 如果获取不到，使用默认值
	if not font:
		font = ThemeDB.fallback_font
	if font_size <= 0:
		font_size = 16
	
	# 获取文本内容
	var text = rich_text_label.text
	if rich_text_label.bbcode_enabled:
		# 如果启用了BBCode，获取解析后的文本
		text = rich_text_label.get_parsed_text()
	
	# 计算文本绘制位置
	var content_rect = rect
	if normal_style:
		# 考虑样式的内边距
		content_rect = Rect2(
			rect.position.x + normal_style.get_margin(SIDE_LEFT),
			rect.position.y + normal_style.get_margin(SIDE_TOP),
			rect.size.x - normal_style.get_margin(SIDE_LEFT) - normal_style.get_margin(SIDE_RIGHT),
			rect.size.y - normal_style.get_margin(SIDE_TOP) - normal_style.get_margin(SIDE_BOTTOM)
		)
	
	# 绘制文本
	if font and not text.is_empty():
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos = Vector2(
			content_rect.position.x + 4,  # 左对齐，留一点边距
			content_rect.position.y + (content_rect.size.y + text_size.y) * 0.5
		)
		font.draw_string(canvas_item, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, font_color)

# 简单的BBCode标签清理函数
# 创建RichTextLabel单元格
func _create_rich_text_cell(tree_item: TreeItem, column_index: int, text: String, row_index: int, rich_text_scene: PackedScene = null) -> void:
	# 设置单元格模式为自定义
	tree_item.set_cell_mode(column_index, TreeItem.CELL_MODE_CUSTOM)
	
	# 检查是否有BBCode版本的文本
	var bbcode_key = "_bbcode_" + column_keys[column_index]
	var final_text = text
	if row_index < table_data.size() and table_data[row_index].has(bbcode_key):
		final_text = table_data[row_index][bbcode_key]
	
	var cache_key = str(row_index) + "_" + str(column_index)
	
	# 检查是否有特定列的场景指定
	var column_key = column_keys[column_index]
	var scene_key = "_scene_" + column_key
	var column_specific_scene = null
	
	if row_index < table_data.size() and table_data[row_index].has(scene_key):
		column_specific_scene = table_data[row_index][scene_key]
	
	# 优先级：列特定场景 > 传入场景 > 默认场景
	var scene_to_use = column_specific_scene
	if not scene_to_use:
		scene_to_use = rich_text_scene if rich_text_scene != null else default_rich_text_scene
	
	# 强制使用RichTextLabel场景，如果没有场景则报错
	if not scene_to_use:
		push_error("错误: 必须设置RichTextLabel场景！")
		return
	
	var scene_instance = scene_to_use.instantiate()
	if not scene_instance:
		push_error("错误: 无法实例化RichTextLabel场景")
		return
	
	# 查找场景中的RichTextLabel
	var rich_text_label = null
	if scene_instance is RichTextLabel:
		rich_text_label = scene_instance
	else:
		rich_text_label = _find_rich_text_label(scene_instance)
	
	if not rich_text_label:
		push_error("错误: 在场景中未找到RichTextLabel")
		scene_instance.queue_free()
		return
	
	# 设置文本内容
	rich_text_label.bbcode_enabled = true
	rich_text_label.text = final_text
	
	# 存储到实例缓存中
	rich_text_instances[cache_key] = {
		"scene_instance": scene_instance,
		"rich_text_label": rich_text_label
	}
	
	# 设置自定义绘制回调
	tree_item.set_custom_draw_callback(column_index, Callable(self, "_custom_draw_rich_text_cell").bind(column_index, row_index))

# 排序功能
func _on_column_title_clicked(column_index: int, mouse_button_index: int = MOUSE_BUTTON_LEFT) -> void:
	if column_index >= column_keys.size():
		return
	
	# 只处理左键点击
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	
	# 更新排序状态
	if column_index == current_sort_column:
		sort_ascending = not sort_ascending
	else:
		current_sort_column = column_index
		sort_ascending = true
	
	# 执行排序
	var sort_key = column_keys[column_index]
	table_data.sort_custom(
		func(a: Dictionary, b: Dictionary):
			var value_a = a.get(sort_key, "")
			var value_b = b.get(sort_key, "")
			
			# 处理排序值
			var sort_a = _get_sort_value(value_a)
			var sort_b = _get_sort_value(value_b)
			
			if sort_ascending:
				return _compare_values(sort_a, sort_b) < 0
			else:
				return _compare_values(sort_a, sort_b) > 0
	)
	
	_populate_table()

# 获取用于排序的值
func _get_sort_value(value) -> Variant:
	# 如果是"-"，当做0处理
	if str(value) == "-":
		return 0
	
	# 如果是数字字符串，转换为数字
	var str_value = str(value)
	if str_value.is_valid_int():
		return str_value.to_int()
	elif str_value.is_valid_float():
		return str_value.to_float()
	
	# 处理带+号的数字（如+60）
	if str_value.begins_with("+") and str_value.substr(1).is_valid_int():
		return str_value.substr(1).to_int()
	elif str_value.begins_with("+") and str_value.substr(1).is_valid_float():
		return str_value.substr(1).to_float()
	
	# 其他情况当做字符串处理
	return str_value.to_lower()  # 转换为小写以便不区分大小写排序

# 比较两个值
func _compare_values(a: Variant, b: Variant) -> int:
	# 如果两个值类型相同，直接比较
	if typeof(a) == typeof(b):
		if a < b:
			return -1
		elif a > b:
			return 1
		else:
			return 0
	
	# 数字优先于字符串
	if (typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT) and typeof(b) == TYPE_STRING:
		return -1
	elif typeof(a) == TYPE_STRING and (typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT):
		return 1
	
	# 其他情况转换为字符串比较
	var str_a = str(a)
	var str_b = str(b)
	if str_a < str_b:
		return -1
	elif str_a > str_b:
		return 1
	else:
		return 0

# 行点击回调
func _on_item_selected() -> void:
	var selected_data = get_selected_data()
	var selected_index = get_selected_index()
	
	if not selected_data.is_empty() and selected_index >= 0:
		row_clicked.emit(selected_data, selected_index)
