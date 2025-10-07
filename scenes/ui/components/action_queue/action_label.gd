extends Control
class_name ActionLabel

# 信号
signal action_removed(action: Action)

# 引用
var action: Action

# 节点引用
@export var label: RichTextLabel
@export var remove_button: Button

func _ready():
	remove_button.pressed.connect(_on_remove_button_pressed)

# 设置Action信息
func setup_action(new_action: Action):
	action = new_action
	label.text = action.get_action_name()

# 移除按钮点击事件
func _on_remove_button_pressed():
	action_removed.emit(action)
