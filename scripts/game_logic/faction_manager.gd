extends Manager

# --- 阵营管理 ---
var faction_resources: Dictionary = {}  # 存储所有阵营资源 {faction_id: FactionResource}
var next_faction_id: int = 1000  # 下一个可用的四位数ID，从1000开始

func _ready():
	super._ready()
	
	# 创建默认的System faction
	create_system_faction()

func create_system_faction():
	"""创建默认的System faction"""
	# 使用固定ID 1000创建System faction
	var system_faction = FactionResource.new()
	system_faction.id = 1000
	system_faction.display_name = "System"
	system_faction.species_name = "System"
	system_faction.species_adjective = "System"
	
	# 初始化默认颜色
	system_faction.primary_color = Color.GRAY
	
	faction_resources[1000] = system_faction
	
	# 确保下一个faction ID从1001开始
	if next_faction_id <= 1000:
		next_faction_id = 1001
	
	print("FactionManager: 创建默认System faction，ID: 1000")
	return 1000

#region 阵营创建和管理方法
func create_faction(display_name: String = "", species_name: String = "", species_adjective: String = "") -> int:
	"""创建新的阵营，返回分配的四位数ID"""
	var new_id = next_faction_id
	next_faction_id += 1
	
	var new_faction = FactionResource.new()
	new_faction.id = new_id
	new_faction.display_name = display_name
	new_faction.species_name = species_name
	new_faction.species_adjective = species_adjective
	
	# 初始化默认颜色
	new_faction.primary_color = Color.WHITE
	
	faction_resources[new_id] = new_faction
	
	return new_id


# 获取指定ID的FactionResourc，未找到则返回null
func get_faction(faction_id: int) -> FactionResource:

	if faction_resources.has(faction_id):
		return faction_resources[faction_id]
	push_error("FactionManager: 找不到faction_id " + str(faction_id))
	return null

func get_all_faction_ids() -> Array[int]:
	"""获取所有阵营的ID列表"""
	var ids: Array[int] = []
	for id in faction_resources.keys():
		ids.append(id)
	return ids



#endregion

#region 外交关系管理方法
func set_diplomatic_relation(faction_a_id: int, faction_b_id: int, relation: GlobalEnum.DiplomaticRelation) -> bool:
	"""设置两个阵营之间的外交关系（双向设置）"""
	var faction_a = get_faction(faction_a_id)
	var faction_b = get_faction(faction_b_id)
	
	if faction_a and faction_b:
		faction_a.diplomatic_relations[faction_b_id] = relation
		faction_b.diplomatic_relations[faction_a_id] = relation
		return true
	
	return false

func get_diplomatic_relation(source_faction_id: int, target_faction_id: int) -> GlobalEnum.DiplomaticRelation:
	"""获取指定阵营与目标势力的外交关系"""
	var source_faction = get_faction(source_faction_id)
	if source_faction and source_faction.diplomatic_relations.has(target_faction_id):
		return source_faction.diplomatic_relations[target_faction_id]
	return GlobalEnum.DiplomaticRelation.UNKNOWN  # 默认为未知

func set_diplomatic_favor(faction_a_id: int, faction_b_id: int, favor: int):
	"""设置两个阵营之间的友好值（双向设置，-200到200）"""
	var faction_a = get_faction(faction_a_id)
	var faction_b = get_faction(faction_b_id)
	
	if faction_a and faction_b:
		var clamped_favor = clamp(favor, -200, 200)
		faction_a.diplomatic_favor[faction_b_id] = clamped_favor
		faction_b.diplomatic_favor[faction_a_id] = clamped_favor

func get_diplomatic_favor(source_faction_id: int, target_faction_id: int) -> int:
	"""获取指定阵营与目标势力的友好值"""
	var source_faction = get_faction(source_faction_id)
	if source_faction and source_faction.diplomatic_favor.has(target_faction_id):
		return source_faction.diplomatic_favor[target_faction_id]
	return 0  # 默认为0（中立）

func adjust_diplomatic_favor(faction_a_id: int, faction_b_id: int, change: int):
	"""调整两个阵营之间的友好值（双向调整，限制在-200到200之间）"""
	var current_favor = get_diplomatic_favor(faction_a_id, faction_b_id)
	var new_favor = current_favor + change
	set_diplomatic_favor(faction_a_id, faction_b_id, new_favor)

func set_diplomatic_visibility(faction_a_id: int, faction_b_id: int, visible: bool):
	"""设置两个阵营之间的外交能见度（双向设置，对等属性）"""
	var faction_a = get_faction(faction_a_id)
	var faction_b = get_faction(faction_b_id)
	
	if faction_a and faction_b:
		faction_a.diplomatic_visibility[faction_b_id] = visible
		faction_b.diplomatic_visibility[faction_a_id] = visible

func get_diplomatic_visibility(source_faction_id: int, target_faction_id: int) -> bool:
	"""获取指定阵营与目标势力的外交能见度"""
	var source_faction = get_faction(source_faction_id)
	if source_faction and source_faction.diplomatic_visibility.has(target_faction_id):
		return source_faction.diplomatic_visibility[target_faction_id]
	return false  # 默认为不可见

#region 情报系统方法

# 设置阵营的基础情报等级
func set_base_intelligence_level(faction_id: int, level: int):
	"""设置阵营的基础情报等级"""
	var faction = get_faction(faction_id)
	if faction:
		faction.base_intelligence_level = clamp(level, -100, 100)

# 获取阵营的基础情报等级
func get_base_intelligence_level(faction_id: int) -> int:
	"""获取阵营的基础情报等级"""
	var faction = get_faction(faction_id)
	if faction:
		return faction.base_intelligence_level
	return 0

# 设置对特定阵营的情报加成
func set_intelligence_bonus(source_faction_id: int, target_faction_id: int, bonus: int):
	"""设置对特定阵营的情报等级加成（可正可负）"""
	var source_faction = get_faction(source_faction_id)
	if source_faction:
		var clamped_bonus = clamp(bonus, -100, 100)
		if clamped_bonus == 0:
			# 如果加成为0，从字典中移除该项
			source_faction.intelligence_bonus.erase(target_faction_id)
		else:
			source_faction.intelligence_bonus[target_faction_id] = clamped_bonus

# 获取对特定阵营的情报加成
func get_intelligence_bonus(source_faction_id: int, target_faction_id: int) -> int:
	"""获取对特定阵营的情报等级加成"""
	var source_faction = get_faction(source_faction_id)
	if source_faction and source_faction.intelligence_bonus.has(target_faction_id):
		return source_faction.intelligence_bonus[target_faction_id]
	return 0  # 默认无加成

# 获取最终的情报等级（新计算公式）
func get_final_intelligence_level(source_faction_id: int, target_faction_id: int) -> int:
	"""获取最终情报等级：自身基础情报等级 + 自身对目标加成 - 目标对自身加成 - 目标基础情报等级"""
	var source_base_level = get_base_intelligence_level(source_faction_id)
	var source_bonus_to_target = get_intelligence_bonus(source_faction_id, target_faction_id)
	var target_bonus_to_source = get_intelligence_bonus(target_faction_id, source_faction_id)
	var target_base_level = get_base_intelligence_level(target_faction_id)
	
	var final_level = source_base_level + source_bonus_to_target - target_bonus_to_source - target_base_level
	return clamp(final_level, -100, 100)

# 调整基础情报等级
func adjust_base_intelligence_level(faction_id: int, change: int):
	"""调整阵营的基础情报等级"""
	var current_level = get_base_intelligence_level(faction_id)
	var new_level = clamp(current_level + change, -100, 100)
	set_base_intelligence_level(faction_id, new_level)

# 调整情报加成
func adjust_intelligence_bonus(source_faction_id: int, target_faction_id: int, change: int):
	"""调整对特定阵营的情报等级加成"""
	var current_bonus = get_intelligence_bonus(source_faction_id, target_faction_id)
	var new_bonus = clamp(current_bonus + change, -100, 100)
	set_intelligence_bonus(source_faction_id, target_faction_id, new_bonus)

#endregion

func set_diplomatic_data(faction_a_id: int, faction_b_id: int, data: Dictionary):
	"""统一设置外交数据的便捷方法
	data格式：{
		"relation": GlobalEnum.DiplomaticRelation (可选),
		"favor": int (可选),
		"visibility": bool (可选),
		"intelligence_bonus_a_to_b": int (可选) - A对B的情报加成,
		"base_intelligence_a": int (可选) - A的基础情报等级,
	}"""
	if data.has("relation"):
		set_diplomatic_relation(faction_a_id, faction_b_id, data["relation"])
	
	if data.has("favor"):
		set_diplomatic_favor(faction_a_id, faction_b_id, data["favor"])
	
	if data.has("visibility"):
		set_diplomatic_visibility(faction_a_id, faction_b_id, data["visibility"])
	
	# 新的情报系统参数
	if data.has("intelligence_bonus_a_to_b"):
		set_intelligence_bonus(faction_a_id, faction_b_id, data["intelligence_bonus_a_to_b"])
	
	if data.has("intelligence_bonus_b_to_a"):
		set_intelligence_bonus(faction_b_id, faction_a_id, data["intelligence_bonus_b_to_a"])
	
	if data.has("base_intelligence_a"):
		set_base_intelligence_level(faction_a_id, data["base_intelligence_a"])


func get_diplomatic_data(faction_a_id: int, faction_b_id: int) -> Dictionary:
	"""统一获取外交数据的便捷方法
	返回格式：{
		"relation": GlobalEnum.DiplomaticRelation,
		"favor": int,
		"visibility": bool,
		"base_intelligence_a": int,  # A的基础情报等级
		"base_intelligence_b": int,  # B的基础情报等级
		"intelligence_bonus_a_to_b": int,  # A对B的情报加成
		"intelligence_bonus_b_to_a": int,  # B对A的情报加成
		"final_intelligence_a_to_b": int,  # A对B的最终情报等级
		"final_intelligence_b_to_a": int   # B对A的最终情报等级
	}"""
	return {
		"relation": get_diplomatic_relation(faction_a_id, faction_b_id),
		"favor": get_diplomatic_favor(faction_a_id, faction_b_id),
		"visibility": get_diplomatic_visibility(faction_a_id, faction_b_id),
		# 基础情报等级
		"base_intelligence_a": get_base_intelligence_level(faction_a_id),
		"base_intelligence_b": get_base_intelligence_level(faction_b_id),
		# 情报加成
		"intelligence_bonus_a_to_b": get_intelligence_bonus(faction_a_id, faction_b_id),
		"intelligence_bonus_b_to_a": get_intelligence_bonus(faction_b_id, faction_a_id),
		# 最终计算结果
		"final_intelligence_a_to_b": get_final_intelligence_level(faction_a_id, faction_b_id),
		"final_intelligence_b_to_a": get_final_intelligence_level(faction_b_id, faction_a_id)
	}

#endregion
