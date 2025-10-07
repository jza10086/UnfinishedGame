extends Node3D

@export_group("轨道参数")
@export var default_radius: float = 5.0

@export var segments: int = 64:
	set(value):
		segments = max(3, value) # 至少3个分段

@export var ring_width: float = 0.05 # 轨道环带的宽度


@export var tilt_degrees: float = 0.0 # 轨道倾斜角度


@export_group("材质")
@export var orbit_color: Color = Color(0.5, 0.7, 1.0, 0.5)# 包含透明度

@export_group("角度管理")
# 追踪每个轨道上已使用的角度（以弧度为单位）
var used_angles_per_orbit: Dictionary = {}
# 基础最小角度间隔（弧度）- 用于计算动态间隔
@export var base_angle_separation: float = 0.5
# 半径系数，用于调整不同半径轨道的角度间隔
@export var radius_coefficient: float = 5

var stellar_name: String

# 全局材质变量，供多个函数访问
var material: StandardMaterial3D

# 存储轨道ID与半径的映射
var orbit_radius: Dictionary = {}

func _ready() -> void:
	pass

# 设置材质
func set_material(mesh_inst: MeshInstance3D):
	material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = orbit_color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_inst.material_override = material

# 创建轨道节点
func create_orbit(id: int, radius: float = default_radius):
	if orbit_radius.has(id):
		return
	else:
		# 存储轨道半径
		orbit_radius[id] = radius

	# 创建网格实例作为局部变量
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "轨道"+ stellar_name + str(id)
	add_child(mesh_instance)
	# 创建并配置材质
	set_material(mesh_instance)
	# 生成轨道环网格
	create_mesh(mesh_instance, radius)

# 创建轨道网格
func create_mesh(mesh_instance: MeshInstance3D, radius: float):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 计算倾斜的旋转
	var tilt_radians = deg_to_rad(tilt_degrees)
	var basis_tilt = Basis().rotated(Vector3.RIGHT, tilt_radians)

	for i in range(segments + 1): # +1 使环闭合
		var angle = TAU * i / segments
		var cos_angle = cos(angle)
		var sin_angle = sin(angle)

		# 内部顶点
		var inner_v_local = Vector3(cos_angle * (radius - ring_width / 2.0), 0, sin_angle * (radius - ring_width / 2.0))
		# 外部顶点
		var outer_v_local = Vector3(cos_angle * (radius + ring_width / 2.0), 0, sin_angle * (radius + ring_width / 2.0))

		# 应用倾斜
		var inner_v = basis_tilt * inner_v_local
		var outer_v = basis_tilt * outer_v_local
		
		# 法线
		var normal = (basis_tilt * Vector3.UP).normalized()
		
		# UVs
		var u = float(i) / segments
		var uv_inner = Vector2(u, 0)
		var uv_outer = Vector2(u, 1)

		st.set_normal(normal)
		st.set_uv(uv_outer)
		st.add_vertex(outer_v)
		st.set_uv(uv_inner)
		st.add_vertex(inner_v)

	# 创建索引
	for i in range(segments):
		var current_outer = i * 2
		var current_inner = i * 2 + 1
		var next_outer = (i + 1) * 2
		var next_inner = (i + 1) * 2 + 1

		# 第一个三角形
		st.add_index(current_inner)
		st.add_index(next_outer)
		st.add_index(current_outer)

		# 第二个三角形
		st.add_index(current_inner)
		st.add_index(next_inner)
		st.add_index(next_outer)

	var new_mesh = st.commit()
	new_mesh.surface_set_material(0, material)
	mesh_instance.mesh = new_mesh
	
# 获取指定轨道的半径
func get_orbit_radius(orbit_id: int) -> float:
	# 从存储的映射中获取轨道半径
	if orbit_id in orbit_radius:
		return orbit_radius[orbit_id]
	else:
		# 如果轨道不存在，返回 -1 表示未找到
		printerr("未找到轨道 ID " + str(orbit_id))
		return -1.0

#region 角度处理函数
# 为指定轨道查找不冲突的角度位置
func find_available_angle(orbit_id: int, preferred_angle_coefficient: float = randf()) -> float:
	# 限制angle_coefficient在0.0-1.0范围内
	if preferred_angle_coefficient < 0.0 or preferred_angle_coefficient > 1.0:
		printerr("角度系数必须在0.0到1.0之间")
		preferred_angle_coefficient = clamp(preferred_angle_coefficient, 0.0, 1.0)
	
	var orbit_radius_value = get_orbit_radius(orbit_id)
	if orbit_radius_value < 0:
		printerr("无效轨道半径: " + str(orbit_id))
		return -1.0
	
	# 计算此轨道的动态最小角度间隔
	var min_angle_separation = calculate_min_angle_separation(orbit_radius_value)
	
	# 初始化轨道的角度数组（如果不存在）
	if not orbit_id in used_angles_per_orbit:
		used_angles_per_orbit[orbit_id] = []
	
	# 计算目标角度
	var target_angle = preferred_angle_coefficient * TAU
	
	# 查找不冲突的角度
	var final_angle = find_non_conflicting_angle(orbit_id, target_angle, min_angle_separation)
	if final_angle < 0:
		printerr("无法在轨道 " + str(orbit_id) + " 上找到合适的位置")
		return -1.0
	
	# 记录使用的角度
	used_angles_per_orbit[orbit_id].append(final_angle)
	return final_angle

# 查找不与现有行星冲突的角度
func find_non_conflicting_angle(orbit_id: int, preferred_angle: float, min_angle_separation: float) -> float:
	var used_angles = used_angles_per_orbit[orbit_id]
	
	# 如果没有其他行星，直接使用首选角度
	if used_angles.is_empty():
		return preferred_angle
	
	# 检查首选角度是否冲突
	if not is_angle_conflicting(preferred_angle, used_angles, min_angle_separation):
		return preferred_angle
	
	# 尝试在首选角度附近找到合适位置
	var search_range = PI / 6.0  # 搜索范围：30度
	var step = 0.1  # 步长
	
	for offset in range(1, int(search_range / step) + 1):
		var offset_radians = offset * step
		
		# 尝试正向偏移
		var angle1 = fmod(preferred_angle + offset_radians, TAU)
		if not is_angle_conflicting(angle1, used_angles, min_angle_separation):
			return angle1
		
		# 尝试负向偏移
		var angle2 = fmod(preferred_angle - offset_radians + TAU, TAU)
		if not is_angle_conflicting(angle2, used_angles, min_angle_separation):
			return angle2
	
	# 如果在搜索范围内找不到，进行全轨道搜索
	for i in range(0, int(TAU / step)):
		var test_angle = i * step
		if not is_angle_conflicting(test_angle, used_angles, min_angle_separation):
			return test_angle
	
	# 如果轨道已满，返回-1
	return -1.0

# 检查角度是否与现有角度冲突
func is_angle_conflicting(test_angle: float, used_angles: Array, min_angle_separation: float) -> bool:
	for used_angle in used_angles:
		var angle_diff = abs(test_angle - used_angle)
		# 考虑角度的循环性质（0和2π是相同的）
		angle_diff = min(angle_diff, TAU - angle_diff)
		
		if angle_diff < min_angle_separation:
			return true
	
	return false

# 根据轨道半径计算动态的最小角度间隔
func calculate_min_angle_separation(orbit_radius_value: float) -> float:
	# 基本思路：半径越小，需要更大的角度间隔；半径越大，可以更密集
	# 公式：base_separation * (radius_coefficient / orbit_radius)
	# 限制最小值和最大值，防止极端情况
	var dynamic_separation = base_angle_separation * (radius_coefficient / orbit_radius_value)
	return clamp(dynamic_separation, 0.3, 1.0)  # 最大约57.3°

# 清除指定轨道的所有已使用角度（可选功能）
func clear_orbit_angles(orbit_id: int):
	if orbit_id in used_angles_per_orbit:
		used_angles_per_orbit[orbit_id].clear()

# 获取指定轨道已使用的角度数量
func get_orbit_used_angle_count(orbit_id: int) -> int:
	if orbit_id in used_angles_per_orbit:
		return used_angles_per_orbit[orbit_id].size()
	return 0
#endregion
