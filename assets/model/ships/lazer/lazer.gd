extends Node3D

#这是一个一次性vfx，采用射后不管模式，自行销毁


@onready var lazer_mesh: MeshInstance3D = $MeshInstance3D
@onready var animation_player = $AnimationPlayer
func shoot(start_pos: Vector3, end_pos: Vector3, scale_coeff: float):
	if lazer_mesh:
		
		# 计算方向和距离
		var direction = end_pos - start_pos
		var distance = direction.length()
		
		# 计算旋转：让激光束指向目标
		if distance > 0:
			# 手动计算旋转，让Y轴指向目标方向
			var direction_normalized = direction.normalized()
			# 创建变换矩阵，让Y轴指向目标
			var up = Vector3.UP
			# 如果方向和UP向量平行，使用FORWARD作为参考
			if abs(direction_normalized.dot(up)) > 0.99:
				up = Vector3.FORWARD
			
			# 计算正交基向量
			var right = direction_normalized.cross(up).normalized()
			var forward = right.cross(direction_normalized).normalized()
			
			# 设置变换矩阵 (right, direction, forward)
			lazer_mesh.transform.basis = Basis(right, direction_normalized, forward)
			
			# 调整起点：如果原始mesh的Y轴范围是[-1,1]，需要偏移到起点
			# 将激光束的起点移动到start_pos，而不是中心
			lazer_mesh.transform.origin = start_pos + direction_normalized * (distance * 0.5)
		
		# 缩放激光束：Y轴缩放为距离的一半，因为原始mesh范围是[-1,1]
		lazer_mesh.scale = Vector3(1.0, distance * 0.5, 1.0)
	
		# 同时设置shader参数（如果需要的话）
		var material = lazer_mesh.get_surface_override_material(0)
		if not material:
			print("警告: 激光特效没有独立材质，可能会导致材质共享问题")
			material = lazer_mesh.mesh.surface_get_material(0)
		
		if material:
			material.set_shader_parameter("beam_width_coeff",scale_coeff)
		
		animation_player.play("lazer_animation")
		await animation_player.animation_finished
		material.set_shader_parameter("beam_width_coeff",1.0)
		VFXPool.return_laser(self)
	else:
		print("激光特效未能成功发射")
