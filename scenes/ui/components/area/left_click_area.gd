extends Control
class_name LeftClickArea

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_on_left_click()

func _on_left_click() -> void:
	print("检测到左键点击")
