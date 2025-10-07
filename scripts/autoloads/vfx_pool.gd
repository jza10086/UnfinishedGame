extends Node

# 预加载你的特效场景
var laser_effect_scene: PackedScene = preload("res://assets/model/ships/lazer/lazer.tscn")
var path_3d_scene: PackedScene = preload("res://assets/model/3d_path/3d_path001.tscn")

# 用数组作为池子，存储不同类型的特效实例
var laser_pool = []
var path_3d_pool = []
var max_lazer_pool_size = 100 # 根据你的游戏规模调整
var max_path_3d_pool_size = 50 # 根据你的游戏规模调整

# 为激光特效设置独立的材质副本
func _setup_unique_material(laser: Node3D):
	var mesh_instance = laser.get_node("MeshInstance3D") as MeshInstance3D
	if mesh_instance:
		# 获取原始材质
		var original_material = mesh_instance.get_surface_override_material(0)
		if not original_material:
			original_material = mesh_instance.mesh.surface_get_material(0)
		
		if original_material:
			# 创建材质的深度副本
			var material_copy = original_material.duplicate(true)
			# 将副本设置为表面覆盖材质
			mesh_instance.set_surface_override_material(0, material_copy)

func _ready():
	# 游戏开始时，预先实例化一些特效对象放入池中
	for i in range(max_lazer_pool_size):
		var laser = laser_effect_scene.instantiate()
		laser.name = "LaserEffect_" + str(i) # 方便调试
		_setup_unique_material(laser)
		laser_pool.append(laser)

	for i in range(max_path_3d_pool_size):
		var path_3d = path_3d_scene.instantiate()
		path_3d.name = "Path3DEffect_" + str(i) # 方便调试
		path_3d_pool.append(path_3d)


# 从池中获取一个激光特效
func get_laser():
	if laser_pool.is_empty():
		# 如果池子空了，动态创建一个新的（作为备用方案）
		var laser = laser_effect_scene.instantiate()
		_setup_unique_material(laser)
		return laser
	else:
		# 从池子末尾取出一个
		return laser_pool.pop_back()

# 从池中获取一个3D路径特效
func get_path_3d():
	if path_3d_pool.is_empty():
		# 如果池子空了，动态创建一个新的（作为备用方案）
		var path_3d = path_3d_scene.instantiate()
		return path_3d
	else:
		# 从池子末尾取出一个
		return path_3d_pool.pop_back()

# 将用完的特效返回池中
func return_laser(laser: Node3D):
	# 检查池子是否已满，避免无限增长
	if laser_pool.size() >= max_lazer_pool_size:
		# 如果满了，直接销毁，不再回收
		laser.queue_free()
		return

	# 从场景树中移除它，但保留在内存中
	if laser.get_parent():
		laser.get_parent().remove_child(laser)
	
	laser_pool.append(laser)

func return_path_3d(path_3d: Node3D):
	# 检查池子是否已满，避免无限增长
	if path_3d_pool.size() >= max_path_3d_pool_size:
		# 如果满了，直接销毁，不再回收
		path_3d.queue_free()
		return

	# 从场景树中移除它，但保留在内存中
	if path_3d.get_parent():
		path_3d.get_parent().remove_child(path_3d)
	
	path_3d_pool.append(path_3d)

# 重置激光材质参数
func _reset_laser_material(laser: Node3D):
	var mesh_instance = laser.get_node("MeshInstance3D") as MeshInstance3D
	if mesh_instance:
		var material = mesh_instance.get_surface_override_material(0)
		if material:
			# 重置shader参数到默认值
			material.set_shader_parameter("beam_width_coeff", 1.0)
			material.set_shader_parameter("beam_width", 0.5)

