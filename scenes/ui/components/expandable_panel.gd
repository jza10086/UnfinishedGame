extends VBoxContainer
class_name ExpandablePanel

## 可展开/收缩的面板组件
## 点击标题可以展开或收缩内容区域

@export var panel_title: String = "面板" : set = set_panel_title
@export var start_expanded: bool = false
@export var animation_duration: float = 0.3

@onready var toggle_button: Button = $Header/Panel/ToggleButton
@onready var arrow_icon: Label = $Header/ArrowIcon
@onready var content: VBoxContainer = $Content

var is_expanded: bool = true
var tween: Tween

signal panel_toggled(expanded: bool)

func _ready():
	set_panel_title(panel_title)
	if not start_expanded:
		toggle_panel()

func set_panel_title(value: String):
	panel_title = value
	if toggle_button:
		toggle_button.text = panel_title

func toggle_panel():
	is_expanded = !is_expanded
	panel_toggled.emit(is_expanded)
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	if is_expanded:
		# 展开
		arrow_icon.text = "▼"
		content.modulate.a = 0.0
		content.visible = true
		tween.parallel().tween_property(content, "modulate:a", 1.0, animation_duration)
		tween.parallel().tween_property(content, "scale:y", 1.0, animation_duration)
	else:
		# 收缩
		arrow_icon.text = "▶"
		tween.parallel().tween_property(content, "modulate:a", 0.0, animation_duration)
		tween.parallel().tween_property(content, "scale:y", 0.0, animation_duration)
		tween.tween_callback(func(): content.visible = false)

func _on_toggle_button_pressed():
	toggle_panel()

## 添加内容到面板中
func add_content(node: Control):
	var content_container = $Content/Panel/MarginContainer/ContentContainer
	content_container.add_child(node)

## 清空面板内容
func clear_content():
	var content_container = $Content/Panel/MarginContainer/ContentContainer
	for child in content_container.get_children():
		child.queue_free()
