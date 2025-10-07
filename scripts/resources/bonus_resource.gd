## 通用加成资源管理器
## 用于管理任何对象的多层加成系统，支持基础值、奖励值、乘数和最终计算值
## 继承自Resource类，可作为资源文件保存和加载
class_name BonusResource
extends Resource

## 加成类型枚举
enum BonusType {
	BASIC,      ## 基础值
	BONUS,      ## 奖励值（加法）
	MULTIPLIER ## 乘数值（乘法）
}

## 加成条目类
class BonusEntry:
	var bonus_type: BonusType
	var data_type: Variant
	var value: Variant
	var info: String

	func _init(p_bonus_type: BonusType, p_data_type: Variant, p_value: Variant, p_info: String):
		self.bonus_type = p_bonus_type
		self.data_type = p_data_type
		self.value = p_value
		self.info = p_info

## 数据存储结构: {id: BonusEntry}
## id: 唯一标识符（int）

# 非FINAL类型加成条目存储
var data_storage: Dictionary[int, BonusEntry] = {}
# FINAL类型结果缓存，key为data_type，value为最终计算值
var final_data: Dictionary[Variant, float] = {}



## 变更标记 - 标记数据是否已变更
var is_changed: bool = true

## 添加加成
## @param data_type: 数据类型（Variant）
## @param info: 来源标识
## @param bonus_type: 加成类型
## @param value: 加成值（支持任意数据类型）
func add_bonus(data_type: Variant, info: String, bonus_type: BonusType, value: Variant) -> int:
	
	var id = GlobalNodes.managers.BonusManager.generate_id()
	
	# 使用BonusEntry类
	data_storage[id] = BonusEntry.new(bonus_type, data_type, value, info)
	
	is_changed = true

	return id  # 返回唯一ID，方便后续移除

## 删除加成
## @param id: 唯一标识符（int）
func remove_bonus(id: int):
	if data_storage.has(id):
		data_storage.erase(id)
		is_changed = true

## 按data_type获取最终值
## @param data_type: 数据类型（Variant）
## @return: 最终计算值，如果data_type不存在返回0.0
func get_result(data_type: Variant) -> float:
		if is_changed:
			_calculate()
		return final_data.get(data_type, 0.0)

## 按data_type获取来源信息字典
## @param data_type: 数据类型（Variant）
## @return: Dictionary {info: formatted_value_string}
func get_sources(data_type: Variant) -> Dictionary:
	var result = {}
	
	for id in data_storage:
		var bonus_entry = data_storage[id]
		if bonus_entry.data_type == data_type:
			var info = bonus_entry.info
			var bonus_type = bonus_entry.bonus_type
			var value = bonus_entry.value
			
			# 根据BonusType格式化值
			var formatted_value: String
			match bonus_type:
				BonusType.BASIC:
					# BASIC：直接返回值，使用基础值颜色
					formatted_value = TextTools.BBcode_basic(str(value))
				BonusType.BONUS:
					# BONUS：正数加+，负数保持原样，根据正负使用不同颜色
					var value_str: String
					if value >= 0:
						value_str = "+" + str(value)
						formatted_value = TextTools.BBcode_bonus(value_str)
					else:
						value_str = str(value)
						formatted_value = TextTools.BBcode_warning(value_str)
				BonusType.MULTIPLIER:
					# MULTIPLIER：转换为一位小数的百分数，正数加+，根据正负使用不同颜色
					var percentage = value * 100.0
					var value_str: String
					if value >= 0:
						value_str = "+%.1f%%" % percentage
						formatted_value = TextTools.BBcode_bonus(value_str)
					else:
						value_str = "%.1f%%" % percentage
						formatted_value = TextTools.BBcode_warning(value_str)
				_:
					# 其他类型直接返回值
					formatted_value = str(value)
			
			result[info] = formatted_value
	
	return result.duplicate(true)  # 深度复制，确保完全只读

## 获取所有数据类型
## @return: Array 包含所有唯一的data_type
func get_data_types() -> Array:
	var data_types = []
	
	for id in data_storage:
		var bonus_entry = data_storage[id]
		var data_type = bonus_entry.data_type
		if not data_types.has(data_type):
			data_types.append(data_type)
	
	return data_types

## 清空所有数据
func clear():
		data_storage.clear()
		final_data.clear()
		is_changed = true

## 执行计算公式，更新最终值
func _calculate():
	if not is_changed:
		return
	
	# 清空旧的FINAL数据
	_clear_final_data()
	
	# 单次遍历：同时收集所有data_type的加成数据
	var type_calculations = {}  # {data_type: {basic: float, bonus: float, multiplier: float}}
	
	for id in data_storage:
		var bonus_entry = data_storage[id]
		var data_type = bonus_entry.data_type
		var bonus_type = bonus_entry.bonus_type
		var value = bonus_entry.value
		
		# 初始化data_type的计算数据
		if not type_calculations.has(data_type):
			type_calculations[data_type] = {"basic": 0.0, "bonus": 0.0, "multiplier": 0.0}
		
		# 根据类型累加值
		if value is float or value is int:
			match bonus_type:
				BonusType.BASIC:
					type_calculations[data_type]["basic"] += value
				BonusType.BONUS:
					type_calculations[data_type]["bonus"] += value
				BonusType.MULTIPLIER:
					type_calculations[data_type]["multiplier"] += value
	
	# 计算最终值并存储
	for data_type in type_calculations:
		var calc_data = type_calculations[data_type]
		var final_value = (calc_data["basic"] + calc_data["bonus"]) * (calc_data["multiplier"] + 1.0)
		
		# 存储最终值到final_storage中，直接使用data_type作为key
		final_data[data_type] = final_value
	
	is_changed = false

## 清除所有FINAL类型的数据
func _clear_final_data():
		final_data.clear()
