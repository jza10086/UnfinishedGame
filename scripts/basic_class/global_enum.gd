class_name GlobalEnum

# 外交关系类型
enum DiplomaticRelation {
	UNKNOWN,    # 未知 (默认值)
	HOSTILE,    # 敌对
	NEUTRAL,    # 中立
	FRIENDLY,   # 友好
	ALLIED      # 盟友
}

# 资源类型
enum ResourceType {
	ENERGY = 100,
	MINE = 101,
	FOOD = 102,
	TECH = 103
}

# 资源字典结构
# 格式：{GlobalEnum.ResourceType: amount, ...}


# 单位类型
enum UnitType {
	UNKNOWN,
	FLEET,
	PLANET,
	STELLAR
}


# 科技类型
enum TechCategory {
	GENERAL,
	CORE
}