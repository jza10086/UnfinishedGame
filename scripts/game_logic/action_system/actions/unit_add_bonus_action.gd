extends UnitAction
class_name UnitAddBonusAction

var unit_id: int
var unit: Unit
var unit_type: GlobalEnum.UnitType

var bonus_ids: Array[int] = []  # 用于标识这些加成的唯一ID数组

var source_name: String
var bonus_type: BonusResource.BonusType
var resources: Dictionary  # 资源类型到数量的映射 {GlobalEnum.ResourceType: float}
var stackable: bool
var duration_turns: int  # 持续回合数，-1为永久

var execute_once: bool = false  # 标记是否已经执行过




func _init(p_unit_id: int, p_resources: Dictionary, p_source_name: String,
p_bonus_type: BonusResource.BonusType, p_stackable: bool = false, p_duration_turns: int = -1) -> void:

	action_name = "UnitAddBonusAction"
	unit_id = p_unit_id
	unit_type = _get_unit_type_by_id(p_unit_id)  # 根据ID判断并赋值unit_type
	resources = p_resources
	source_name = p_source_name
	bonus_type = p_bonus_type
	stackable = p_stackable
	duration_turns = p_duration_turns
	
func execute() -> void:
	if not execute_once:
		# 为每个资源类型添加加成
		for resource_type in resources.keys():
			var amount = resources[resource_type]
			var id = unit.add_resource_bonus(resource_type, source_name, bonus_type, amount)
			bonus_ids.append(id)
		execute_once = true  # 标记已经执行过

	# 检查duration_turns
	if duration_turns == 0:
		_finished()
	elif duration_turns > 0:
		duration_turns -= 1

# 根据unit id判断unit类型
func _get_unit_type_by_id(id: int) -> GlobalEnum.UnitType:
	"""
	根据单位ID范围判断单位类型
	- Planet_id: 1000001-9999999 (七位数)
	- Fleet_id: 100000-999999 (六位数)
	- Stellar_id: 10000-99999 (五位数)
	"""
	if id >= 1000001 and id <= 9999999:
		return GlobalEnum.UnitType.PLANET
	elif id >= 100000 and id <= 999999:
		return GlobalEnum.UnitType.FLEET
	elif id >= 10000 and id <= 99999:
		return GlobalEnum.UnitType.STELLAR
	else:
		# 如果ID不在预期范围内，返回默认值
		return GlobalEnum.UnitType.UNKNOWN

# 根据ID和类型到对应Manager查询unit
func _get_unit_by_id_and_type(id: int, type: GlobalEnum.UnitType) -> Unit:
	"""
	根据单位ID和类型到对应的Manager查询单位实例
	- PLANET: 通过PlanetManager.get_planet_by_id()查询
	- FLEET: 通过FleetManager.get_fleet_by_id()查询
	- STELLAR: 通过StellarManager.get_stellar_by_id()查询
	"""
	match type:
		GlobalEnum.UnitType.PLANET:
			return GlobalNodes.managers.PlanetManager.get_planet_by_id(id)
		
		GlobalEnum.UnitType.FLEET:
			return GlobalNodes.managers.FleetManager.get_fleet_by_id(id)
		
		GlobalEnum.UnitType.STELLAR:
			return GlobalNodes.managers.StellarManager.get_stellar_by_id(id)
		
		_:
			return null

func validate() -> Array:
	# 验证unit_id是否有效
	# 根据ID和类型查询unit
	unit = _get_unit_by_id_and_type(unit_id, unit_type)
	if not unit:
		return [false, "找不到ID为 " + str(unit_id) + " 的单位"]

	if unit_type == GlobalEnum.UnitType.UNKNOWN:
		return [false, "无法识别的单位类型，ID: " + str(unit_id)]

	# 验证resources字典
	if resources.is_empty():
		return [false, "resources字典不能为空"]
	
	# 验证资源类型和数值
	for resource_type in resources.keys():
		var amount = resources[resource_type]
		
		# 验证资源类型是否有效
		if not resource_type is GlobalEnum.ResourceType:
			return [false, "无效的资源类型: " + str(resource_type)]
		
		# 验证amount是否为有效数值
		if not (amount is float or amount is int):
			return [false, "资源数量必须是数值类型: " + str(amount)]

	if duration_turns == 0:
		return [false, "持续回合数不能为0"]

	return [true, ""]

func cancel() -> void:
	_finished()

func _finished() -> void:

	# 移除之前添加的所有bonus
	for id in bonus_ids:
		unit.remove_resource_bonus(id)

	super._finished()
