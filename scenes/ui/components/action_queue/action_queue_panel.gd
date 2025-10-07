extends Control

# Action label场景的引用
var action_label_scene: PackedScene = preload("res://scenes/ui/components/action_queue/action_label.tscn")

# 节点引用
@export var action_list: VBoxContainer
@export var queue_status: Label
@export var clear_all_button: Button

func _ready():
	# 初始化显示
	_update_queue_display()
	
	GlobalSignalBus.action_queue_changed.connect(_on_queue_changed)

# 队列变化时更新显示
func _on_queue_changed():
	_update_queue_display()

# 更新队列显示
func _update_queue_display():
	# 清除所有现有的Action label
	_clear_action_labels()
	
	# 更新队列状态文本
	var queue_size = 0
	queue_size = GlobalNodes.managers.ActionManager.action_queues["main"].size()
	queue_status.text = "队列: %d 个Action" % queue_size
	
	# 为每个Action创建标签
	for i in range(queue_size):
		var action = GlobalNodes.managers.ActionManager.action_queues["main"][i]
		_create_action_label(action)

# 清除所有Action标签
func _clear_action_labels():
	for child in action_list.get_children():
		child.queue_free()

# 创建Action标签
func _create_action_label(action: Action):
	var label_instance = action_label_scene.instantiate()
	action_list.add_child(label_instance)
	
	# 设置Action标签的内容和行为
	label_instance.setup_action(action)
	
	# 连接删除信号
	label_instance.action_removed.connect(_on_action_removed)
	

# 当单个Action被移除时
func _on_action_removed(action: Action):
	GlobalNodes.managers.ActionManager.cancel_action(action)

# 清空全部按钮点击事件
func _on_clear_all_button_pressed():
	GlobalNodes.managers.ActionManager.clear_all_actions("main")

# 手动更新显示（供外部调用）
func refresh_display():
	_update_queue_display()
