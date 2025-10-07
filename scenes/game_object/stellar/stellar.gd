class_name Stellar
extends Unit

# 唯一标识符
var stellar_id: int = -1  # 五位数ID，由StellarManager分配

# 所有权信息
var owner_faction: int = -1  # 所属阵营ID，-1表示无主

# 与其他恒星系的连接关系 - 格式："恒星系名称": 距离
@export var stellar_connections:Dictionary = {}

@export var planet_container:Node

# 行星管理数组
var planets: Array = []  # 存储该恒星系下所有行星的引用

var stellar_type:String
var describe: String

var bonus_ids_from_planets: Dictionary = {}  # 记录由各planet添加的bonus ID，key: Planet, value: Array[int]

@export var orbits_container :Node3D
@export var stellar_label :Node3D

var planet_id: int = 1
# 唯一标识符:name


func _init() -> void:
	unit_type = GlobalEnum.UnitType.STELLAR
	# 初始化恒星系资源管理器
	bonus_resource = BonusResource.new()


func _ready():
	# 调用基类的_ready方法
	super._ready()
	
	# 连接恒星系更新信号
	GlobalSignalBus.stellar_update.connect(self.update)



# 所有权管理方法
func set_faction_owner(faction_id: int):
	"""设置恒星系所有者"""
	owner_faction = faction_id

func get_faction_owner() -> int:
	"""获取恒星系所有者，-1表示无主"""
	return owner_faction

# 设置name和position
func set_basic_infos(input_name: String, input_position: Vector3,input_type:String):
	self.name = input_name
	self.position = input_position
	stellar_type = input_type
	var stellar_type_data = StellarJsonLoader.get_stellar_type(stellar_type)
	self.scale = self.scale * stellar_type_data["size"]
	describe = stellar_type_data["describe"]
	
	# 设置恒星系基础资源
	set_basic_bonus(stellar_type_data)

	# 设置轨道容器的恒星名称
	if orbits_container:
		orbits_container.stellar_name = input_name
	# 延迟初始化，等待节点准备完成
	call_deferred("stellar_init")

# 根据恒星系类型初始化恒星系
func stellar_init() -> bool:
	# 确保节点已经准备好
	if not orbits_container:
		printerr("轨道容器节点未准备好，初始化失败")
		return false
	
	# 如果没有指定恒星类型，跳过初始化
	if stellar_type == "":
		print("未指定恒星类型，跳过初始化")
		return true
	
	# 从 StellarJsonLoader 获取恒星系类型数据
	var stellar_data = StellarJsonLoader.get_stellar_type(stellar_type)
	if stellar_data.is_empty():
		printerr("无法找到恒星系类型: " + stellar_type)
		return false
	
	# 通过信号请求PlanetManager初始化行星
	GlobalSignalBus.stellar_init_requested.emit(self)
	
	# 延迟计算行星资源，等待行星初始化完成
	call_deferred("calculate_planets_resources")
	
	stellar_label.text = self.name 
	return true

# 在指定轨道上创建行星（通过信号委托给PlanetManager）
func create_planet(orbit_id: int, planet_type: String = "", angle_coefficient: float = randf()):
	# 通过信号委托给PlanetManager处理
	GlobalSignalBus.planet_create_requested.emit(self, orbit_id, planet_type, angle_coefficient)





var popup_scene = preload("res://scenes/ui/panel/planet_panel.tscn")
# popup
func popup():
	var popup_instance = popup_scene.instantiate()
	popup_instance.set_planet_reference(planets[1])	  # 假设弹出第二个行星的信息面板
	GlobalNodes.UIManager.add_child(popup_instance)


func update_sprite_scale():
	var camera = GlobalNodes.managers.CameraManager.get_camera()
	var camera_y = camera.global_position.y
	var scale_factor = camera_y / 200.0
	var clamped_scale = clamp(scale_factor, 0.5, 2.0)  # 限制缩放范围
	stellar_label.scale = Vector3(clamped_scale, clamped_scale, clamped_scale)
	
	# 计算透明度值
	var alpha_value = 1.0

	if scale_factor < 0.8:
		alpha_value = 1.0 - remap(scale_factor, 0.5, 0.8, 1.0, 0.0)
	
	# 设置stellar_label的透明度
	stellar_label.modulate.a = alpha_value
	
	# 为preview_model设置材质透明度（基础alpha值为45/255）
	if preview_model:
		var base_alpha = 45.0 / 255.0  # 基础透明度值
		# 直接从mesh获取材质
		var material = preview_model.mesh.surface_get_material(0)
		
		if material:
			# 将计算出的alpha_value映射到基础透明度上
			var final_alpha = base_alpha * alpha_value
			final_alpha = clamp(final_alpha, 0.0, 1.0)  # 钳制alpha值在0-1之间
			material.albedo_color.a = final_alpha
	
	# 为highlight_model设置材质透明度（同样的逻辑和参数）
	if highlight_model and is_selected:
		var base_alpha = 255.0 / 255.0  # 基础透明度值
		# 直接从mesh获取材质
		var material = highlight_model.mesh.surface_get_material(0)
		
		if material:
			# 将计算出的alpha_value映射到基础透明度上
			var final_alpha = base_alpha * alpha_value
			final_alpha = clamp(final_alpha, 0.0, 1.0)  # 钳制alpha值在0-1之间
			material.albedo_color.a = final_alpha

	
#region 资源管理接口
# 设置恒星系的基础资源
func set_basic_bonus(stellar_type_data: Dictionary):
	"""根据stellar_type_data设置恒星系基础资源"""
	if stellar_type_data.has("basic_resources"):
		for resource_type in stellar_type_data["basic_resources"].keys():
			var resource_amount = stellar_type_data["basic_resources"][resource_type]
			add_resource_bonus(resource_type, "恒星系基础值", BonusResource.BonusType.BASIC, resource_amount)

# 计算来自所有行星的资源
func calculate_planets_resources():
	"""计算并添加来自所有行星的资源到恒星系资源中"""
	# 使用planets数组获取所有行星
	for planet in planets:
		if planet.is_changed == false:
			continue  # 如果行星数据未变更，跳过计算（不移除也不添加）
		
		# 如果该planet有之前的bonus记录，先移除
		if bonus_ids_from_planets.has(planet):
			for id in bonus_ids_from_planets[planet]:
				remove_resource_bonus(id)
			bonus_ids_from_planets[planet].clear()  # 清空数组，但保留键
		
		var planet_bonus_resource = planet.get_bonus_resource()

		# 使用get_data_types()函数获取行星BonusResource的所有key
		var planet_keys = planet_bonus_resource.get_data_types()
		
		# 初始化该planet的bonus IDs数组
		if not bonus_ids_from_planets.has(planet):
			bonus_ids_from_planets[planet] = []
		
		# 遍历行星的资源key
		for resource_type in planet_keys:
			var planet_total = planet_bonus_resource.get_result(resource_type)
				
			# 添加到恒星系资源中，来源为"来自行星名"
			var source_key = "来自" + planet.name
			var id = add_resource_bonus(resource_type, source_key, BonusResource.BonusType.BONUS, planet_total)
			bonus_ids_from_planets[planet].append(id)
		planet.is_changed = false  # 重置行星的变更标记
	

# 恒星系更新函数 - 通过信号机制调用
func update():
	"""恒星系更新函数，处理恒星系的各种更新逻辑"""
	
	# 重新计算来自所有行星的资源
	calculate_planets_resources()
	
	# 发送恒星系更新完成信号
	GlobalSignalBus.stellar_update_completed.emit()




#endregion
