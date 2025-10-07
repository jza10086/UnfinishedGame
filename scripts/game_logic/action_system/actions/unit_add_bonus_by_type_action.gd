extends UnitAddBonusAction
class_name UnitAddBonusByTypeAction

## UnitAddBonusByTypeAction - 通过bonus_type从JSON配置添加单位加成
## 
## 这个类继承自UnitAddBonusAction，提供了通过bonus_type字符串来自动加载
## JSON配置的便捷方式，而不需要手动指定所有参数。
##
## 使用示例：
## var action = UnitAddBonusByTypeAction.new(1000001, "tech_bonus_energy")
## action.validate() # 验证action是否有效
## action.execute() # 执行添加加成的操作

func _init(p_unit_id: int, p_bonus_type: String) -> void:
	# 从JSON加载器获取bonus配置
	var bonus_config = BonusJsonLoader.get_bonus_type(p_bonus_type)
	
	if bonus_config.is_empty():
		push_error("UnitAddBonusByTypeAction: 找不到bonus类型: " + p_bonus_type)
		return
	
	# 从配置中提取参数并直接传递给父类构造函数
	super._init(
		p_unit_id,
		bonus_config.get("resources", {}),
		bonus_config.get("describe", p_bonus_type),
		bonus_config.get("bonus_type", BonusResource.BonusType.BASIC),
		bonus_config.get("stackable", false),
		bonus_config.get("duration_turns", -1)
	)
	
	# 更新action名称
	action_name = "UnitAddBonusByTypeAction"
