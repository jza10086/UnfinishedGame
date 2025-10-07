extends Node
class_name ZeroTurnAction

static func init_zero_turn() -> void:
	# 初始化零回合
	GlobalNodes.managers.PlanetManager.trigger_planet_update()
	GlobalNodes.managers.StellarManager.trigger_stellar_update()
	# var update_action = UpdateAllTechProgressAction.new()
	# GlobalNodes.managers.ActionManager.add_action(update_action,"init")
	# GlobalNodes.managers.ActionManager.execute_queue("init")
	var all_faction_ids = GlobalNodes.managers.FactionManager.get_all_faction_ids()
	# 遍历所有faction，跳过System faction (ID: 1000)
	for faction_id in all_faction_ids:
		if faction_id == 1000:  # 跳过System faction
			continue
			
		var current_faction = GlobalNodes.managers.FactionManager.get_faction(faction_id)
		# 更新可研究科技列表
		GlobalNodes.managers.TechManager.update_available_techs(current_faction)
		# 更新可选择科技列表
		GlobalNodes.managers.TechManager.update_selectable_techs(current_faction)
