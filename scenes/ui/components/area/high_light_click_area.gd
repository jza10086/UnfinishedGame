extends Control
class_name HighLightClickArea

signal left_clicked

@export var target_node: Control


var original_modulate: Color # 原始颜色
var highlight_color: Color = Color(1.35, 1.35, 1.35)  # 鼠标悬停时的高亮颜色
var darklight_color: Color = Color(0.65, 0.65, 0.65)  # 鼠标按下时的暗色
var is_pressed: bool = false
var mouse_inside: bool = false

func _ready():
	# 连接鼠标事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	original_modulate = target_node.modulate
	
func _on_mouse_entered():
	mouse_inside = true
	if is_pressed:
		target_node.modulate = darklight_color
	else:
		target_node.modulate = highlight_color

func _on_mouse_exited():
	mouse_inside = false
	target_node.modulate = original_modulate

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressed = true
			target_node.modulate = darklight_color
		else:
			is_pressed = false
			_on_left_clicked()
			if mouse_inside:
				target_node.modulate = highlight_color
			else:
				target_node.modulate = original_modulate

func _on_left_clicked() -> void:
	left_clicked.emit()
