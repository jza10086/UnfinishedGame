extends Unit
class_name Planet

# 唯一标识符
var planet_id: int = -1  # 七位数ID，由stellar的五位数ID + 两位序号组成

# 所有权信息
var owner_faction: int = -1  # 所属阵营ID，-1表示无主

var planet_type: String
var describe: String
var group: Array = []

# Colony 实例
var colony: ColonyResource

var colonized: bool = false  # 是否已殖民

var bonus_ids_from_colony: Array[int] = []  # 记录由colony添加的bonus ID

func _ready():
	# 初始化ColonyTile
	initialize_colony_tile()
	GlobalSignalBus.planet_update.connect(self.update)
	set_process(false)

# 静态方法：创建行星模型
static func create_planet_tscn(input_planet_type: String = "") -> Node3D:
	var scene_to_use: PackedScene
	
	# 通过 PlanetJsonLoader 获取行星类型数据和tscn路径
	if input_planet_type != "":
		var planet_type_data = PlanetJsonLoader.get_planet_type(input_planet_type)
		if not planet_type_data.is_empty():
			var planet_tscn_path = planet_type_data["tscn"]
			# 直接尝试加载场景
			scene_to_use = load(planet_tscn_path)
			if scene_to_use == null:
				push_error("无法找到行星场景,使用默认场景")
				scene_to_use = load("res://assets/model/planets/planet.tscn")
		else:
			push_error("无法找到行星类型数据,使用默认场景")
			scene_to_use = load("res://assets/model/planets/planet.tscn")
	else:
		push_error("无法找到行星场景,使用默认场景")
		scene_to_use = load("res://assets/model/planets/planet.tscn")

	var planet_instance = scene_to_use.instantiate()
	
	# 如果提供了行星类型，设置基本信息
	if input_planet_type != "":
		planet_instance.set_basic_infos(input_planet_type)
	
	return planet_instance

func _process(_delta):
	pass

func _init() -> void:
	unit_type = GlobalEnum.UnitType.PLANET

	# 初始化资源管理器
	bonus_resource = BonusResource.new()
	
	# 初始化colony
	colony = ColonyResource.new(self)

#region planet基础信息管理
func set_basic_infos(input_planet_type: String):
	planet_type = input_planet_type
	var planet_type_data = PlanetJsonLoader.get_planet_type(planet_type)
	
	if not planet_type_data.is_empty():
		# 设置基本信息
		describe = planet_type_data.get("describe", "")
		group = planet_type_data["group"]

		
		# 设置缩放
		self.scale = Vector3.ONE * planet_type_data.get("size", 1.0)

		# 根据planet_type_data设置行星基础资源
		set_basic_bonus(planet_type_data)
		# 初始化默认地形，使用JSON中的tile_amount参数
		var tile_amount = planet_type_data.get("tile_amount", 7)  # 默认值为7
		initialize_default_terrain(tile_amount)
	else:
		push_error("Planet: 找不到行星类型数据: " + input_planet_type)
	describe = planet_type_data["describe"]

# 设置行星的组（覆盖现有组）
func set_planet_groups(new_groups: Array):
	group = new_groups.duplicate()

#endregion

#region planet阵营管理

# 所有权管理方法
func set_faction_owner(faction_id: int):
	"""设置行星所有者"""
	owner_faction = faction_id
	# 通知ColonyTile阵营信息变化
	var colony_tile = get_node_or_null("ColonyTile")
	if colony_tile:
		if colony_tile.has_method("_on_planet_faction_changed"):
			# 使用新的回调方法通知变化
			colony_tile._on_planet_faction_changed(faction_id)
		elif colony_tile.has_method("set_planet_info"):
			# 备用方案：使用传统方式
			colony_tile.set_planet_info(planet_id, owner_faction)

func get_faction_owner() -> int:
	"""获取行星所有者，-1表示无主"""
	return owner_faction

#endregion

#region planet资源管理

# 设置行星的基础资源
func set_basic_bonus(planet_type_data: Dictionary):
	# 根据planet_type_data设置行星基础资源
	if planet_type_data.has("basic_resources"):
		for resource_type in planet_type_data["basic_resources"].keys():
			var resource_amount = planet_type_data["basic_resources"][resource_type]
			add_resource_bonus(resource_type, "行星基础值", BonusResource.BonusType.BASIC, resource_amount)


#endregion

#region colony管理

# 初始化默认地形
func initialize_default_terrain(tile_count: int):
	var coords = MathTools.generate_hex_tile_coords_by_count(tile_count)
	
	# 获取grass类型的tile数据
	var tile_data = TileJsonLoader.get_tile_by_type("grass")
	var alt_tile_array = []
	if tile_data.has("alt_tile") and tile_data["alt_tile"] is Array:
		alt_tile_array = tile_data["alt_tile"]
	
	for coord in coords:
		# 使用pick_random()随机选择alt_tile索引
		var alt_tile_index = 0
		if alt_tile_array.size() > 0:
			alt_tile_index = alt_tile_array.find(alt_tile_array.pick_random())
		
		# 将地形tile添加到colony的ground layer
		colony.add_tile("grass", coord, colony.colony_ground_tiles, alt_tile_index)

func get_colony_resource() -> ColonyResource:
	return colony

# 计算colony的tile产出资源
func calculate_colony_resources():
	"""计算并添加来自colony tile的资源到行星资源中"""
	if not colonized:
		return  # 如果未殖民，跳过计算

	if not colony:
		push_error("Planet: colony不存在，无法计算资源")
		return

	if not colony.is_changed:
		return  # 如果colony数据未变更，跳过计算

	# 先移除之前的colony资源加成（防止重复累加）
	for id in bonus_ids_from_colony:
		remove_resource_bonus(id)
	bonus_ids_from_colony.clear()
	
	# 从colony计算tile资源
	var tile_resources = colony.calculate_tile_resources()
	
	# 将tile资源添加到行星资源中
	for resource_type in tile_resources.keys():
		var resource_amount = tile_resources[resource_type]
		if resource_amount > 0:
			var id = add_resource_bonus(resource_type, "Colony产出", BonusResource.BonusType.BONUS, resource_amount)
			bonus_ids_from_colony.append(id)
	colony.is_changed = false  # 重置colony的变更标记

func initialize_colony_tile():
	"""初始化ColonyTile，设置行星信息"""
	var colony_tile = get_node_or_null("ColonyTile")
	if colony_tile:
		# 直接设置行星信息
		colony_tile.set_planet_info(planet_id, owner_faction)
		print("Planet: 已设置ColonyTile信息 - 行星ID:", planet_id, " 阵营ID:", owner_faction)

#endregion

func update():
	"""行星更新函数，处理行星的各种更新逻辑"""

	# 重新计算来自colony tile的资源
	calculate_colony_resources()
	
	# 发送行星更新完成信号
	GlobalSignalBus.planet_update_completed.emit()
