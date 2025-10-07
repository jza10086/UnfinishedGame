extends Control

@export var label_container:VBoxContainer
@export var tag_container:HBoxContainer
@export var name_label:Label
@export var cost_container:VBoxContainer
@export var texture_rect:TextureRect

func _ready() -> void:
	add_label("[color=red]T[/color][color=green]e[/color][color=blue]s[/color][color=white]t[/color]")

# 设置名称标签
func set_name_label(text: String) -> void:
	if name_label:
		name_label.text = text

# 设置费用标签
func add_cost_label(text: String) -> RichTextLabel:
	if not cost_container:
		return null
	
	var rich_label = RichTextLabel.new()
	rich_label.bbcode_enabled = true
	rich_label.text = text
	rich_label.fit_content = true
	rich_label.scroll_active = false
	rich_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rich_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rich_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	cost_container.add_child(rich_label)
	return rich_label

# 设置纹理图片
func set_texture(texture: Texture2D) -> void:
	if texture_rect:
		texture_rect.texture = texture

# 在label容器中添加RichTextLabel
func add_label(text: String) -> RichTextLabel:
	if not label_container:
		return null
	
	var rich_label = RichTextLabel.new()
	rich_label.bbcode_enabled = true
	rich_label.text = text
	rich_label.fit_content = true
	rich_label.scroll_active = false
	rich_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rich_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rich_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	label_container.add_child(rich_label)
	return rich_label

# 在tag容器中添加RichTextLabel
func add_tag(text: String) -> RichTextLabel:
	if not tag_container:
		return null
	
	var rich_label = RichTextLabel.new()
	rich_label.bbcode_enabled = true
	rich_label.text = text
	rich_label.fit_content = true
	rich_label.scroll_active = false
	rich_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rich_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rich_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	tag_container.add_child(rich_label)
	return rich_label
