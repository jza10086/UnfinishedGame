extends Control

signal label_left_clicked

@export var name_label:RichTextLabel
@export var progress_label:RichTextLabel
@export var icon_rect:TextureRect
@export var describe_label:RichTextLabel
@export var tag_label:RichTextLabel
@export var left_click_area:Control

func set_tech_data(tech_type: StringName ,progress_value: float = 0.0) -> void:
	"""根据tech_type设置对应的标签和图标"""
	# 从TechJsonLoader获取科技数据
	var tech_data = TechJsonLoader.get_tech(tech_type)
	if tech_data.is_empty():
		push_error("TechLabel: 找不到科技数据: " + tech_type)
		return
	
	name_label.text = tech_data.get("name", "UNKNOWN_NAME")
	
	# 设置科技费用
	var cost = tech_data.get("cost")
	progress_label.text = MathTools.format_number(progress_value) + "/" + MathTools.format_number(cost)
	
	var icon_path = tech_data.get("icon_path", "")
	if icon_path != "":
		var texture = load(icon_path)
		if texture:
			icon_rect.texture = texture
		else:
			push_warning("TechLabel: 无法加载图标: " + icon_path)
	
	# 设置科技描述
	describe_label.text = tech_data.get("describe", "")
	
	# 设置科技标签
	var tags = tech_data.get("tags", [])
	#TODO 图形标签，TextTools
	tag_label.text = "未设置"

func _ready() -> void:
	left_click_area.left_clicked.connect(_on_label_left_clicked)

func _on_label_left_clicked()-> void:
	label_left_clicked.emit()
