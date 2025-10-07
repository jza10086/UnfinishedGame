extends Action
class_name DiplomacyRelationshipAction

# 外交关系设置相关的参数
var faction_a_id: int
var faction_b_id: int
var new_relation: GlobalEnum.DiplomaticRelation

# 用于撤销操作的原始关系状态
var original_relation_a_to_b: GlobalEnum.DiplomaticRelation
var original_relation_b_to_a: GlobalEnum.DiplomaticRelation

# 静态预验证方法 - 轻量级检查，不创建实例
static func can_execute(p_faction_a_id: int, p_faction_b_id: int, p_new_relation: GlobalEnum.DiplomaticRelation) -> Dictionary:
	# 检查FactionManager是否可用
	if not GlobalNodes.FactionManager:
		return {"valid": false, "error_message": "FactionManager不可用"}
	
	# 检查阵营A是否存在
	var faction_a = GlobalNodes.FactionManager.get_faction(p_faction_a_id)
	if not faction_a:
		return {"valid": false, "error_message": "阵营A不存在，ID: " + str(p_faction_a_id)}
	
	# 检查阵营B是否存在
	var faction_b = GlobalNodes.FactionManager.get_faction(p_faction_b_id)
	if not faction_b:
		return {"valid": false, "error_message": "阵营B不存在，ID: " + str(p_faction_b_id)}
	
	# 检查是否尝试对自己设置外交关系
	if p_faction_a_id == p_faction_b_id:
		return {"valid": false, "error_message": "不能对自己设置外交关系"}
	
	# 检查新关系是否有效
	if p_new_relation < GlobalEnum.DiplomaticRelation.UNKNOWN or p_new_relation > GlobalEnum.DiplomaticRelation.ALLIED:
		return {"valid": false, "error_message": "无效的外交关系类型: " + str(p_new_relation)}
	
	# 检查当前关系是否已经是目标关系
	var current_relation = GlobalNodes.FactionManager.get_diplomatic_relation(p_faction_a_id, p_faction_b_id)
	if current_relation == p_new_relation:
		return {"valid": false, "error_message": "与 %s 已经是相同关系" % [faction_b.display_name]}
	
	return {"valid": true, "error_message": ""}

func _init(p_faction_a_id: int, p_faction_b_id: int, p_new_relation: GlobalEnum.DiplomaticRelation) -> void:
	faction_a_id = p_faction_a_id
	faction_b_id = p_faction_b_id
	new_relation = p_new_relation
	
	# 获取阵营名称用于显示
	var faction_a = GlobalNodes.FactionManager.get_faction(faction_a_id)
	var faction_b = GlobalNodes.FactionManager.get_faction(faction_b_id)
	var faction_a_name = faction_a.display_name if faction_a else "未知阵营"
	var faction_b_name = faction_b.display_name if faction_b else "未知阵营"
	
	action_name = "外交关系: %s -> %s (关系类型: %d)" % [faction_a_name, faction_b_name, new_relation]

func pre_execute() -> void:
	# 保存原始关系状态以备撤销使用
	original_relation_a_to_b = GlobalNodes.FactionManager.get_diplomatic_relation(faction_a_id, faction_b_id)
	original_relation_b_to_a = GlobalNodes.FactionManager.get_diplomatic_relation(faction_b_id, faction_a_id)

func execute() -> void:
	# 设置外交关系
	var success = GlobalNodes.FactionManager.set_diplomatic_relation(faction_a_id, faction_b_id, new_relation)
	
	if success:
		_finished()
	else:
		_update_state(ActionState.FAILED, "无法设置外交关系：可能由于系统限制或参数错误")

func validate() -> bool:
	# 检查FactionManager是否可用
	if not GlobalNodes.FactionManager:
		error_message = "FactionManager不可用"
		return false
	
	# 检查阵营A是否存在
	var faction_a = GlobalNodes.FactionManager.get_faction(faction_a_id)
	if not faction_a:
		error_message = "阵营A不存在，ID: " + str(faction_a_id)
		return false
	
	# 检查阵营B是否存在
	var faction_b = GlobalNodes.FactionManager.get_faction(faction_b_id)
	if not faction_b:
		error_message = "阵营B不存在，ID: " + str(faction_b_id)
		return false
	
	# 检查是否尝试对自己设置外交关系
	if faction_a_id == faction_b_id:
		error_message = "不能对自己设置外交关系"
		return false
	
	# 检查新关系是否有效
	if new_relation < GlobalEnum.DiplomaticRelation.UNKNOWN or new_relation > GlobalEnum.DiplomaticRelation.ALLIED:
		error_message = "无效的外交关系类型: " + str(new_relation)
		return false
	
	return true

func undo() -> void:
	# 恢复原始关系状态
	if GlobalNodes.FactionManager:
		# 注意：这里需要分别恢复双方的关系，因为原始状态可能不对称
		var faction_a = GlobalNodes.FactionManager.get_faction(faction_a_id)
		var faction_b = GlobalNodes.FactionManager.get_faction(faction_b_id)
		
		if faction_a and faction_b:
			faction_a.diplomatic_relations[faction_b_id] = original_relation_a_to_b
			faction_b.diplomatic_relations[faction_a_id] = original_relation_b_to_a
			print("撤销外交关系设置：%s 与 %s 的关系已恢复" % [faction_a.display_name, faction_b.display_name])

func validate_once() -> Array: 
	return [true, ""]


func _finished():
	pass
