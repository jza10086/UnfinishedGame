@tool
extends JzaGraphTree
class_name CoreTechTree

var current_faction: Resource

func _ready() -> void:
	super._ready()
	
	if not Engine.is_editor_hint():
		var faction_id = GlobalNodes.managers.StateManager.current_faction_id
		# 根据ID从GlobalNodes.manager.FactionManager获取faction
		current_faction = GlobalNodes.managers.FactionManager.get_faction(faction_id)
		if not current_faction:
			push_error("GeneralTechPanel: 找不到faction_id " + str(faction_id))
			return
			
		# 在加载节点后初始化所有核心科技节点
		initialize_core_tech_nodes()

func initialize_core_tech_nodes() -> void:
	"""
	初始化所有 CoreTechTreeNode 节点
	为每个节点加载科技数据并设置名称标签
	"""
	if not node_container:
		push_error("CoreTechTree: node_container 未设置")
		return
	
	for child in node_container.get_children():
		if child is CoreTechTreeNode:
			var tech_node = child
			
			# 检查 tech_type 是否已设置
			if tech_node.tech_type.is_empty():
				push_warning("CoreTechTree: 节点 %s 的 tech_type 为空，跳过" % tech_node.name)
				continue
			
			# 从 TechJsonLoader 加载科技数据
			var tech_data = TechJsonLoader.get_tech(tech_node.tech_type)
			
			if tech_data.is_empty():
				push_error("CoreTechTree: 无法加载 tech_type '%s' 的数据" % tech_node.tech_type)
				continue
			
			# 验证科技类型必须是 CORE
			var tech_category = tech_data.get("tech_category", GlobalEnum.TechCategory.GENERAL)
			if tech_category != GlobalEnum.TechCategory.CORE:
				push_error("CoreTechTree: tech_type '%s' 不是 CORE 类型科技" % tech_node.tech_type)
				continue
			
			# 设置节点数据
			tech_node.set_data(tech_data)
			
			# 设置名称标签（暂时使用 tech_type）TODO: 以后根据语言文件更改名称
			tech_node.set_label(tech_node.tech_type)
			
			# 检查科技是否在 faction 的 available_techs 中，设置可用性
			tech_node.available = current_faction.available_techs.has(tech_node.tech_type)
			
			# 连接按钮按下信号
			if not tech_node.button.pressed.is_connected(_on_tech_node_pressed):
				tech_node.button.pressed.connect(_on_tech_node_pressed.bind(tech_node.tech_type))
			
func _on_tech_node_pressed(tech_type: StringName) -> void:
	
	GlobalNodes.PlayerController.set_current_researching_tech(GlobalNodes.managers.StateManager.current_faction_id, tech_type)
	

func get_tech_node_by_type(tech_type: StringName) -> CoreTechTreeNode:
	"""
	根据 tech_type 获取对应的节点
	"""
	for node in nodes:
		if node is CoreTechTreeNode and node.tech_type == tech_type:
			return node
	return null
