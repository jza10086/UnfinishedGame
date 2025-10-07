extends Control

@export var current_faction_id: int = 1000  # 当前查看的阵营ID
@export var table: GenericTable
@export var faction_info_label:Label
@export var declare_war_button:Button
@export var declare_war_info_area:Control  # 宣战按钮的悬浮提示区域


var selected_faction_id: int = -1  # 当前选中的目标阵营ID
var last_validation_result: Dictionary = {}  # 保存最后一次验证结果

var red_label = preload("res://scenes/ui/components/special_node/special_rich_text_label_red.tscn")

func _ready():
	# 设置表格的列键
	table.column_keys = ["faction_name", "relation", "favor", "intelligence_out"]
	
	# 设置表格列数
	table.set_columns(4)
	
	# 初始化表格
	table.initialize()
	
	# 设置列标题
	_setup_column_titles()
	
	# 连接信号
	table.row_clicked.connect(_on_diplomatic_row_clicked)
	
	# 初始化faction_info_label
	selected_faction_id = current_faction_id
	_show_faction_info(selected_faction_id)

	# 加载外交数据
	load_diplomatic_data()


# 检查是否可以对指定阵营宣战 - 使用Action的预验证
func can_declare_war_on_faction(target_faction_id: int = selected_faction_id) -> Dictionary:
	var validation_result = DiplomacyRelationshipAction.can_execute(
		current_faction_id,
		target_faction_id,
		GlobalEnum.DiplomaticRelation.HOSTILE
	)
	
	# 保存验证结果
	last_validation_result = validation_result
	
	# 根据验证结果设置按钮状态
	if declare_war_button:
		declare_war_button.disabled = not validation_result["valid"]
	
	# 更新info_area的悬浮提示
	if declare_war_info_area:
		if declare_war_button and declare_war_button.disabled:
			# 构建错误消息
			var error_message = "无法宣战："
			if validation_result.has("error_message") and validation_result["error_message"] != "":
				error_message += validation_result["error_message"]
			else:
				error_message += "不满足宣战条件"
			
			# 将错误信息转换为红色
			error_message = TextTools.BBcode_warning(error_message)
			
			# 设置info_area
			declare_war_info_area.set_text(error_message)
			declare_war_info_area.set_enabled(true)
		else:
			# 按钮可用时禁用悬浮提示
			declare_war_info_area.set_enabled(false)
	
	return validation_result

# 设置列标题
func _setup_column_titles():
	if table.tree:
		table.tree.set_column_title(0, "势力名称")
		table.tree.set_column_title(1, "外交关系")
		table.tree.set_column_title(2, "友好度")
		table.tree.set_column_title(3, "相对情报等级")
		
		# 设置所有列标题为左对齐
		table.tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
		table.tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
		table.tree.set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_LEFT)
		table.tree.set_column_title_alignment(3, HORIZONTAL_ALIGNMENT_LEFT)
		
		# 配置每一列的宽度和扩展行为
		
		# "势力名称" (第 0 列): 让它自动扩展以填充剩余空间
		table.tree.set_column_expand(0, true)
		
		# "外交关系" (第 1 列): 固定宽度，不扩展
		table.tree.set_column_expand(1, false)
		table.tree.set_column_custom_minimum_width(1, 200)
		
		# "友好度" (第 2 列): 固定宽度，不扩展
		table.tree.set_column_expand(2, false)
		table.tree.set_column_custom_minimum_width(2, 200)

		# "相对情报等级" (第 3 列): 固定宽度，不扩展
		table.tree.set_column_expand(3, false)
		table.tree.set_column_custom_minimum_width(3, 200)


# 设置当前阵营
func set_current_faction(faction_id: int):
	current_faction_id = faction_id

# 加载外交数据
func load_diplomatic_data():
	if not GlobalNodes.FactionManager:
		push_error("FactionManager不可用")
		return
	
	# 清空现有数据
	table.clear_data()
	
	var all_factions = GlobalNodes.FactionManager.get_all_faction_ids()
	
	for faction_id in all_factions:
		var faction = GlobalNodes.FactionManager.get_faction(faction_id)
		if not faction:
			continue
		
		var row_data = {}
		
		# 如果是当前阵营自己，显示特殊数据
		if faction_id == current_faction_id:
			row_data = {
				"faction_id": faction_id,
				"faction_name": faction.display_name + " (当前)",
				"relation": "-",
				"favor": "-",
				"intelligence_out": "-"
			}
			# 添加普通行数据
			table.add_data(row_data)
		else:
			# 获取外交信息
			var diplomatic_info = GlobalNodes.FactionManager.get_diplomatic_data(current_faction_id, faction_id)
			
			# 只显示有外交能见度的势力
			if diplomatic_info["visibility"]:
				row_data = {
					"faction_id": faction_id,
					"faction_name": faction.display_name,
					"relation": _format_relation(diplomatic_info["relation"]),
					"favor": _format_favor(diplomatic_info["favor"]),
					"intelligence_out": diplomatic_info["final_intelligence_a_to_b"]
				}
				
				# 根据外交关系选择场景 - 只针对relation列
				if diplomatic_info["relation"] == GlobalEnum.DiplomaticRelation.HOSTILE:
					# 为敌对关系的relation列添加特殊标记
					row_data["_scene_relation"] = red_label
				
				# 添加行数据
				table.add_data(row_data)

# 格式化外交关系
func _format_relation(relation_enum) -> String:
	match relation_enum:
		GlobalEnum.DiplomaticRelation.ALLIED:
			return "盟友"
		GlobalEnum.DiplomaticRelation.FRIENDLY:
			return "友好"
		GlobalEnum.DiplomaticRelation.NEUTRAL:
			return "中立"
		GlobalEnum.DiplomaticRelation.HOSTILE:
			return "敌对"
		GlobalEnum.DiplomaticRelation.UNKNOWN:
			return "未知"
		_:
			return "未知"

# 格式化友好度
func _format_favor(favor_value: int) -> String:
	if favor_value > 0:
		return "+%d" % favor_value
	else:
		return "%d" % favor_value

# 处理外交行点击事件
func _on_diplomatic_row_clicked(row_data: Dictionary, _row_index: int):
	var target_faction_id = row_data.get("faction_id", -1)
	if target_faction_id == -1:
		return
	
	# 记录选中的阵营ID
	selected_faction_id = target_faction_id
	
	# 显示阵营信息（统一显示，不论是当前阵营还是其他阵营）
	_show_faction_info(target_faction_id)

# 显示阵营信息（统一函数）
func _show_faction_info(faction_id: int):
	var faction = GlobalNodes.FactionManager.get_faction(faction_id)
	if not faction:
		return
	
	if not faction_info_label:
		return
	
	var info_text = "=== 阵营信息 ===\n"
	info_text += "阵营名称：%s\n" % faction.display_name
	info_text += "种族名称：%s\n" % faction.species_name
	info_text += "种族形容词：%s\n" % faction.species_adjective
	info_text += "拥有恒星系：%d 个\n" % faction.get_stellar_count()
	info_text += "拥有行星：%d 个\n" % faction.get_planet_count()
	info_text += "拥有舰队：%d 个\n" % faction.get_fleet_count()
	
	# 统一显示外交信息（包括当前阵营）
	info_text += "\n=== 外交信息 ===\n"
	if faction_id != current_faction_id:
		var diplomatic_info = GlobalNodes.FactionManager.get_diplomatic_data(current_faction_id, faction_id)
		info_text += "当前关系：%s\n" % _format_relation(diplomatic_info["relation"])
		info_text += "友好度：%s\n" % _format_favor(diplomatic_info["favor"])
		info_text += "相对情报等级：%d\n" % diplomatic_info["final_intelligence_a_to_b"]
		info_text += "外交可见性：%s" % ("是" if diplomatic_info["visibility"] else "否")
	else:
		info_text += "当前关系：-\n"
		info_text += "友好度：-\n"
		info_text += "相对情报等级：-\n"
		info_text += "外交可见性：-\n"
	
	faction_info_label.text = info_text
	can_declare_war_on_faction()  # 更新宣战按钮状态

# 刷新外交数据
func refresh_data():
	load_diplomatic_data()

# 获取当前阵营信息
func get_current_faction() -> FactionResource:
	if GlobalNodes.FactionManager:
		return GlobalNodes.FactionManager.get_faction(current_faction_id)
	return null

# 获取当前选中的目标阵营信息
func get_selected_faction() -> FactionResource:
	if selected_faction_id != -1 and GlobalNodes.FactionManager:
		return GlobalNodes.FactionManager.get_faction(selected_faction_id)
	return null

func _on_button_pressed() -> void:
	GlobalNodes.UIManager.back_to_main()

func _on_declare_war_pressed() -> void:
	# 创建外交关系Action
	var diplomacy_action = DiplomacyRelationshipAction.new(
		current_faction_id,
		selected_faction_id,
		GlobalEnum.DiplomaticRelation.HOSTILE
	)
	
	# 添加到Action系统
	GlobalNodes.ActionManager.add_action(diplomacy_action)

func init_panel(_data):
	pass
