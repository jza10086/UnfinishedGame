extends JzaPanel

@export var general_tech_list: PanelContainer
@export var current_researching_tech_label: PanelContainer
@export var empty_tech_label: RichTextLabel
@export var current_researchin_progress_bar: ProgressBar
@export var researching_overflow_label: RichTextLabel

func _ready():
	
	general_tech_list.label_pressed.connect(on_label_pressed)
	
	var faction_id = GlobalNodes.managers.StateManager.current_faction_id

	# 根据ID从GlobalNodes.manager.FactionManager获取faction
	var faction = GlobalNodes.managers.FactionManager.get_faction(faction_id)
	if not faction:
		push_error("GeneralTechPanel: 找不到faction_id " + str(faction_id))
		return
	
	var overflow_text = tr("UI_GeneralTechPanel_ResearchingOverflowLabel")
	overflow_text = overflow_text.format({
		"amount": faction.researching_overflow
	})
	researching_overflow_label.text =overflow_text
	init_optional_techs(faction)
	set_current_researching_tech(faction)



func init_optional_techs(faction: FactionResource) -> void:
	# 清空现有列表
	general_tech_list.clear_tech_labels()
	
	var optional_techs: Dictionary = {}  # {tech_type: progress_value}
	
	# 从faction获取researching_progress的tech_type和研究进度
	for tech_type in faction.researching_progress:
		var progress_value = faction.researching_progress[tech_type]
		optional_techs[tech_type] = progress_value
	
	# 从faction获取selectable_techs的tech_type，默认研究进度为0.0
	for tech_type in faction.selectable_techs:
		# 跳过重复的type
		if not optional_techs.has(tech_type):
			optional_techs[tech_type] = 0.0
	
	# 往general_tech_list中添加optional_techs
	for tech_type in optional_techs:
		var progress_value = optional_techs[tech_type]
		general_tech_list.add_tech_label(tech_type, progress_value)

func set_current_researching_tech(faction: FactionResource) -> void:
	# 获取当前正在研究的科技类型
	var current_tech = faction.current_researching_tech
	
	# 如果为空，则隐藏current_researching_tech_label，显示empty_tech_label
	if current_tech.is_empty():
		current_researching_tech_label.hide()
		empty_tech_label.show()
		current_researchin_progress_bar.value = 0.0
		return
	
	# 如果不为空，显示current_researching_tech_label，隐藏empty_tech_label
	current_researching_tech_label.show()
	empty_tech_label.hide()
	
	# 获取当前科技的研究进度
	var progress = faction.researching_progress.get(current_tech, 0.0)
	
	# 获取科技数据以获取总cost
	var tech_data = TechJsonLoader.get_tech(current_tech)
	var cost = tech_data.get("cost", 1.0)
	
	# 设置current_researching_tech_label(一个general_tech_label)
	current_researching_tech_label.set_tech_data(current_tech, progress)
	
	# 映射研究进度与cost之比到0.0-100.0
	var progress_percentage = (progress / cost) * 100.0
	current_researchin_progress_bar.value = progress_percentage

func init_panel(_data):
	pass

func refresh():
	pass

func cleanup():
	pass
	
func connect_signals():
	pass
	
func disconnect_signals():
	pass

func _on_exit_button_pressed() -> void:
	disconnect_signals()
	GlobalNodes.UIManager.back_to_main()

func on_label_pressed(tech_type):
	GlobalNodes.PlayerController.set_current_researching_tech(GlobalNodes.managers.StateManager.current_faction_id, tech_type)
	var faction_id = GlobalNodes.managers.StateManager.current_faction_id

	# 根据ID从GlobalNodes.manager.FactionManager获取faction
	var faction = GlobalNodes.managers.FactionManager.get_faction(faction_id)
	set_current_researching_tech(faction)
	
