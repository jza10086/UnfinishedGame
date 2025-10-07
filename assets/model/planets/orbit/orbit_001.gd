extends MeshInstance3D

@export_group("Orbit Parameters")
@export var radius: float = 5.0:
	set(value):
		radius = value
		_generate_orbital_ring()
@export var segments: int = 64:
	set(value):
		segments = max(3, value) # 至少3个分段
		_generate_orbital_ring()
@export var ring_width: float = 0.1: # 轨道环带的宽度
	set(value):
		ring_width = max(0.01, value)
		_generate_orbital_ring()
@export var tilt_degrees: float = 0.0: # 轨道倾斜角度
	set(value):
		tilt_degrees = value
		_generate_orbital_ring()

func _ready():
	_generate_orbital_ring()

func _generate_orbital_ring():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 计算倾斜的旋转
	var tilt_radians = deg_to_rad(tilt_degrees)
	var basis_tilt = Basis().rotated(Vector3.RIGHT, tilt_radians) # 绕X轴倾斜

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
		
		# 法线 (对于不受光照影响的材质，法线不那么重要，但好的习惯是设置它们)
		# 对于扁平朝上的环，法线可以是 Vector3.UP 经过 basis_tilt 变换
		var normal = (basis_tilt * Vector3.UP).normalized()
		
		# UVs (如果需要纹理)
		var u = float(i) / segments
		var uv_inner = Vector2(u, 0)
		var uv_outer = Vector2(u, 1)

		st.set_normal(normal)

		st.set_uv(uv_outer)
		st.add_vertex(outer_v)
		st.set_uv(uv_inner)
		st.add_vertex(inner_v)

	# 创建索引 (连接顶点形成三角面)
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
		
	# 如果不手动计算法线，可以取消注释下一行，但对于扁平环，手动指定更准确
	# st.generate_normals()
	# st.generate_tangents() # 如果使用法线贴图

	var new_mesh = st.commit()
	self.mesh = new_mesh # 应用到 MeshInstance3D

func _deferred_update_in_editor():
	# 如果setget没有完全覆盖所有情况，可以在这里强制刷新
	if mesh: # 确保mesh存在
		_generate_orbital_ring() # 重新生成，因为它依赖多个参数


# 可选：如果你希望在代码中改变属性后也自动更新
# 你需要为每个 @export var 定义 set 方法，如上面 radius, segments 等所示
# 并在 set 方法的末尾调用 _generate_orbital_ring() 或 _update_material()
