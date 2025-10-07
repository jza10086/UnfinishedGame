extends Node3D
# 舰队实例
var visual_path = preload("res://assets/model/3d_path/3d_path001.tscn")


@export var MapGenerater :Node
@export var UIManager :Node
@export var test_hud :Node
@export var PlayerController: Node

func _ready() -> void:
	# 使用新的初始化方法
	GlobalNodes.initialize_from_main(self)
	MapGenerater.generate_map_total()
	
	# 创建测试阵营和设置外交关系
	create_test_factions_and_diplomacy()
	
	creat_fleet_test()
	
	# 测试bonus actions
	test_bonus_actions()
	
	ZeroTurnAction.init_zero_turn()
	
func create_test_factions_and_diplomacy():
	"""创建测试阵营并设置外交关系 - 合并版本"""
	if GlobalNodes.managers.FactionManager == null:
		print("错误：FactionManager未初始化")
		return
	
	print("=== 创建测试阵营 ===")
	
	# 获取System faction ID
	var system_id = 1000
	
	# 创建人类联邦
	var human_id = GlobalNodes.managers.FactionManager.create_faction("人类联邦", "人类", "人类的")
	print("创建阵营：人类联邦，ID:", human_id)
	
	# 创建虫族帝国
	var zerg_id = GlobalNodes.managers.FactionManager.create_faction("虫族帝国", "虫族", "虫族的") 
	print("创建阵营：虫族帝国，ID:", zerg_id)
	
	# 创建机械军团
	var robot_id = GlobalNodes.managers.FactionManager.create_faction("机械军团", "机械", "机械的")
	print("创建阵营：机械军团，ID:", robot_id)
	
	# 创建星际海盗
	var pirate_id = GlobalNodes.managers.FactionManager.create_faction("星际海盗", "海盗", "海盗的")
	print("创建阵营：星际海盗，ID:", pirate_id)
	
	# 设置各阵营的TECH产出
	print("=== 设置TECH产出 ===")
	var human_faction = GlobalNodes.managers.FactionManager.get_faction(human_id)
	var zerg_faction = GlobalNodes.managers.FactionManager.get_faction(zerg_id)
	var robot_faction = GlobalNodes.managers.FactionManager.get_faction(robot_id)
	var pirate_faction = GlobalNodes.managers.FactionManager.get_faction(pirate_id)
	
	if human_faction:
		human_faction.resource_productions[GlobalEnum.ResourceType.TECH] = 250.0
		human_faction.current_researching_tech = "DefaultPak:advanced_weapons"
		print("人类联邦 TECH产出: 250, 当前研究: DefaultPak:advanced_weapons")
	
	if zerg_faction:
		zerg_faction.resource_productions[GlobalEnum.ResourceType.TECH] = 150.0
		zerg_faction.current_researching_tech = "DefaultPak:advanced_weapons"
		print("虫族帝国 TECH产出: 150, 当前研究: DefaultPak:advanced_weapons")
	
	if robot_faction:
		robot_faction.resource_productions[GlobalEnum.ResourceType.TECH] = 450.0
		robot_faction.current_researching_tech = "DefaultPak:advanced_weapons"
		print("机械军团 TECH产出: 450, 当前研究: DefaultPak:advanced_weapons")
	
	if pirate_faction:
		pirate_faction.resource_productions[GlobalEnum.ResourceType.TECH] = 100.0
		pirate_faction.current_researching_tech = "DefaultPak:advanced_weapons"
		print("星际海盗 TECH产出: 100, 当前研究: DefaultPak:advanced_weapons")
	
	# 设置各阵营的基础情报等级
	print("=== 设置基础情报等级 ===")
	GlobalNodes.managers.FactionManager.set_base_intelligence_level(system_id, 50)  # System faction基础情报等级
	GlobalNodes.managers.FactionManager.set_base_intelligence_level(human_id, 45)   # 人类联邦基础情报等级
	GlobalNodes.managers.FactionManager.set_base_intelligence_level(zerg_id, 30)    # 虫族帝国基础情报等级
	GlobalNodes.managers.FactionManager.set_base_intelligence_level(robot_id, 60)   # 机械军团基础情报等级（最高）
	GlobalNodes.managers.FactionManager.set_base_intelligence_level(pirate_id, 40)  # 星际海盗基础情报等级
	
	print("基础情报等级设置完成：")
	print("- System: 50")
	print("- 人类联邦: 45") 
	print("- 虫族帝国: 30")
	print("- 机械军团: 60")
	print("- 星际海盗: 40")
	
	# 设置外交关系
	print("=== 设置外交关系 ===")
	var all_factions = GlobalNodes.managers.FactionManager.get_all_faction_ids()
	
	for faction_id in all_factions:
		if faction_id == system_id:
			continue
		
		var faction = GlobalNodes.managers.FactionManager.get_faction(faction_id)
		if not faction:
			continue
		
		# 根据阵营名称设置不同的外交数据
		var diplomatic_data: Dictionary
		match faction.display_name:
			"人类联邦":
				diplomatic_data = {
					"relation": GlobalEnum.DiplomaticRelation.FRIENDLY,
					"favor": 60,
					"visibility": true,
					"base_intelligence_a": 50,  # System的基础情报等级
					"intelligence_bonus_a_to_b": 25,  # System对人类联邦的情报加成
					"intelligence_bonus_b_to_a": -5   # 人类联邦对System的情报加成
				}
			"虫族帝国":
				diplomatic_data = {
					"relation": GlobalEnum.DiplomaticRelation.HOSTILE,
					"favor": -80,
					"visibility": true,
					"base_intelligence_a": 50,  # System的基础情报等级
					"intelligence_bonus_a_to_b": -10, # System对虫族帝国的情报加成
					"intelligence_bonus_b_to_a": -20  # 虫族帝国对System的情报加成
				}
			"机械军团":
				diplomatic_data = {
					"relation": GlobalEnum.DiplomaticRelation.NEUTRAL,
					"favor": 10,
					"visibility": true,
					"base_intelligence_a": 50,  # System的基础情报等级
					"intelligence_bonus_a_to_b": 5,   # System对机械军团的情报加成
					"intelligence_bonus_b_to_a": -15  # 机械军团对System的情报加成
				}
			"星际海盗":
				diplomatic_data = {
					"relation": GlobalEnum.DiplomaticRelation.HOSTILE,
					"favor": -45,
					"visibility": true,
					"base_intelligence_a": 50,  # System的基础情报等级
					"intelligence_bonus_a_to_b": -25, # System对星际海盗的情报加成
					"intelligence_bonus_b_to_a": 10   # 星际海盗对System的情报加成
				}
			_:
				diplomatic_data = {
					"relation": GlobalEnum.DiplomaticRelation.UNKNOWN,
					"favor": 0,
					"visibility": false,
					"base_intelligence_a": 50,  # System的基础情报等级
					"intelligence_bonus_a_to_b": 0,   # 无情报加成
					"intelligence_bonus_b_to_a": 0    # 无情报加成
				}
		
		GlobalNodes.managers.FactionManager.set_diplomatic_data(system_id, faction_id, diplomatic_data)
		print("设置外交关系：System <-> ", faction.display_name, " 关系:", diplomatic_data)

func creat_fleet_test():
	var action = FleetCreateAction.new("test",10001,1000)
	GlobalNodes.managers.ActionManager.add_action(action)


func _on_next_turn_button_pressed() -> void:
	GlobalNodes.managers.TurnManager.next_turn()

func _on_button_pressed() -> void:
	print("=== 所有faction的科技进度 ===")
	var all_faction_ids = GlobalNodes.managers.FactionManager.get_all_faction_ids()
	
	for faction_id in all_faction_ids:
		if faction_id == 1000:  # 跳过System faction
			continue
			
		var faction = GlobalNodes.managers.FactionManager.get_faction(faction_id)
		if faction:
			print("阵营:", faction.display_name, " (ID:", faction_id, ")")
			print("  TECH产出:", faction.resource_productions.get(GlobalEnum.ResourceType.TECH, 0))
			print("  当前研究:", faction.current_researching_tech)
			print("  研究进度:", faction.researching_progress)
			print("  已解锁科技:", faction.unlocked_techs)
			print("  可研究科技:", faction.available_techs)
			print("  研究溢出:", faction.researching_overflow)
			print("  ---")

func test_bonus_actions():
	"""测试两种bonus action的功能"""
	
	var test_unit_id = 10000
	var bonus_type = "tech_bonus_energy"
	
	print("测试单位ID: ", test_unit_id)
	print("使用bonus类型: ", bonus_type)
	
	# 测试 UnitAddBonusAction (原版，需要手动指定所有参数)
	var manual_resources = {GlobalEnum.ResourceType.ENERGY: -0.2}
	var manual_action = UnitAddBonusAction.new(
		test_unit_id,
		manual_resources,
		"手动科技加成：能量产出+20%",
		BonusResource.BonusType.MULTIPLIER,
		false,
		-1
	)
	GlobalNodes.managers.ActionManager.add_action(manual_action)
	
	# 测试 UnitAddBonusByTypeAction (新版，通过JSON自动配置)

	var type_action = UnitAddBonusByTypeAction.new(test_unit_id, bonus_type)
	
	GlobalNodes.managers.ActionManager.add_action(type_action)
