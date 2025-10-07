class_name Unit
extends Area3D

signal selected(unit: Unit, event: InputEvent)


var unit_type: GlobalEnum.UnitType


# 预览模型显示控制（由子类重写具体节点引用）
var is_mouse_over: bool = false
var camera_height_threshold: float = 50.0
var preview_model: Node3D = null
var highlight_model: Node3D = null

# 选中状态控制
var is_selected: bool = false

## 变更标记 - 标记数据是否已变更
var is_changed: bool = false


# 资源管理
var bonus_resource: BonusResource

func _init() -> void:
	# 初始化资源管理器
	bonus_resource = BonusResource.new()

func _ready():

	
	# 尝试获取预览模型节点
	preview_model = get_node_or_null("PreviewModel")
	highlight_model = get_node_or_null("HighlightModel")
	
	# 连接鼠标进入和离开信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 连接输入事件信号
	input_event.connect(_on_input_event)
	
	# 默认隐藏预览模型和高亮模型
	if preview_model:
		preview_model.visible = false
	if highlight_model:
		highlight_model.visible = false
	
	# 初始化选中状态
	is_selected = false

# 鼠标进入区域时的回调
func _on_mouse_entered():
	is_mouse_over = true
	update_preview_model_visibility()

# 鼠标离开区域时的回调
func _on_mouse_exited():
	is_mouse_over = false
	update_preview_model_visibility()

# 更新预览模型和高亮模型的显示状态
func update_preview_model_visibility():
	# 获取相机位置
	var camera = GlobalNodes.managers.CameraManager.get_camera()
	var camera_y = camera.global_position.y

	# 判断是否应该显示预览模型
	var should_show_preview = is_mouse_over and camera_y >= camera_height_threshold
	
	# 更新预览模型
	if preview_model:
		preview_model.visible = should_show_preview
	
	# 判断是否应该显示高亮模型（选中状态下且相机高度满足条件）
	var should_show_highlight = is_selected and camera_y >= camera_height_threshold
	
	# 更新高亮模型
	if highlight_model:
		highlight_model.visible = should_show_highlight

# 更新精灵缩放（由子类重写具体实现）
func update_sprite_scale():
	# 基类提供默认空实现，子类根据需要重写
	pass

# 设置高亮模型的可见性
func set_highlight_visible(should_show: bool):
	is_selected = should_show
	# 立即更新显示状态
	update_preview_model_visibility()

func _process(_delta):
	# 检查相机高度并更新预览模型显示状态
	update_sprite_scale()
	update_preview_model_visibility()

# 处理输入事件的回调（由子类重写具体实现）
func _on_input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed():
		emit_signal("selected", self,event)  # 发出被选中信号
		get_viewport().set_input_as_handled() # 消费掉这个事件，防止它继续传播

#region 资源管理接口
# 添加资源加成
func add_resource_bonus(resource_type, info: String, bonus_type: BonusResource.BonusType, amount: float) -> int:
	"""
	为单位添加资源加成
	- resource_type: 资源类型 (GlobalEnum.ResourceType或是StringName)
	- info: 加成来源信息 (String)
	- bonus_type: 加成类型 (BonusResource.BonusType)
	- amount: 加成数值
	"""
	var id = bonus_resource.add_bonus(resource_type, info, bonus_type, amount)
	is_changed = true  # 标记数据已变更
	return id  # 返回加成的唯一ID，方便后续移除

# 移除资源加成
func remove_resource_bonus(id: int):
	"""
	移除指定资源类型和来源的加成
	- resource_type: 资源类型 (GlobalEnum.ResourceType)
	- info: 加成来源信息 (String)
	"""
	bonus_resource.remove_bonus(id)
	is_changed = true  # 标记数据已变更


# 设置基础资源（由子类重写具体实现）
func set_basic_bonus(type_data: Dictionary):
	"""
	根据type_data设置基础资源（由子类重写具体实现）
	- type_data: 包含basic_resources的数据字典
	"""
	if type_data.has("basic_resources"):
		for resource_type in type_data["basic_resources"].keys():
			var resource_amount = type_data["basic_resources"][resource_type]
			add_resource_bonus(resource_type, "基础值", BonusResource.BonusType.BASIC, resource_amount)

# 获取资源加成
func get_bonus_resource() -> BonusResource:
	"""获取BonusResource实例"""
	return bonus_resource
#endregion
