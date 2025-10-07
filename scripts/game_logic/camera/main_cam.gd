extends Camera3D

# StateManager相关
var camera_id: String = "main_camera"  # 相机唯一标识符
@export var CamCentreTarget:Node3D
# 天空着色器相关
var world_environment: WorldEnvironment = null

# 基础移动速度相关参数(可在编辑器中调整)
@export_group("移动速度设置")
@export var base_move_speed: float = 5000.0  # 基础移动速度（单位：单位/秒）
@export var base_scroll_speed: float = 30000.0  # 基础滚轮速度（单位：单位/秒）
@export var base_drag_speed: float = 5  # 基础拖动速度（单位：单位/像素）

# 滚轮平滑相关参数
var target_height: float = 0.0  # 目标高度
@export_group("平滑设置")
@export var height_smoothing: float = 5.0  # 平滑系数，值越大过渡越快
@export var wheel_step: float = 200.0  # 每次滚轮滚动的高度变化值
@export var ease_out_threshold: float = 0.1  # 接近目标时的临界值

@export_group("高度与速度关系设置")
# 指数系数，控制速度随高度变化的程度
@export var speed_exponent: float = 1
# 基础系数，控制基础速度倍率
@export var base_factor: float = 1.0

@export_group("相机移动范围设置")

# 定义相机高度的范围，决定视角转换区间
@export var min_camera_height: float = 2.5   # 相机最低y
@export var max_camera_height: float = 3500.0  # 相机最高y

# 默认高度范围，用于速度计算等动态调整功能
var default_min_camera_height: float = 2.5
var default_max_camera_height: float = 3500.0


@export_group("相机旋转设置")
@export var min_x_rotation: float = -90.0  # 最小X轴旋转角度（以度为单位）
@export var max_x_rotation: float = -45.0    # 最大X轴旋转角度（以度为单位）



# 定义相机在XZ平面的移动范围
@export var min_camera_x: float = -3000.0  # 相机最小x坐标
@export var max_camera_x: float = 3000.0   # 相机最大x坐标
@export var min_camera_z: float = -3000.0  # 相机最小z坐标
@export var max_camera_z: float = 3000.0   # 相机最大z坐标

# 根据当前高度计算速度修正系数
func calculate_speed_factor() -> float:
	# 使用默认高度范围计算高度比例（0到1之间）
	var height_ratio: float = (position.y - default_min_camera_height) / (default_max_camera_height - default_min_camera_height)
	# 确保比例在有效范围内
	height_ratio = clamp(height_ratio, 0.01, 1.0)
	# 应用指数关系: base_factor * height_ratio^exponent
	return base_factor * pow(height_ratio, speed_exponent)

func _ready() -> void:
	# 初始化目标高度为当前相机高度
	target_height = position.y
	
	# 初始化默认高度范围（保存编辑器中设置的原始值）
	default_min_camera_height = min_camera_height
	default_max_camera_height = max_camera_height

	# 查找WorldEnvironment节点
	var main_game = get_node("../../..")  # 向上导航到MainGame节点
	if main_game:
		world_environment = main_game.get_node("Background/WorldEnvironment")
		if not world_environment:
			print("警告: 无法找到WorldEnvironment节点")

# 设置目标高度的方法，供外部调用
func set_target_height(new_height: float) -> void:
	target_height = clamp(new_height, min_camera_height, max_camera_height)

func _process(delta: float) -> void:
	# 计算当前高度下的速度修正系数
	var speed_factor: float = calculate_speed_factor()
	
	# 处理 WASD 控制的水平移动（XZ 平面）
	var horizontal_movement: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("camera_move_up"):
		horizontal_movement.z -= 1   # 向前（屏幕上方）
	if Input.is_action_pressed("camera_move_down"):
		horizontal_movement.z += 1   # 向后（屏幕下方）
	if Input.is_action_pressed("camera_move_left"):
		horizontal_movement.x -= 1   # 向左
	if Input.is_action_pressed("camera_move_right"):
		horizontal_movement.x += 1   # 向右

	if horizontal_movement != Vector3.ZERO:
		# 应用速度修正系数
		horizontal_movement = horizontal_movement.normalized() * base_move_speed * speed_factor * delta
		
	# 应用平滑高度过渡
	if target_height != 0 and abs(position.y - target_height) > ease_out_threshold:
		# 使用插值实现平滑过渡，lerp 是线性插值函数
		position.y = lerp(position.y, target_height, delta * height_smoothing)

	# 处理 Y 轴的移动（键盘滚轮或其他按键映射控制）
	var vertical_movement: float = 0.0
	# 我们不再使用 is_action_just_pressed，而是使用滚轮事件的增量值
	# 这部分的滚轮逻辑移到 _input 函数中，实现更平滑的滚动

	# 更新相机在 XZ 和 Y 轴上的位置
	position += Vector3(horizontal_movement.x, vertical_movement, horizontal_movement.z)

	# 限制相机位置在预定范围内（XYZ三个轴）
	position.x = clamp(position.x, min_camera_x, max_camera_x)
	position.y = clamp(position.y, min_camera_height, max_camera_height)
	position.z = clamp(position.z, min_camera_z, max_camera_z)
	var child = CamCentreTarget  # 获取子节点
	var parent_transform = global_transform
	var child_transform = child.global_transform
	# 只允许父级节点的 X 轴影响子节点
	child_transform.origin.x = parent_transform.origin.x
	child_transform.origin.z = parent_transform.origin.z - 10
	child.global_transform = child_transform
	# 保持子节点其他轴不受影响

	# 先让相机朝向目标点
	look_at(CamCentreTarget.global_transform.origin)
	
	# 应用X轴旋转角度限制
	var current_rotation = rotation_degrees
	current_rotation.x = clamp(current_rotation.x, min_x_rotation, max_x_rotation)
	rotation_degrees = current_rotation
	
	# 更新天空着色器的相机位置参数
	update_sky_shader_camera_position()
	
func _input(event):
	# 按键映射 "camera_move_mouse_middle" 用于拖动操作
	# 当鼠标移动时，并且输入映射 "camera_move_mouse" 被按下，
	# 则将鼠标的相对位移转为在 XZ 平面上的移动
	if event is InputEventMouseMotion and Input.is_action_pressed("camera_move_mouse"):
		# 计算当前高度下的速度修正系数
		var speed_factor: float = calculate_speed_factor()
		var delta_mouse: Vector2 = event.relative
		# 应用速度修正系数到拖动速度
		var move_vector: Vector3 = Vector3(-delta_mouse.x * base_drag_speed * speed_factor, 0, -delta_mouse.y * base_drag_speed * speed_factor)
		position += move_vector
		
		# 限制相机位置在预定范围内（XZ平面）
		position.x = clamp(position.x, min_camera_x, max_camera_x)
		position.z = clamp(position.z, min_camera_z, max_camera_z)
	
	# 处理鼠标滚轮事件，实现平滑缩放
	elif event is InputEventMouseButton:
		# 检查是否是滚轮操作
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# 计算当前高度下的速度修正系数
			var speed_factor: float = calculate_speed_factor()
			
			# 初始化目标高度（如果尚未设置）
			if target_height == 0:
				target_height = position.y
			
			# 根据滚轮方向调整目标高度
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# 向上滚动，缩小（降低高度）
				target_height -= wheel_step * speed_factor  # 使用可配置的滚轮步进值
			else:  # MOUSE_BUTTON_WHEEL_DOWN
				# 向下滚动，放大（增加高度）
				target_height += wheel_step * speed_factor  # 使用可配置的滚轮步进值
			
			# 限制目标高度在允许范围内
			target_height = clamp(target_height, min_camera_height, max_camera_height)

# 更新天空着色器的相机位置参数
func update_sky_shader_camera_position() -> void:
	if world_environment and world_environment.environment and world_environment.environment.sky and world_environment.environment.sky.sky_material:
		# 只使用X和Z轴位置，忽略Y轴（高度）影响
		var horizontal_position = Vector3(position.x, 0.0, position.z)
		# 设置天空着色器的相机位置参数
		world_environment.environment.sky.sky_material.set_shader_parameter("camera_position", horizontal_position)
