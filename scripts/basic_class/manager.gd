extends Node
class_name Manager

func register() -> void:
	GlobalNodes.add_manager(self.name,self)
	print(self.name,"已初始化")

func _ready() -> void:
	register()
