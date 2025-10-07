extends Manager
class_name trigger

#region rules

func _check_current_resource(resource: GlobalEnum.ResourceType, amount: float, operator: StringName) -> bool:
	match operator:
		"==":
			return GlobalNodes.get_manager("ResourceManager").get_resource_amount(resource) == amount
		"!=":
			return GlobalNodes.get_manager("ResourceManager").get_resource_amount(resource) != amount
		">":
			return GlobalNodes.get_manager("ResourceManager").get_resource_amount(resource) > amount
		"<":
			return GlobalNodes.get_manager("ResourceManager").get_resource_amount(resource) < amount
		">=":
			return GlobalNodes.get_manager("ResourceManager").get_resource_amount(resource) >= amount
		"<=":
			return GlobalNodes.get_manager("ResourceManager").get_resource_amount(resource) <= amount
		_:
			push_error("TriggerManager: 不支持的比较操作符: " + operator)
			return false

func test_trigger(p_text):
	print(p_text)

#endregion
