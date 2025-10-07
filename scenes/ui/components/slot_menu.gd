extends Control

@export var slot_container:GridContainer
@export var menu_tag: String = ""

# 自定义信号，参数为slot和自身标记
signal slot_pressed_with_tag(index, menu_tag, slot_data)

var slot_scence = preload("res://scenes/ui/components/slot.tscn")
# 全局数组管理slot数据，按索引对应

var slot_data_array: Array = []
# 索引计数器，每次创建slot时递增
var slot_index_counter: int = 0

# SlotState常量（与slot.gd中的enum对应）
# 0 = EMPTY（空闲）, 1 = RESERVED（预占）, 2 = OCCUPIED（已占用）

func _ready() -> void:
	clear_all_slots()

# 创建slot
func create_slot(state: int = 0, texture: Texture2D = null, display_text: String = "", data = null) -> Control:
	var slot_instance = slot_scence.instantiate()
	slot_container.add_child(slot_instance)
	# 连接slot的信号，使用Callable.bind绑定索引
	slot_instance.component_pressed.connect(Callable(self, "_on_slot_pressed").bind(slot_index_counter))
	# 将数据添加到数组中
	slot_data_array.append(data)
	# 设置slot状态、纹理和显示文本
	slot_instance.set_slot(state, texture, display_text)
	# 递增索引计数器
	slot_index_counter += 1
	return slot_instance

# 清空所有slot
func clear_all_slots() -> void:
	# 清空slot_container的所有子节点
	for child in slot_container.get_children():
		child.queue_free()
	# 清空数组
	slot_data_array.clear()
	# 重置索引计数器
	slot_index_counter = 0

# slot被点击时的处理函数
func _on_slot_pressed(slot_state, index: int) -> void:
	# 检查索引是否有效
	if index >= 0 and index < slot_data_array.size():
		var data = slot_data_array[index]
		# 发送带有标记的信号，参数顺序：menu_tag, index, data, state
		slot_pressed_with_tag.emit(menu_tag, index, data, slot_state)
