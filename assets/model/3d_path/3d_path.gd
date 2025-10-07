extends Node3D

#这是一个依赖其他逻辑的vfx，采用管理者模式，由VFXManager进行管理

@onready var path_mesh: MeshInstance3D = $PathMesh
@onready var start_marker: Marker3D = $Start
@onready var end_marker: Marker3D = $End
@onready var arrow: MeshInstance3D = $End/Arrow

# 路径缩短距离（世界单位），从end向start方向缩短，避免与箭头重叠
# 这是一个绝对距离值，不是乘数
@export var path_end_offset: float = 36.0
# 通过两点坐标直接建立路径

func create_visual_path(start_position: Vector3, end_position: Vector3):
	start_marker.global_position = start_position
	end_marker.global_position = end_position
	update_path_mesh()

func update_path_mesh():
	if not path_mesh or not start_marker or not end_marker:
		return
	
	# 获取起点和终点位置
	var start_pos = start_marker.global_position
	var end_pos = end_marker.global_position
	
	# 计算从end到start的方向向量（在xz平面上）
	var direction_to_start = Vector3(start_pos.x - end_pos.x, 0, start_pos.z - end_pos.z)
	var full_distance = direction_to_start.length()
	
	if full_distance <= 0:
		return
	
	direction_to_start = direction_to_start.normalized()
	
	# 计算缩短后的路径长度（从end向start方向缩短path_end_offset距离）
	var shortened_distance = (full_distance - path_end_offset) / 2.0
	
	# 如果缩短后距离小于等于0，则不显示路径
	if shortened_distance <= 0:
		path_mesh.visible = false
		return
	else:
		path_mesh.visible = true
	
	# 计算PathMesh的位置：从end位置沿着向start方向平移path_end_offset距离
	var offset_position = end_pos + direction_to_start * path_end_offset
	path_mesh.global_position = offset_position
	
	# 计算旋转角度（绕y轴旋转）
	# z轴负方向指向start，所以需要计算从end到start的方向
	var angle = atan2(direction_to_start.x, direction_to_start.z)
	# 由于我们要让z轴负方向指向start，所以需要旋转180度
	path_mesh.rotation.y = angle + PI
	
	# 设置PathMesh的缩放，路径长度为缩短后的距离除以2
	# 假设原始mesh在z轴方向长度为1单位，从原点向z正方向延伸
	path_mesh.scale.z = shortened_distance
	
	# 更新箭头的旋转，使其指向正确方向
	if arrow:
		# 箭头应该指向路径方向（从start到end）
		var direction_to_end = Vector3(end_pos.x - start_pos.x, 0, end_pos.z - start_pos.z).normalized()
		var arrow_angle = atan2(direction_to_end.x, direction_to_end.z)
		arrow.rotation.y = arrow_angle
