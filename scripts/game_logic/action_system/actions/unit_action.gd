extends Action
class_name UnitAction



func _init(_unit: Unit) -> void:
	action_name = "UnitAction基类"

func _on_unit_executed(_unit: Node) -> void:
	pass

# Action虚函数模板
func pre_execute():
	pass

func execute():
	pass

func validate_once() -> Array: 
	return [true, ""]

func validate() -> Array:
	return [true, ""]

