extends Resource
class_name FactionResource

# 核心四位数ID
var id: int

# 身份信息
var display_name: String
var species_name: String
var species_adjective: String

# 命名规则 (这里我们直接存储数组，而不是引用NameList资源)
var planet_name_pool: Array[String]
var leader_name_pool: Array[String]

# 视觉信息
var primary_color: Color
var flag_texture: Texture2D # 旗帜依然可以是预设资源

# 动态游戏数据
var owned_stellar_ids: Array[int] = []
var owned_planet_ids: Array[int] = []
var owned_fleet_ids: Array[int] = []

# 已解锁内容
var unlocked_techs: Array[String] = []
var unlocked_buildings: Array[String] = []
var unlocked_ships: Array[String] = []

# 可研究科技列表
var selectable_tech_count: int = 3  # 每次可选择的科技数量
var available_techs: Dictionary[String, float] = {}  # 潜在可研究的科技列表，名称、权重

var selectable_techs: Dictionary[String,String] = {}  # 实际可选择的科技列表，名称，名称，模拟set


var current_researching_tech: String = ""  # 当前正在研究的科技名称
var researching_progress: Dictionary[String, float] = {}  # 当前研究中的科技进度
var researching_overflow: float = 0.0  # 研究溢出值


# 阵营级bonus记录
var planet_bonus: Dictionary[StringName,int] = {}
var fleet_bonus: Dictionary[StringName,int] = {}
var stellar_bonus: Dictionary[StringName,int] = {}







# 外交关系数据
# 存储与其他势力的友好值（-100到100，负数表示敌对，正数表示友好）
var diplomatic_favor: Dictionary = {}  # 格式：{faction_id: favor_value}
# 存储与其他势力的正式外交关系
var diplomatic_relations: Dictionary = {}  # 格式：{faction_id: GlobalEnum.DiplomaticRelation}
# 外交能见度（双方是否知晓对方的存在，对等属性）
var diplomatic_visibility: Dictionary = {}  # 格式：{faction_id: bool}
# 自身情报等级（影响对所有其他阵营的基础情报收集能力）
var base_intelligence_level: int = 0  # 默认为0
# 对特定阵营的情报等级加成（可正可负，默认为0）
var intelligence_bonus: Dictionary = {}  # 格式：{faction_id: int}，加成值

# 资源系统数据
var resources: Dictionary = {}  # 格式：{GlobalEnum.ResourceType: amount}
var resource_productions: Dictionary = {}  # 格式：{GlobalEnum.ResourceType: amount}

# _init 构造函数可以保持简单，或者完全不写
func _init():
	# 初始化资源系统
	for resource_type in GlobalEnum.ResourceType.values():
		resources[resource_type] = 0.0
		resource_productions[resource_type] = 0.0

# 恒星系所有权管理
func get_stellar_count() -> int:
	"""获取拥有的恒星系数量"""
	return owned_stellar_ids.size()

# 行星所有权管理
func get_planet_count() -> int:
	"""获取拥有的行星数量"""
	return owned_planet_ids.size()

# 舰队所有权管理
func get_fleet_count() -> int:
	"""获取拥有的舰队数量"""
	return owned_fleet_ids.size()

# 批量操作
func get_all_owned_objects() -> Dictionary:
	"""获取所有拥有的对象ID"""
	return {
		"stellars": owned_stellar_ids.duplicate(),
		"planets": owned_planet_ids.duplicate(),
		"fleets": owned_fleet_ids.duplicate()
	}

# 资源管理函数 - 仅提供查询功能
func get_resource(resource_type: GlobalEnum.ResourceType) -> float:
	"""获取资源数量"""
	return resources.get(resource_type, 0.0)

func check_resource(resource_type: GlobalEnum.ResourceType, amount: float) -> bool:
	"""检查资源是否足够"""
	return get_resource(resource_type) >= amount

func get_all_resources() -> Dictionary:
	"""获取所有资源"""
	return resources.duplicate()

# 预资源管理函数 - 仅提供查询功能
func get_resource_production(resource_type: GlobalEnum.ResourceType) -> float:
	"""获取预资源数量"""
	return resource_productions.get(resource_type, 0.0)

func get_all_resource_productions() -> Dictionary:
	"""获取所有预资源"""
	return resource_productions.duplicate()

func compare_resource_productions_with_current(additional_resources: Dictionary = {}) -> bool:
	"""比对预资源与当前资源"""
	var total_resource_productions = resource_productions.duplicate()
	
	for resource_type in additional_resources:
		if total_resource_productions.has(resource_type):
			total_resource_productions[resource_type] += additional_resources[resource_type]
		else:
			total_resource_productions[resource_type] = additional_resources[resource_type]
	
	for resource_type in total_resource_productions:
		var pre_amount = total_resource_productions[resource_type]
		var current_amount = get_resource(resource_type)
		
		if pre_amount > current_amount:
			return false
	
	return true
