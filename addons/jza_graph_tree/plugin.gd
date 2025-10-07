@tool
extends EditorPlugin


# 我们将按钮保存在一个变量中，以便在退出时可以访问并移除它。
var custom_button: Button


func _enter_tree() -> void:
	# 1. 创建一个新的 Button 节点
	custom_button = Button.new()
	
	# 2. 设置按钮的属性
	custom_button.tooltip_text = "生成星系"
	
	custom_button.icon = preload("res://icon.svg")
	custom_button.expand_icon = true
	custom_button.custom_minimum_size = Vector2(32,32)
	custom_button.tooltip_text = "点击这里生成一个新的随机星系用于测试。"
	
	# 3. 连接按钮的 "pressed" 信号到一个回调函数
	custom_button.pressed.connect(_on_button_pressed)

	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, custom_button)


func _exit_tree() -> void:
	# 在插件禁用时，清理我们添加的所有东西
	# 确保 custom_button 仍然有效
	if is_instance_valid(custom_button):
		# 从工具栏移除按钮
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, custom_button)
		# 彻底销毁按钮节点，防止内存泄漏
		custom_button.queue_free()


# 按钮被点击时会调用的函数
func _on_button_pressed() -> void:
	print("正在生成新的星系...")
