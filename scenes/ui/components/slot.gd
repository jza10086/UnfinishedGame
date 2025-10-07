extends Control
signal component_pressed(slot_state: SlotState)

# 槽位状态枚举
enum SlotState {
	EMPTY,      # 空闲
	RESERVED,   # 预占
	OCCUPIED    # 已占用
}

# 导出节点引用
@export var icon_node : TextureRect
@export var button_node : Button
@export var label_node : Label

# 槽位状态
var slot_state: SlotState = SlotState.EMPTY

func _ready():
	"""初始化槽位状态"""
	_set_slot_state(SlotState.EMPTY)

func set_slot(state: SlotState, texture: Texture2D = null, display_text: String = ""):
	"""统一设置槽位的状态、纹理和显示文本"""
	_set_slot_state(state, display_text)
	if texture:
		_set_texture(texture)

func _set_slot_state(state: SlotState, display_text: String = ""):
	"""统一设置槽位状态"""
	slot_state = state
	
	match state:
		SlotState.EMPTY:
			modulate = Color(1, 1, 1, 1)  # 正常颜色
			label_node.text = "+"
		
		SlotState.RESERVED:
			modulate = Color(1.0, 0.8, 0.5, 0.6)  # 橙色半透明
			label_node.text = display_text
		
		SlotState.OCCUPIED:
			modulate = Color(1, 1, 1, 1)  # 正常颜色
			label_node.text = ""

func _on_button_pressed() -> void:
	# 发送当前槽位状态
	component_pressed.emit(slot_state)


func _set_texture(p_texture: Texture2D) -> void:
	icon_node.texture = p_texture
