extends Sprite2D

func _ready() -> void:
	hide()


func _process(_delta: float) -> void:
	# get_global_mouse_position() 获取鼠标在游戏世界中的全局坐标
	# 将自身的全局坐标设置为鼠标的全局坐标，实现跟随
	self.global_position = get_global_mouse_position() + Vector2(0,-35)
