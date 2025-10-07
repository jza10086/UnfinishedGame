extends Manager

@export var StellarContainer: Node

# 采样参数
@export var min_distance: float = 200.0    # 星系之间的最小间距
@export var max_points: int = 20         # 目标星系总数
@export var k: int = 30                   # 每个活跃点生成候选点的最大尝试次数

# 采样圆相关参数
@export var circle_origin: Vector3 = Vector3(0, 0, 0)
# 采样时默认二维圆中心为 (width/2, width/2)；转换到 3D 时先平移将圆心搬到原点，再加上 circle_origin 以调整实际世界位置

# 连接参数
@export var connection_distance: float = 400.0   # 两节点之间距离小于该值时建立初步连接
@export var min_connect: int = 1                # 每个节点至少应有的连接数
@export var max_connect: int = 5                # 每个节点最多允许的连接数
var current_width: float   # 当前采样区域直径（将根据目标数量动态调整）

@export var input_seed:int = -3883173113623033170


func generate_map_total():
	generate_map()
	visualize_stellar_connections() # 在生成地图后创建连线

func _ready() -> void:
	pass
	
# 生成地图数据，交由StellarManager接管
func generate_map() -> int:
	print("开始生成地图")
	
	# 重置unique恒星类型状态
	StellarJsonLoader.reset_unique_stellar_types()
	
	# 设置随机种子
	if input_seed != 0:
		print("使用指定种子:", input_seed)
		seed(input_seed)
	else:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		print("使用随机种子", rng.seed)
		seed(rng.seed)
	
	# --- 节点生成部分 ---
	# 根据 min_distance 与 max_points 推算理论上采样圆直径：width = min_distance * sqrt(max_points)
	var initial_width = min_distance * sqrt(max_points)
	current_width = initial_width
	var points: Array = generate_poisson_points(current_width)
	# 如果采样结果不足目标节点数，则逐步增大区域直径直至采样点数 >= max_points
	while points.size() < max_points:
		current_width *= 1.1  # 增大 10%
		points = generate_poisson_points(current_width)
	# 打乱数组后取前 max_points 个点，确保数量严格等于 max_points
	points.shuffle()
	points = points.slice(0, max_points)
	print("最终使用的点数: ", points.size())
	
	# 将二维采样点转换为 3D 坐标并创建恒星系
	var generated_count = 0
	
	# 创建所有恒星系
	print("开始创建恒星系，点数: ", points.size())
	for point in points:
		var world_pos: Vector3 = Vector3(point.x - current_width / 2, 0, point.y - current_width / 2) + circle_origin
		
		# 使用加权随机选择恒星类型
		var stellar_type = StellarJsonLoader.get_random_stellar_type()
		
		# 根据恒星类型获取合适的名称（unique类型会使用special_name，普通类型使用随机名称）
		var stellar_name = StellarJsonLoader.get_stellar_name_for_type(stellar_type, "stellar_names")
		
		# 创建恒星系
		var stellar = GlobalNodes.managers.StellarManager.create_stellar(stellar_name, world_pos, stellar_type)
		StellarContainer.add_child(stellar)
		generated_count += 1
		
	print("恒星系创建完成，总数: ", generated_count)
	
	# 输出unique恒星类型统计信息
	var unique_stats = StellarJsonLoader.get_unique_stellar_stats()
	print("Unique恒星类型统计:")
	print("  总unique类型数: ", unique_stats["total_unique_types"])
	print("  已生成数量: ", unique_stats["generated_unique_types"])
	print("  已生成列表: ", unique_stats["generated_list"])
	print("  待生成列表: ", unique_stats["pending_unique_types"])
	
	# --- 建立连接部分 ---
	connect_nodes()
	
	# 返回生成的恒星系数量
	return generated_count

# 使用 Poisson Disk Sampling 算法在二维采样空间 [0, the_width] 内生成圆形区域内的点集
func generate_poisson_points(the_width: float) -> Array:
	# 使用网格加速检测：cell_size = min_distance / √2
	var cell_size = min_distance / sqrt(2)
	var grid_width = int(ceil(the_width / cell_size))
	var grid_height = int(ceil(the_width / cell_size))
	
	# 构造二维网格（二维数组），初始值均为 null
	var grid: Array = []
	for i in range(grid_width):
		grid.append([])
		for j in range(grid_height):
			grid[i].append(null)
	
	var points: Array = []       # 存放采样得到的 Vector2 点
	var active_list: Array = []  # 活跃列表，候选点均从这里已有的点附近生成
	
	# 定义采样圆：圆心为 (the_width/2, the_width/2)，半径为 the_width/2
	var center: Vector2 = Vector2(the_width / 2, the_width / 2)
	var circle_radius: float = the_width / 2
	
	# 生成第一个初始点：使用极坐标在圆内随机均匀生成
	var angle = randf() * TAU
	var r = sqrt(randf()) * circle_radius
	var first_point: Vector2 = center + Vector2(cos(angle), sin(angle)) * r
	points.append(first_point)
	active_list.append(first_point)
	var grid_x = int(first_point.x / cell_size)
	var grid_y = int(first_point.y / cell_size)
	grid[grid_x][grid_y] = first_point
	
	# 主循环：从活跃列表中不断生成候选点
	var loop_count = 0
	while active_list.size() > 0:
		loop_count += 1
		var idx = randi() % active_list.size()
		var point: Vector2 = active_list[idx]
		var found = false
		for i in range(k):
			angle = randf() * TAU
			var radius = randf() * min_distance + min_distance
			var candidate: Vector2 = point + Vector2(cos(angle), sin(angle)) * radius
			# 判断候选点是否位于采样圆内且在 [0, the_width] 区间内
			if candidate.distance_to(center) < circle_radius and candidate.x >= 0 and candidate.x < the_width and candidate.y >= 0 and candidate.y < the_width:
				grid_x = int(candidate.x / cell_size)
				grid_y = int(candidate.y / cell_size)
				var ok = true
				# 检查周围网格中是否有点距离该候选点小于 min_distance
				for ix in range(max(0, grid_x - 2), min(grid_width, grid_x + 3)):
					for iy in range(max(0, grid_y - 2), min(grid_height, grid_y + 3)):
						if grid[ix][iy] != null:
							if grid[ix][iy].distance_to(candidate) < min_distance:
								ok = false
								break
					if not ok:
						break
				if ok:
					points.append(candidate)
					active_list.append(candidate)
					grid[grid_x][grid_y] = candidate
					found = true
					break
		if not found:
			active_list.remove_at(idx)
	
	print("泊松采样完成，生成点数: ", points.size(), ", 循环执行次数: ", loop_count)		
	return points

#region 连接相关
# 根据StellarManager中的恒星系建立连接关系。
# 规则：
#   第一轮：若两节点之间距离 <= connection_distance，
#            且双方连接数均低于 max_connect，则建立双向连接。
#   第二轮：对于每个没有任何连接的节点，
#            找到最近的未达到max_connect的节点并建立连接（忽略距离限制）。
func connect_nodes() -> void:
	# 获取所有恒星系名称
	var stellar_names = GlobalNodes.managers.StellarManager.stellars.keys()
	var n: int = stellar_names.size()
	
	# 第一轮：按照距离限制建立连接
	print("开始第一轮连接...")
	for i in range(n):
		for j in range(i + 1, n):
			var name_a = stellar_names[i]
			var name_b = stellar_names[j]
			var stellar_a = GlobalNodes.managers.StellarManager.stellars[name_a]
			var stellar_b = GlobalNodes.managers.StellarManager.stellars[name_b]
			var d: float = stellar_a.position.distance_to(stellar_b.position)
			
			if d <= connection_distance:
				# 检查两个恒星系的连接数
				if stellar_a.stellar_connections.size() < max_connect and stellar_b.stellar_connections.size() < max_connect:
					# 建立双向连接（调用两次单向连接）
					GlobalNodes.managers.StellarManager.connect_stellars(stellar_a, stellar_b, 1)
					GlobalNodes.managers.StellarManager.connect_stellars(stellar_b, stellar_a, 1)
	
	# 第二轮：确保每个孤立节点都有至少一个连接
	print("开始第二轮连接...")
	for stellar_name in stellar_names:
		var stellar = GlobalNodes.managers.StellarManager.stellars[stellar_name]
		
		# 如果当前恒星系没有任何连接
		if stellar.stellar_connections.size() == 0:
			var candidates: Array = []
			print("发现孤立恒星系: ", stellar_name)
			
			# 收集所有可能的连接目标（无视最大连接数限制）
			for other_name in stellar_names:
				if other_name != stellar_name:
					var other_stellar = GlobalNodes.StellarManager.stellars[other_name]
					# 无视连线限制，直接添加所有其他恒星系作为候选
					candidates.append({
						"name": other_name,
						"stellar": other_stellar,
						"distance": stellar.position.distance_to(other_stellar.position)
					})
			
			if candidates.size() > 0:
				# 按距离从近到远排序
				candidates.sort_custom(Callable(self, "_compare_distance"))
				var nearest = candidates[0]
				
				# 建立与最近的恒星系的双向连接（无视连接数上限）
				GlobalNodes.StellarManager.connect_stellars(stellar, nearest["stellar"], 1)
				GlobalNodes.StellarManager.connect_stellars(nearest["stellar"], stellar, 1)
				print("为孤立恒星系建立连接: ", stellar_name, " <-> ", nearest["name"], " (距离: ", nearest["distance"], "，无视连接数限制)")
			else:
				print("警告：无法为孤立恒星系找到连接目标: ", stellar_name)
		# while 循环结束
	# for 循环结束
	print("连接完成")

# 创建一根连接两点的线段网格
func create_line(start_pos: Vector3, end_pos: Vector3) -> MeshInstance3D:
	# 创建一个立即网格
	var im = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1, 1, 1, 0.5) # 半透明白色
	
	# 绘制线段
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(start_pos)
	im.surface_add_vertex(end_pos)
	im.surface_end()
	
	# 创建网格实例并设置材质
	var mi = MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = material
	
	return mi

# 根据StellarManager中恒星系的连接关系创建可视化连线
func visualize_stellar_connections() -> void:
	# 新建一个用于存放所有连线的父节点
	var lines_parent: Node3D = Node3D.new()
	lines_parent.name = "ConnectionLines"
	StellarContainer.add_child(lines_parent)
	
	# 遍历所有恒星系及其连接
	for stellar_name in GlobalNodes.managers.StellarManager.stellars.keys():
		var stellar = GlobalNodes.managers.StellarManager.stellars[stellar_name]
		for connection_name in stellar.stellar_connections.keys():
			var other_stellar = GlobalNodes.managers.StellarManager.stellars[connection_name]
			# 只为instance_id较小的节点创建连线，避免重复
			if stellar.get_instance_id() < other_stellar.get_instance_id():
				var line_instance = create_line(stellar.position, other_stellar.position)
				lines_parent.add_child(line_instance)

# 自定义排序函数，用于按照候选字典中 "distance" 值从小到大排序
func _compare_distance(a: Dictionary, b: Dictionary) -> bool:
	# 在Godot的sort_custom中，返回true表示a应该排在b前面
	# 我们希望距离小的排在前面，所以当a的距离小于b时返回true
	return a["distance"] < b["distance"]

#endregion
