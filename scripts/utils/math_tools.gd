@tool
class_name MathTools


# 罗马数字转换
static func roman_num(num: int) -> String:
	if num == 0:
		return ""
	elif num < 1 or num > 3999:
		push_error("输入数据无效，无法转换为罗马数字")
		return "N/A"
		
	var roman_values = [
		[1000, "M"],
		[900, "CM"],
		[500, "D"],
		[400, "CD"],
		[100, "C"],
		[90, "XC"],
		[50, "L"],
		[40, "XL"],
		[10, "X"],
		[9, "IX"],
		[5, "V"],
		[4, "IV"],
		[1, "I"]
	]
	
	var result = ""
	var number = num
	
	for value in roman_values:
		while number >= value[0]:
			result += value[1]
			number -= value[0]
	
	return result

# 按权重随机选择
static func weight_rand(item_weights: Dictionary) -> Variant:
	if item_weights.is_empty():
		return null
	
	# 过滤并计算总权重（跳过权重<=0的项）
	var valid_items: Dictionary = {}
	var total_weight = 0.0
	for item in item_weights:
		var weight = item_weights[item]
		if weight > 0:
			valid_items[item] = weight
			total_weight += weight
	
	if valid_items.is_empty() or total_weight <= 0:
		return null
	
	# 生成随机数
	var random_value = randf() * total_weight
	
	# 找到对应的项目
	var cumulative_weight = 0.0
	for item in valid_items:
		cumulative_weight += valid_items[item]
		if random_value <= cumulative_weight:
			return item
	
	# 如果没有找到，返回最后一个
	push_error("权重随机选择出现异常，返回最后一个项目")
	return valid_items.keys()[-1]

# 使用Dijkstra算法计算图中两点间的最短距离和路径
# graph: 邻接表字典，格式为 {node_id: {neighbor_id: distance, ...}, ...}
# start: 起点节点标识符（可以是任意类型：String, int, 等）
# end: 终点节点标识符（可以是任意类型：String, int, 等）
# 返回: 字典 {distance: int, path: Array}，如果无法到达返回 {distance: -1, path: []}
static func dijkstra(graph: Dictionary, start: Variant, end: Variant) -> Dictionary:
	# 检查起点和终点是否存在
	if not graph.has(start) or not graph.has(end):
		push_error("Dijkstra算法：起点或终点不存在于图中")
		return {"distance": -1, "path": []}
	
	# 如果起点和终点相同，距离为0
	if start == end:
		return {"distance": 0, "path": [start]}
	
	# 初始化Dijkstra算法所需的数据结构
	var distances: Dictionary = {}  # 存储到各个节点的最短距离
	var visited: Dictionary = {}    # 标记已访问的节点
	var previous: Dictionary = {}   # 存储每个节点的前驱节点，用于路径重建
	var unvisited: Array = []       # 未访问的节点列表
	
	# 初始化所有节点的距离为无穷大
	for node_id in graph:
		distances[node_id] = INF
		visited[node_id] = false
		previous[node_id] = null  # 使用null代替空字符串，支持任意类型
		unvisited.append(node_id)
	
	# 起始节点的距离设为0
	distances[start] = 0
	
	# Dijkstra算法主循环
	while unvisited.size() > 0:
		# 找到未访问中距离最小的节点
		var current_node = null
		var min_distance = INF
		
		for node_id in unvisited:
			if distances[node_id] < min_distance:
				min_distance = distances[node_id]
				current_node = node_id
		
		# 如果找不到可达的节点，说明图不连通
		if min_distance == INF:
			break
		
		# 标记当前节点为已访问
		visited[current_node] = true
		unvisited.erase(current_node)
		
		# 如果已经到达目标节点，可以提前结束
		if current_node == end:
			break
		
		# 更新相邻节点的距离
		var connections = graph[current_node]
		for neighbor_id in connections:
			if not visited[neighbor_id]:
				var edge_distance = connections[neighbor_id]
				var new_distance = distances[current_node] + edge_distance
				
				if new_distance < distances[neighbor_id]:
					distances[neighbor_id] = new_distance
					previous[neighbor_id] = current_node  # 记录前驱节点
	
	# 重建路径
	var path: Array = []
	var result_distance = distances[end]
	
	if result_distance == INF:
		return {"distance": -1, "path": []}  # 表示无法到达
	else:
		# 从终点回溯到起点构建路径
		var current = end
		while current != null:
			path.push_front(current)
			current = previous[current]
		
		return {"distance": int(result_distance), "path": path}

# 格式化数值显示（支持K、M、B单位）
static func format_number(amount: float) -> String:
	var abs_amount = abs(amount)
	var sign_prefix = "-" if amount < 0 else ""
	
	if abs_amount >= 1000000000:  # 10亿以上用B
		return sign_prefix + "%.1fB" % (abs_amount / 1000000000.0)
	elif abs_amount >= 1000000:  # 100万以上用M
		return sign_prefix + "%.1fM" % (abs_amount / 1000000.0)
	elif abs_amount >= 1000:     # 1000以上用k
		return sign_prefix + "%.1fk" % (abs_amount / 1000.0)
	else:                        # 1000以下保留1位小数
		return sign_prefix + "%.1f" % abs_amount

# 六边形坐标系相关常量和函数
const HEX_WALK_DIRECTIONS = [
	Vector3i(-1, 0, 1),
	Vector3i(0, -1, 1),
	Vector3i(1, -1, 0),
	Vector3i(1, 0, -1),
	Vector3i(0, 1, -1),
	Vector3i(-1, 1, 0)
]

# 根据target_tile_count智能生成六边形瓦片坐标
static func generate_hex_tile_coords_by_count(target_tile_count: int) -> Array[Vector2i]:
	if target_tile_count <= 0:
		push_error("target_tile_count 必须大于 0")
		return []
	
	var generated_coords: Array[Vector2i] = []
	var current_layer = 0
	
	while generated_coords.size() < target_tile_count:
		var current_layer_coords = get_hex_ring_coords(current_layer)
		var remaining_count = target_tile_count - generated_coords.size()
		
		if remaining_count >= current_layer_coords.size():
			generated_coords.append_array(current_layer_coords)
			current_layer += 1
		else:
			current_layer_coords.shuffle()
			var selected_coords = current_layer_coords.slice(0, remaining_count)
			generated_coords.append_array(selected_coords)
			break
	
	return generated_coords

# 生成指定半径(环)上的所有六边形格子的坐标
static func get_hex_ring_coords(radius: int) -> Array[Vector2i]:
	if radius == 0:
		return [Vector2i.ZERO]

	var ring_coords: Array[Vector2i] = []
	var cube_coord = Vector3i(0, radius, -radius)

	for i in range(6):
		for _j in range(radius):
			ring_coords.append(cube_to_hex_coord(cube_coord))
			cube_coord += HEX_WALK_DIRECTIONS[i]
			
	return ring_coords

# 将立方体坐标转换为六边形用户坐标
static func cube_to_hex_coord(cube: Vector3i) -> Vector2i:
	var u = cube.x
	var v = -cube.z
	return Vector2i(u, v)

# 将六边形用户坐标转换为立方体坐标
static func hex_coord_to_cube(hex_coord: Vector2i) -> Vector3i:
	var x = hex_coord.x
	var z = -hex_coord.y
	var y = -x - z
	return Vector3i(x, y, z)

# 比较两组资源字典，检查已有资源是否满足所需资源
# 参数：available_resources - 已有资源字典 {GlobalEnum.ResourceType: amount, ...}
# 参数：required_resources - 所需资源字典 {GlobalEnum.ResourceType: amount, ...}
# 返回：Array - [bool, Dictionary]
#   - 如果资源足够：[true, remaining_resources] - remaining_resources为扣除所需资源后的剩余资源
#   - 如果资源不足：[false, missing_resources] - missing_resources为缺少的资源字典
static func compare_resources(available_resources: Dictionary, required_resources: Dictionary) -> Array:
	var missing_resources: Dictionary = {}
	var remaining_resources: Dictionary = available_resources.duplicate()
	var has_sufficient_resources = true
	
	# 遍历所有所需资源
	for resource_type in required_resources:
		var required_amount = required_resources[resource_type]
		var available_amount = available_resources.get(resource_type, 0.0)
		
		# 检查资源是否足够
		if available_amount < required_amount:
			# 记录缺少的资源数量
			missing_resources[resource_type] = required_amount - available_amount
			has_sufficient_resources = false
		else:
			# 计算剩余资源
			remaining_resources[resource_type] = available_amount - required_amount
	
	# 根据结果返回相应的数据
	if has_sufficient_resources:
		return [true, remaining_resources]
	else:
		return [false, missing_resources]

# 按Key排序字典，返回新的有序字典
# 参数：input_dict - 输入的字典
# 返回：Dictionary - 按Key排序后的新字典
static func sort_dictionary_by_key(input_dict: Dictionary) -> Dictionary:
	if input_dict.is_empty():
		return {}
	
	# 获取所有键并排序
	var keys: Array = input_dict.keys()
	keys.sort()
	
	# 构建排序后的新字典
	var sorted_dict: Dictionary = {}
	for key in keys:
		sorted_dict[key] = input_dict[key]
	
	return sorted_dict

