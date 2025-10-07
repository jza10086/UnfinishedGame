extends Node

enum TurnPhase {
	Action,  # 行动阶段
	FleetMove,  # 舰队移动阶段
	Animation,  # 动画阶段
}

@warning_ignore("unused_signal")
signal turn_phase_completed()
@warning_ignore("unused_signal")
signal turn_phase(phase:TurnPhase)

# 资源系统信号 - 简化版
# 资源修改请求信号：faction_id, resource_dict(资源类型:数量), result_array[bool]
@warning_ignore("unused_signal")
signal resource_modify_request(faction_id: int, resource_dict: Dictionary, result_array: Array)

# 资源查询请求信号：faction_id, resource_dict(资源类型:数量), result_array[bool]
@warning_ignore("unused_signal")
signal resource_query_request(faction_id: int, resource_dict: Dictionary, result_array: Array)

# 资源更新信号
@warning_ignore("unused_signal")
signal resource_updated(faction_id: int, resource_dict: Dictionary)

# 预资源更新信号
@warning_ignore("unused_signal")
signal resource_production_updated(faction_id: int, resource_production_dict: Dictionary)

# 预资源修改请求信号：faction_id, resource_dict(资源类型:数量), result_array[bool]
@warning_ignore("unused_signal")
signal resource_production_modify_request(faction_id: int, resource_dict: Dictionary, result_array: Array)

# 预资源比对请求信号：faction_id, resource_dict(额外资源字典), result_array[bool]
@warning_ignore("unused_signal")
signal resource_production_compare_request(faction_id: int, additional_resources: Dictionary, result_array: Array)

# 资源更新请求信号
@warning_ignore("unused_signal")
signal resource_update_requested(faction_id: int)

# 玩家选择单位信号
@warning_ignore("unused_signal")
signal unit_selected(unit: Node)

# 玩家取消选择信号
@warning_ignore("unused_signal")
signal unit_deselected()

# 恒星系初始化请求信号
@warning_ignore("unused_signal")
signal stellar_init_requested(stellar: Node)

# 行星创建请求信号
@warning_ignore("unused_signal")
signal planet_create_requested(stellar: Node, orbit_id: int, planet_type: String, angle_coefficient: float)

# 所有权管理信号
@warning_ignore("unused_signal")
signal ownership_transfer_requested(object_type: String, object_id: int, old_faction_id: int, new_faction_id: int)

# Bonus更新信号 - 统一管理所有加成资源的计算
@warning_ignore("unused_signal")
signal bonus_update()

@warning_ignore("unused_signal")
signal planet_update()

@warning_ignore("unused_signal")
signal planet_update_completed()

@warning_ignore("unused_signal")
signal all_planet_update_completed()

@warning_ignore("unused_signal")
signal stellar_update()

@warning_ignore("unused_signal")
signal stellar_update_completed()

@warning_ignore("unused_signal")
signal all_stellar_update_completed()

@warning_ignore("unused_signal")
signal turn_finished()  # 回合结束信号




# Action队列变化信号
@warning_ignore("unused_signal")
signal action_queue_changed()

@warning_ignore("unused_signal")
signal init_action_finished() # 初始化action信号