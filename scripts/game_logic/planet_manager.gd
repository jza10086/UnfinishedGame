extends Manager

# 行星管理容器
var planets: Dictionary = {}  # {planet_id: planet_node}

# 行星更新计数器
var planet_update_counter: int = 0
var is_waiting_for_planet_updates: bool = false

func _ready() -> void:
	super._ready()
	# 连接信号
	GlobalSignalBus.connect("stellar_init_requested", _on_stellar_init_requested)
	GlobalSignalBus.connect("planet_create_requested", _on_planet_create_requested)
	GlobalSignalBus.connect("planet_update_completed", _on_planet_update_completed)

# 信号处理：当恒星系请求初始化时
func _on_stellar_init_requested(stellar: Node):
	initialize_stellar_planets(stellar)

# 信号处理：当请求创建行星时
func _on_planet_create_requested(stellar: Node, orbit_id: int, planet_type: String, angle_coefficient: float):
	create_planet(stellar, orbit_id, planet_type, angle_coefficient)

# 信号处理：当行星更新完成时
func _on_planet_update_completed():
	planet_update_counter -= 1
	
	# 检查是否所有行星都完成了更新
	if is_waiting_for_planet_updates and planet_update_counter <= 0:
		is_waiting_for_planet_updates = false
		print("PlanetManager: 所有行星更新完成")
		GlobalSignalBus.all_planet_update_completed.emit.call_deferred()

# 初始化恒星系的行星（原stellar.stellar_init中的行星部分）
func initialize_stellar_planets(stellar: Node) -> bool:
	# 确保节点已经准备好
	if not stellar.orbits_container:
		printerr("轨道容器节点未准备好，初始化失败")
		return false
	
	# 如果没有指定恒星类型，跳过初始化
	if stellar.stellar_type == "":
		print("未指定恒星类型，跳过初始化")
		return true
	
	# 从 StellarJsonLoader 获取恒星系类型数据
	var stellar_data = StellarJsonLoader.get_stellar_type(stellar.stellar_type)
	if stellar_data.is_empty():
		printerr("无法找到恒星系类型: " + stellar.stellar_type)
		return false
	
	# 处理行星生成
	if stellar_data.has("planets"):
		var planets_data = stellar_data["planets"]
		for planet_type in planets_data:
			var planet_data = planets_data[planet_type]
			var orbit = planet_data["orbit"]
			var radius = planet_data["radius"]
			var angle = planet_data["angle"]
			
			# 创建轨道
			stellar.orbits_container.create_orbit(orbit, radius)
			
			# 创建行星，使用指定的角度系数
			create_planet(stellar, orbit, planet_type, angle)
	
	return true

# 创建行星（原stellar.create_planet逻辑迁移）
func create_planet(stellar: Node, orbit_id: int, planet_type: String = "", angle_coefficient: float = randf()) -> Node:
	if not stellar:
		printerr("恒星系对象为空")
		return null
		
	var orbit_radius = stellar.orbits_container.get_orbit_radius(orbit_id)
	if orbit_radius < 0:
		printerr("无效轨道半径: " + str(orbit_id))
		return null
	
	# 使用轨道容器的角度处理功能
	var final_angle = stellar.orbits_container.find_available_angle(orbit_id, angle_coefficient)
	if final_angle < 0:
		printerr("无法在轨道 " + str(orbit_id) + " 上找到合适的位置")
		return null
	
	# 通过 planet.gd 的静态方法创建完整的行星场景实例
	var planet = Planet.create_planet_tscn(planet_type)
	# 设置行星名称和ID
	planet.name = stellar.name + str(MathTools.roman_num(stellar.planet_id))
	
	# 为行星设置ID：stellar的五位数ID + 两位planet_id
	if stellar.stellar_id != -1:
		var planet_full_id = stellar.stellar_id * 100 + stellar.planet_id
		planet.planet_id = planet_full_id
		# 注册到管理器
		planets[planet_full_id] = planet
	
	stellar.planet_id += 1
	
	# 根据最终角度计算位置
	var pos_x = orbit_radius * cos(final_angle)
	var pos_z = orbit_radius * sin(final_angle)
	planet.position = Vector3(pos_x, 0, pos_z)

	# 设置默认所有者为System faction
	var system_faction_id = 1000
	planet.set_faction_owner(system_faction_id)

	stellar.planet_container.add_child(planet)
	
	# 添加行星到恒星系的planets数组
	stellar.planets.append(planet)
	
	# 在添加到场景树后，立即初始化ColonyTile
	if planet.has_method("initialize_colony_tile"):
		planet.call_deferred("initialize_colony_tile")
	
	return planet

# 获取行星
func get_planet_by_id(planet_id: int) -> Node:
	if planets.has(planet_id):
		return planets[planet_id]
	return null

# 移除行星
func remove_planet(planet_id: int) -> bool:
	if not planets.has(planet_id):
		return false
	
	var planet = planets[planet_id]
	planets.erase(planet_id)
	
	# 从恒星系的planets数组中移除
	var stellar = planet.get_parent().get_parent()  # planet -> planet_container -> stellar
	stellar.planets.erase(planet)

	planet.queue_free()
	return true

# 获取所有行星ID
func get_all_planet_ids() -> Array:
	return planets.keys()

# 获取行星数量
func get_planet_count() -> int:
	return planets.size()


# 所有权管理函数
func set_planet_owner(planet_id: int, new_faction_id: int) -> bool:
	"""设置行星所有权，直接操作faction数据"""
	var planet = get_planet_by_id(planet_id)
	if not planet:
		push_error("PlanetManager: 找不到行星 ID: " + str(planet_id))
		return false
	
	var old_faction_id = planet.get_faction_owner()
	
	# 如果所有者相同，直接返回
	if old_faction_id == new_faction_id:
		return true
	
	# 从旧所有者移除
	if old_faction_id != -1:
		var old_faction = GlobalNodes.managers.FactionManager.get_faction(old_faction_id)
		if old_faction:
			var index = old_faction.owned_planet_ids.find(planet_id)
			if index != -1:
				old_faction.owned_planet_ids.remove_at(index)
	
	# 添加到新所有者
	if new_faction_id != -1:
		var new_faction = GlobalNodes.managers.FactionManager.get_faction(new_faction_id)
		if new_faction:
			if not new_faction.owned_planet_ids.has(planet_id):
				new_faction.owned_planet_ids.append(planet_id)
	
	# 设置行星对象的所有者
	planet.set_faction_owner(new_faction_id)
	
	print("PlanetManager: 行星 ", planet.name, " (ID:", planet_id, ") 所有权转移: ", old_faction_id, " -> ", new_faction_id)
	return true

func get_planet_owner(planet_id: int) -> int:
	"""获取行星所有者"""
	var planet = get_planet_by_id(planet_id)
	if planet:
		return planet.get_faction_owner()
	return -1

func get_planets_by_faction(faction_id: int) -> Array:
	"""获取指定阵营拥有的所有行星"""
	var faction_planets = []
	for planet in planets.values():
		if planet.get_faction_owner() == faction_id:
			faction_planets.append(planet)
	return faction_planets

func set_stellar_planets_owner(stellar_id: int, faction_id: int) -> int:
	"""设置恒星系下所有行星的所有者，返回受影响的行星数量"""
	var stellar = GlobalNodes.managers.StellarManager.get_stellar_by_id(stellar_id)
	var stellar_planets = stellar.planets
	var affected_count = 0
	
	for planet in stellar_planets:
		if set_planet_owner(planet.planet_id, faction_id):
			affected_count += 1
	
	print("恒星系 ID:", stellar_id, " 下 ", affected_count, " 个行星所有权变更为阵营:", faction_id)
	return affected_count

# 触发行星更新并等待完成
func trigger_planet_update() -> void:
	"""发出planet_update信号并等待所有行星完成更新"""

	# 记录需要更新的行星数量
	var total_planets = planets.size()
	if total_planets == 0:
		print("PlanetManager: 没有行星需要更新")
		GlobalSignalBus.all_planet_update_completed.emit()
		return
	
	# 初始化计数器
	planet_update_counter = total_planets
	is_waiting_for_planet_updates = true

	
	# 发出planet_update信号
	GlobalSignalBus.planet_update.emit()
	
