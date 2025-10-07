extends Manager

func _ready() -> void:
	super._ready()
	# 目前TechManager不需要连接任何信号
	pass

func unlock_tech(faction: FactionResource, tech_type: StringName) -> bool:
	# 检查科技是否已解锁
	if tech_type in faction.unlocked_techs:
		push_error("TechManager: faction " + str(faction.id) + " 已解锁 tech_type " + tech_type)
		return false
	
	# 解锁科技
	faction.unlocked_techs.append(tech_type)
	print("TechManager: faction " + str(faction.id) + " 解锁了 tech_type " + tech_type)

	var tech_data = TechJsonLoader.get_tech(tech_type)

	# 解锁建筑
	for building in tech_data.get("unlocks", {}).get("building", []):
		faction.unlocked_buildings.append(building)

	# 解锁单位
	for ship in tech_data.get("unlocks", {}).get("ship", []):
		faction.unlocked_ships.append(ship)

	# 解锁资源
	for resource in tech_data.get("unlocks", {}).get("resource", []):
		faction.unlocked_resources.append(resource)
	
	# 添加科技加成
	var bonus_entries = tech_data.get("bonus", [])
	for bonus_entry in bonus_entries:
		add_tech_bonus(faction, bonus_entry, tech_type)

	 # 清除当前研究状态
	faction.researching_progress.erase(faction.current_researching_tech)
	faction.current_researching_tech = ""

	# 从selectable_techs和available_techs中移除
	faction.selectable_techs.erase(tech_type)
	faction.available_techs.erase(tech_type)
	return true

func set_current_researching_tech(faction: FactionResource, tech_type: StringName) -> bool:

	# 检查科技是否已解锁
	if tech_type in faction.unlocked_techs:
		push_error("TechManager: faction " + str(faction.id) + " 已解锁 tech_type " + tech_type)
		return false
	
	# 设置当前研究的科技
	faction.current_researching_tech = tech_type

	# 初始化研究进度
	if not faction.researching_progress.has(tech_type):
		faction.researching_progress[tech_type] = 0.0
 
	print("TechManager: faction " + str(faction.id) + " 开始研究 tech_type " + tech_type)

	return true

func update_researching_progress(faction: FactionResource) -> void:
	# 如果没有正在研究的科技，跳过并清空溢出值
	if faction.current_researching_tech.is_empty():
		faction.researching_overflow = 0.0
		return
	
	# 获取科技研究点数（使用TECH资源）
	var available_research_points = faction.get_resource_production(GlobalEnum.ResourceType.TECH)
	if available_research_points <= 0:
		push_error("TechManager: faction " + str(faction.id) + " TECH资源错误")
		return
	
	# 获取当前研究的科技数据
	var tech_data = TechJsonLoader.get_tech(faction.current_researching_tech)
	
	# 获取科技所需总研发点数
	var tech_cost = tech_data.get("cost")

	# 获取当前科技的研究进度
	var current_progress = faction.researching_progress.get(faction.current_researching_tech, 0.0)
	
	# 计算加上溢出值后的总研究点数
	var total_research_points = available_research_points + faction.researching_overflow
	
	# 更新研究进度
	current_progress += total_research_points
	
	# 检查科技是否完成
	if current_progress >= tech_cost:
		# 科技研究完成
		unlock_tech(faction, faction.current_researching_tech)

		# 计算溢出点数
		faction.researching_overflow = current_progress - tech_cost
		
	else:
		# 科技研究未完成，更新进度
		faction.researching_progress[faction.current_researching_tech] = current_progress
		faction.researching_overflow = 0.0

func calculate_tech_weight(faction: FactionResource, tech_type: StringName) -> float:
	var tech_data = TechJsonLoader.get_tech(tech_type)
	if tech_data.is_empty():
		push_error("TechManager: tech_type " + tech_type + " 数据为空")
		return 0.0
	
	# 仅对GENERAL类型科技计算权重
	if tech_data.get("tech_category") != GlobalEnum.TechCategory.GENERAL:
		push_warning("TechManager: tech_type " + tech_type + " 不是GENERAL类型，无权重")
		return 0.0
	
	# 计算权重
	var total_bonus = 0.0
	var total_multiplier = 0.0
	var weight_rules = tech_data.get("weight", [])
	
	for rule in weight_rules:
		match rule.get("rule"):
			"base_weight":
				var bonus = rule.get("bonus", 0.0)
				var multiplier = rule.get("multiplier")
				total_bonus += bonus
				total_multiplier += multiplier
			"has_tech":
				var required_tech = rule.get("tech_type", "")
				if required_tech in faction.unlocked_techs:
					var bonus = rule.get("bonus", 0.0)
					var multiplier = rule.get("multiplier")
					total_bonus += bonus
					total_multiplier += multiplier
			"has_event_flag":
				pass
			_:
				push_error("TechManager: 未知权重规则 " + str(rule.get("rule")) + " 在 tech_type " + tech_type)

	return total_bonus * (total_multiplier + 1.0)

func update_available_techs(faction: FactionResource) -> void:
	# 通过JsonLoader获取所有科技type
	var all_tech_types = TechJsonLoader.get_all_tech_types()
	
	# 遍历所有科技，跳过已解锁的科技(不跳过已经在available_techs中的科技，用于更新权重)
	for tech_type in all_tech_types:
		# 跳过已解锁的科技
		if tech_type in faction.unlocked_techs:
			continue
		
		# 获取科技数据
		var tech_data = TechJsonLoader.get_tech(tech_type)
		if tech_data.is_empty():
			continue
		
		# 检查前置条件(check_tech_prerequisites)
		if not check_tech_prerequisites(faction, tech_data):
			continue
		
		# 计算权重(calculate_tech_weight)，如果weight为null或小于0则设置为0.0，加入available_techs
		var weight = calculate_tech_weight(faction, tech_type)
		if weight <= 0:
			weight = 0.0
		
		faction.available_techs[tech_type] = weight

func check_tech_prerequisites(faction: FactionResource, tech_data: Dictionary) -> bool:

	# 检查前置科技
	for prerequisites in tech_data.get("prerequisites", []):
		if prerequisites not in faction.unlocked_techs:
			return false
	
	# 检查其他条件（如事件标志等），目前未实现，假设通过
	return true

func update_selectable_techs(faction: FactionResource) -> Dictionary:
	# 根据权重从available_techs中随机选择多个科技，加上现有selectable_techs后不超过max_count
	var max_count = faction.selectable_tech_count
	var remaining = max_count - faction.selectable_techs.size()
	
	if remaining <= 0:
		return faction.selectable_techs
	
	# 从available_techs中选择剩余数量的科技
	var item_weights = faction.available_techs.duplicate()
	
	while remaining > 0 and not item_weights.is_empty():
		var chosen = MathTools.weight_rand(item_weights)
		if chosen:
			faction.selectable_techs[chosen] = chosen
			item_weights.erase(chosen)  # 移除已选择的，避免重复
			remaining -= 1
		else :
			push_error("TechManager: 加权随机选择科技失败")
			break
	
	return faction.selectable_techs

func add_tech_bonus(faction: FactionResource, bonus_entry: Dictionary, tech_type: StringName) -> Array[int]:
	"""
	为阵营添加科技加成
	- faction: 目标阵营
	- bonus_entry: 加成条目字典，包含 bonus_type, target, rule 等字段
	- tech_type: 科技类型名称，用于标识加成来源
	返回: 添加的所有bonus的ID数组
	"""
	var bonus_ids: Array[int] = []
	var bonus_type = bonus_entry.get("bonus_type", "")
	var target_unit_type = bonus_entry.get("target", GlobalEnum.UnitType.UNKNOWN)
	var rule = bonus_entry.get("rule", "faction")

	if bonus_type.is_empty():
		push_error("TechManager: bonus_type为空")
		return bonus_ids
	
	# 根据rule确定目标单位范围
	var target_units: Array = []
	
	match rule:
		"faction":
			# 对阵营内所有指定类型的单位添加加成
			match target_unit_type:
				GlobalEnum.UnitType.PLANET:
					target_units = GlobalNodes.managers.PlanetManager.get_planets_by_faction(faction.id)
				GlobalEnum.UnitType.FLEET:
					target_units = GlobalNodes.managers.FleetManager.get_fleets_by_faction(faction.id)
				GlobalEnum.UnitType.STELLAR:
					target_units = GlobalNodes.managers.StellarManager.get_stellars_by_faction(faction.id)
				_:
					push_error("TechManager: 不支持的目标单位类型: " + str(target_unit_type))
					return bonus_ids
		"all":
			# 对所有指定类型的单位添加加成（暂未实现）
			push_warning("TechManager: rule 'all' 暂未实现")
			return bonus_ids
		_:
			push_error("TechManager: 未知的rule类型: " + rule)
			return bonus_ids
	
	# 为每个目标单位创建并执行UnitAddBonusByTypeAction
	for unit in target_units:
		var action = UnitAddBonusByTypeAction.new(unit.id, bonus_type)
		
		# 验证action
		var validation = action.validate()
		if not validation[0]:
			push_warning("TechManager: 无法为单位 " + str(unit.id) + " 添加加成: " + validation[1])
			continue
		
		# 执行action
		action.execute()
		
		# 收集添加的bonus IDs
		if action.bonus_ids.size() > 0:
			bonus_ids.append_array(action.bonus_ids)
	
	# 在faction的对应字典中记录bonus_type添加次数（每个科技的bonus算1次）
	if bonus_ids.size() > 0:
		match target_unit_type:
			GlobalEnum.UnitType.PLANET:
				if faction.planet_bonus.has(bonus_type):
					faction.planet_bonus[bonus_type] += 1
				else:
					faction.planet_bonus[bonus_type] = 1
			GlobalEnum.UnitType.FLEET:
				if faction.fleet_bonus.has(bonus_type):
					faction.fleet_bonus[bonus_type] += 1
				else:
					faction.fleet_bonus[bonus_type] = 1
			GlobalEnum.UnitType.STELLAR:
				if faction.stellar_bonus.has(bonus_type):
					faction.stellar_bonus[bonus_type] += 1
				else:
					faction.stellar_bonus[bonus_type] = 1
	
	print("TechManager: 为阵营 " + str(faction.id) + " 添加科技 " + tech_type + " 的加成，共 " + str(bonus_ids.size()) + " 个bonus")
	return bonus_ids
