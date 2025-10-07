extends Action
class_name SetCurrentResearchingTechAction

var faction_id: int
var tech_type: StringName
var faction: FactionResource
var tech_data: Dictionary

func _init(p_faction_id: int, p_tech_type: StringName) -> void:
	faction_id = p_faction_id
	tech_type = p_tech_type
	faction = GlobalNodes.managers.FactionManager.get_faction(p_faction_id)
	executer = faction
	action_name = "设置阵营当前研究科技" +  " -> " + tech_type

func validate_once() -> Array:

	return [true, ""]

func validate() -> Array:
	if not faction:
		return [false, "找不到指定阵营 ID: " + str(faction_id)]

	tech_data = TechJsonLoader.get_tech(tech_type)
	if tech_data.is_empty():
		return [false, "找不到科技数据: " + tech_type]

	# 检查科技是否在selectable_techs或是researching_progress中
	if not (faction.selectable_techs.has(tech_type) or faction.researching_progress.has(tech_type)):
		return [false, "科技 " + tech_type + " 不在阵营 " + str(faction_id) + " 的 selectable_techs 或 researching_progress 中"]

	return [true, ""]

func pre_execute():
	"""执行前的准备工作"""
	# 获取同一个faction的所有SetCurrentResearchingTechAction
	var existing_research_actions = GlobalNodes.managers.ActionManager.get_actions(faction, "SetCurrentResearchingTechAction")
	
	# 移除现有的SetCurrentResearchingTechAction
	if existing_research_actions.size() > 0:
		print("移除现有的SetCurrentResearchingTechAction，确保只有一个活动的研究操作")
		GlobalNodes.managers.ActionManager.remove_action(existing_research_actions[0])

func execute():

	# 设置当前研究的科技
	if not GlobalNodes.managers.TechManager.set_current_researching_tech(faction, tech_type):
		push_error("设置当前研究科技失败")
		return

	print("SystemAction: 已设置阵营 " + str(faction_id) + " 的当前研究科技为 " + tech_type)
	_finished()

