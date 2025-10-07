extends UnitAction
class_name FleetCreateAction

# 舰队创建相关的参数
var fleet_name: String
var stellar_id: int
var stellar_position: Vector3
var faction_id: int

# 预留
var creator: Node = null

func _init(p_fleet_name: String, p_stellar_id: int, p_faction_id: int = -1) -> void:
	# 预留
	executer = creator

	fleet_name = p_fleet_name
	stellar_id = p_stellar_id
	faction_id = p_faction_id
	
	# 获取恒星系名称用于显示
	var stellar = GlobalNodes.managers.StellarManager.get_stellar_by_id(stellar_id)
	var stellar_name = stellar.name if stellar else "未知恒星系"
	action_name = "FleetCreateAction: "  + " 在 " + stellar_name + " 创建舰队 " + fleet_name + " (派系:" + str(faction_id) + ")"

func pre_execute() -> void:
	pass

func execute() -> void:
	# 创建舰队（只传递名称）
	var new_fleet = GlobalNodes.managers.FleetManager.create_fleet(fleet_name)
	
	# 在FleetCreateAction中处理所有设置
	if new_fleet:
		# 设置舰队位置
		new_fleet.position = stellar_position
		
		# 设置当前恒星系ID
		new_fleet.set_current_stellar_id(stellar_id)
		
		# 设置舰队所有者
		new_fleet.set_faction_owner(faction_id)
		
		# 通过信号通知资源系统
		GlobalSignalBus.ownership_transfer_requested.emit("fleet", new_fleet.fleet_id, -1, faction_id)
	
	_finished()

func validate() -> Array:
	# 检查舰队名称是否为空
	if fleet_name.is_empty():
		return [false, "舰队名称不能为空"]

	if faction_id == -1:
		return [false, "faction id无效"]

	# 通过get_stellar_by_id验证恒星系是否存在
	var stellar = GlobalNodes.managers.StellarManager.get_stellar_by_id(stellar_id)
	if not stellar:
		return [false, "目标恒星系不存在"]
	
	stellar_position = GlobalNodes.managers.StellarManager.get_stellar_position(stellar)

	return [true, ""]

func undo() -> void:
	pass

func removed() -> void:
	pass
