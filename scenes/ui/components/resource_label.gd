extends HBoxContainer

@export var icon: TextureRect
@export var label: RichTextLabel 
@export var resource_key: GlobalEnum.ResourceType = GlobalEnum.ResourceType.ENERGY  # 用于标识资源类型的键名
@export var info_area: InfoArea 


# 设置图标
func set_icon(texture: Texture2D):
	icon.texture = texture

# 设置文本
func set_label(text: String):
	label.text = text

# 设置资源信息（接受简化的字典数据）
func set_info(resource_data: Dictionary):
	"""
	设置资源标签信息
	参数: resource_data = {"value": 数值, "sources": 来源信息字典}
	"""
	if resource_data.has("value"):
		set_label(str(resource_data["value"]))
	
	if resource_data.has("sources") and info_area:
		var sources_dict = resource_data["sources"]
		if sources_dict.size() > 0:
			var info_text = "资源来源信息:\n"
			for source_name in sources_dict:
				info_text += "- %s: %s\n" % [source_name, sources_dict[source_name]]
			info_area.set_text(info_text)
			info_area.set_enabled(true)
		else:
			info_area.set_enabled(false)
