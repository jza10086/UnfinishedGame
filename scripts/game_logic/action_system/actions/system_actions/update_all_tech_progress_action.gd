extends Action
class_name UpdateAllTechProgressAction

func validate_once() -> Array:
	"""一次性验证逻辑，对于系统action通常直接通过"""
	return [true, ""]

func validate() -> Array:
	"""验证Action是否可以执行"""
	return [true, ""]

func pre_execute():
	"""执行前的准备工作"""
	pass

func execute():
	# 获取所有faction ID
	var all_faction_ids = GlobalNodes.managers.FactionManager.get_all_faction_ids()
	
	# 遍历所有faction，跳过System faction (ID: 1000)
	for faction_id in all_faction_ids:
		if faction_id == 1000:  # 跳过System faction
			continue
			
		var current_faction = GlobalNodes.managers.FactionManager.get_faction(faction_id)
		# 更新科技研究进度
		GlobalNodes.managers.TechManager.update_researching_progress(current_faction)
		# 更新可研究科技列表
		GlobalNodes.managers.TechManager.update_available_techs(current_faction)
		# 更新可选择科技列表
		GlobalNodes.managers.TechManager.update_selectable_techs(current_faction)

	print("SystemAction: 已更新所有faction的科技进度")
	_finished()
