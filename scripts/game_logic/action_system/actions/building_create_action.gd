extends Action
class_name BuildingCreateAction

# 建筑建造相关数据
var faction_id: int
var building_type: String
var coord: Vector2i
var slot_index: int

# 缓存的对象引用
var building_data: Dictionary
var colony: Resource
var faction: Resource
var turn_left: int = 0  # 剩余建造回合数
var turn_total: int = 0  # 总建造回合数
var resource_cost: Dictionary = {}

func _init(p_faction_id: int, p_colony: Resource, p_building_type: String, p_coord: Vector2i, p_slot_index: int):
	super._init()
	faction_id = p_faction_id
	colony = p_colony
	building_type = p_building_type
	coord = p_coord
	slot_index = p_slot_index
	executer = p_colony  # 使用colony作为executer
	
	# 通过building_type从TileJsonLoader获取building数据
	building_data = TileJsonLoader.get_tile_by_type(building_type)
	
	# 通过faction_id从FactionManager获取faction
	faction = GlobalNodes.managers.FactionManager.get_faction(faction_id)

	# action_name
	action_name = "BuildingCreateAction: "  + " 在 " + colony.father_node.name + " 创建建筑 " + building_type


static func pre_validate(p_faction_id: int, p_building_type: String) -> Array:
	# 验证资源是否足够
	# 通过faction_id从FactionManager获取faction
	var target_faction = GlobalNodes.managers.FactionManager.get_faction(p_faction_id)
	if not target_faction:
		return [false, "faction未找到: " + str(p_faction_id)]
	
	# 获取faction的资源数据
	var faction_resources = target_faction.get_all_resources()
	
	# 通过building_type从TileJsonLoader获取building数据
	var target_building_data = TileJsonLoader.get_tile_by_type(p_building_type)
	if not target_building_data:
		return [false, "建筑类型未找到: " + p_building_type]

	# 解析building_type获取的building数据中的cost字段
	if not target_building_data.has("cost"):
		return [true, {}]  # 如果没有cost字段，视为不需要消耗资源

	var cost_data = target_building_data["cost"]
	
	# 使用MathTools比较资源
	var result = MathTools.compare_resources(faction_resources, cost_data)
	if not result[0]:
		return [false, "资源不足"]
	
	return result  # 返回bool值和剩余资源字典

func pre_execute():
	# 为faction的resource_productions减去所需资源
	
	var cost_data = building_data["cost"]
	# 通过ResourceManager减去预资源
	var result_array = [false]
	
	# 将cost_data转换为负数字典（用于扣除）
	var cost_dict_negative = {}
	for resource_type in cost_data:
		cost_dict_negative[resource_type] = -cost_data[resource_type]
	
	GlobalSignalBus.resource_production_modify_request.emit(faction_id, cost_dict_negative, result_array)
	
	# 获取建筑所需回合数
	var build_turns = building_data.get("turn_cost", 1)  # 默认1回合
	
	# 在colony中对应slot创建建筑以及剩余回合数
	colony.set_slot(slot_index, building_type, 0, build_turns)

	# 将建造中tile添加到colony的建筑层
	var constructing_tile_type = building_data.get("constructing_tile_type", "building_building")
	colony.add_tile(constructing_tile_type, coord, colony.colony_building_tiles, 0)

	# 设置剩余回合数
	turn_total = build_turns
	turn_left = build_turns

	# 缓存资源消耗数据
	resource_cost = cost_data


func execute() -> void:
	# 每执行一次，turn_left减1
	turn_left -= 1
	
	# 验证剩余回合数是否为0
	if turn_left > 0:
		# 不为0则set_slot更新剩余回合数，set_slot的tile_type为tile_data的constructing_tile_type（即建造中tile）
		var constructing_tile_type = building_data.get("constructing_tile_type", "building_building")
		colony.set_slot(slot_index, constructing_tile_type, 0, turn_left)
		colony.add_tile(constructing_tile_type, coord, colony.colony_building_tiles, 0)
	else:
		# 为0则完成建筑建造_finished()
		_finished()


func cancel() -> void:
	# 根据剩余回合数计算资源退还
	if turn_left == turn_total:
		# 如果剩余回合数等于总回合数，退还全部资源给faction的resource_productions
		var result_array = [false]
		GlobalSignalBus.resource_production_modify_request.emit(faction_id, resource_cost, result_array)
		
	else:
		# 根据剩余回合数和总回合数之比，退还部分资源给faction的resources
		var progress_ratio = float(turn_total - turn_left) / float(turn_total)
		var refund_ratio = 1.0 - progress_ratio  # 建设时间越久回收越少
		
		# 计算退还资源数量
		var refund_resources = {}
		for resource_type in resource_cost:
			var refund_amount = resource_cost[resource_type] * refund_ratio
			refund_resources[resource_type] = refund_amount
		
		# 退还资源到faction的实际资源
		var result_array = [false]
		GlobalSignalBus.resource_modify_request.emit(faction_id, refund_resources, result_array)
	
	# 清空槽位
	colony.clear_slot(slot_index)


func validate_once() -> Array:
	"""
	只执行一次的验证逻辑，结果会被缓存
	主要用于验证那些在Action生命周期中不会改变的条件
	"""
	# 如果已验证过，返回缓存结果
	if initial_validation_done:
		return initial_validation_result
	
	# 验证建筑层坐标是否已有建筑（只需检查一次）
	var building_tile = colony.get_tile(coord, colony.colony_building_tiles)
	if not building_tile.is_empty():
		initial_validation_result = [false, "坐标 " + str(coord) + " 已有建筑"]
		initial_validation_done = true
		return initial_validation_result
	
	# 验证通过
	initial_validation_result = [true, ""]
	initial_validation_done = true
	return initial_validation_result


func validate() -> Array:
	# 验证所有必要的对象引用
	if not building_data:
		return [false, "building_data未找到"]
	
	if not colony:
		return [false, "colony资源未找到"]
	
	if not faction:
		return [false, "faction资源未找到"]
	
	# 验证槽位索引是否有效
	if slot_index < 0 or slot_index >= colony.slot_array.size():
		return [false, "槽位索引无效: " + str(slot_index)]
	
	# 验证槽位是否为空
	var slot_data = colony.get_slot(slot_index)
	if not slot_data.is_empty():
		return [false, "槽位 " + str(slot_index) + " 已被占用"]
	
	# 验证资源是否足够（使用当前资源而不是预资源）
	if building_data.has("cost"):
		var cost_data = building_data["cost"]
		var faction_resources = faction.get_all_resources()
		var result = MathTools.compare_resources(faction_resources, cost_data)
		
		if not result[0]:
			return [false, "资源不足"]
	
	return [true, ""]

func _finished() -> void:
	# set_slot更新槽位数据为建造完成的建筑以及剩余回合数为0
	colony.set_slot(slot_index, building_type, 0, 0)
	
	# 将建筑添加到colony的建筑层
	colony.add_tile(building_type, coord, colony.colony_building_tiles, 0)

	# 更新Action状态为完成
	_update_state(ActionState.COMPLETED)
