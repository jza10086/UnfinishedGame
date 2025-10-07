extends VisualStepBase
class_name ShipMoveStep

var ship_node: Node3D
var target_pos: Vector3
var description: String

# 移动速度参数
var rotation_speed: float  # 度/秒
var movement_speed: float  # 单位/秒

func _init(p_ship_node: Node3D, p_target_pos: Vector3, p_rotation_speed: float = 120.0, p_movement_speed: float = 100.0):
	self.ship_node = p_ship_node
	self.target_pos = p_target_pos
	self.rotation_speed = p_rotation_speed
	self.movement_speed = p_movement_speed
	self.description = "Move Ship %s to position" % ship_node.name

# 主执行函数：先旋转，后平移
func execute():
	if not is_instance_valid(ship_node):
		emit_signal("finished")
		return
	
	# 1. 先旋转朝向目标方向
	await _rotate_to_target()
	
	# 2. 再平移到目标位置
	await _move_to_target()
	
	# 3. 完成所有动画
	emit_signal("finished")

# 旋转朝向目标方向（x+轴指向目标）
func _rotate_to_target():
	# 计算目标方向向量（在xz平面上）
	var current_pos = ship_node.global_position
	var direction = target_pos - current_pos
	direction.y = 0  # 忽略y轴差异，保持在xz平面
	
	# 如果距离太近，跳过旋转
	if direction.length() < 0.01:
		return
	
	direction = direction.normalized()
	
	# 计算目标旋转角度（x+轴指向目标方向）
	var target_rotation_y = atan2(-direction.z, direction.x)
	var target_quat = Quaternion.from_euler(Vector3(0, target_rotation_y, 0))
	
	# 计算需要旋转的角度和时间
	var current_quat = ship_node.quaternion
	var angle_diff = current_quat.angle_to(target_quat)
	
	# 如果角度差异很小，跳过旋转
	if angle_diff < 0.01:
		return
	
	var duration = angle_diff / deg_to_rad(rotation_speed)
	
	# 执行旋转动画
	await _animate_quaternion(target_quat, duration)

# 平移到目标位置
func _move_to_target():
	var current_pos = ship_node.global_position
	var distance = current_pos.distance_to(target_pos)
	
	# 如果距离太近，跳过移动
	if distance < 0.01:
		return
	
	var duration = distance / movement_speed
	
	# 执行平移动画
	await _animate_position(target_pos, duration)

# 动画四元数旋转
func _animate_quaternion(target_quat: Quaternion, duration: float):
	if duration <= 0:
		ship_node.quaternion = target_quat
		return
	
	var tween = ship_node.create_tween()
	if not tween:
		ship_node.quaternion = target_quat
		return
	
	tween.tween_property(ship_node, "quaternion", target_quat, duration)
	await tween.finished

# 动画位置移动
func _animate_position(target_position: Vector3, duration: float):
	if duration <= 0:
		ship_node.global_position = target_position
		return
	
	var tween = ship_node.create_tween()
	if not tween:
		ship_node.global_position = target_position
		return
	
	tween.tween_property(ship_node, "global_position", target_position, duration)
	await tween.finished
