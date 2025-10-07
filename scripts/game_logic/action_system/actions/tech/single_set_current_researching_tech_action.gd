extends Action
class_name SingleSetCurrentResearchingTechAction

var faction_id: int
var tech_type: StringName
var faction: FactionResource
var tech_data: Dictionary
var previous_tech_type: StringName  # 记录原来的科技类型，用于取消时还原

func _init(p_faction_id: int, p_tech_type: StringName) -> void:
	faction_id = p_faction_id
	tech_type = p_tech_type
	faction = GlobalNodes.managers.FactionManager.get_faction(p_faction_id)
	executer = faction
	action_name = "设置阵营当前研究科技" +  " -> " + tech_type
	
	# 在初始化时直接调用pre_validate进行验证
	var validation_result = pre_validate(p_faction_id, p_tech_type)
	if not validation_result[0]:
		push_error("SingleSetCurrentResearchingTechAction: 验证失败 - " + validation_result[1])
		return
	
	# 记录当前正在研究的科技，以便取消时还原
	previous_tech_type = faction.current_researching_tech

func validate_once() -> Array:
	return [true, ""]

func validate() -> Array:
	# validate保留为空实现，实际验证在pre_validate中
	return [true, ""]

func pre_execute():
	"""执行前的准备工作 - 即时版本直接在这里执行"""
	# 获取同一个faction的所有SingleSetCurrentResearchingTechAction
	var existing_research_actions = GlobalNodes.managers.ActionManager.get_actions(faction, "SingleSetCurrentResearchingTechAction")
	
	# 移除现有的SingleSetCurrentResearchingTechAction
	for action in existing_research_actions:
		if action != self:
			print("移除现有的SingleSetCurrentResearchingTechAction，确保只有一个活动的研究操作")
			GlobalNodes.managers.ActionManager.remove_action(action)
	
	# 即时版本：直接在pre_execute中执行设置
	if not GlobalNodes.managers.TechManager.set_current_researching_tech(faction, tech_type):
		push_error("设置当前研究科技失败")
		return
	
	print("SingleSetCurrentResearchingTechAction: 已设置阵营 " + str(faction_id) + " 的当前研究科技为 " + tech_type)

func execute():
	# 即时版本：execute直接完成
	_finished()

func cancel() -> void:
	# 还原到之前的科技类型
	GlobalNodes.managers.TechManager.set_current_researching_tech(faction, previous_tech_type)
	print("SingleSetCurrentResearchingTechAction: 已取消，还原到之前的科技: " + previous_tech_type)

static func pre_validate(p_faction_id: int, p_tech_type: StringName) -> Array:
	# 获取faction
	var check_faction = GlobalNodes.managers.FactionManager.get_faction(p_faction_id)
	if not check_faction:
		return [false, "找不到指定阵营 ID: " + str(p_faction_id)]

	# 检查科技数据
	var check_tech_data = TechJsonLoader.get_tech(p_tech_type)
	if check_tech_data.is_empty():
		return [false, "找不到科技数据: " + p_tech_type]

	# 检查科技是否在selectable_techs或是researching_progress中
	if not (check_faction.selectable_techs.has(p_tech_type) or check_faction.researching_progress.has(p_tech_type)):
		return [false, "科技 " + p_tech_type + " 不在阵营 " + str(p_faction_id) + " 的 selectable_techs 或 researching_progress 中"]

	return [true, ""]
