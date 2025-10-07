extends Manager
@export var main_cam:Camera3D

# 追踪当前的tween动画
var current_tween: Tween
# 存储延迟的高度限制设置
var pending_height_limits: Dictionary = {}

func _ready() -> void:
	super._ready()


func get_camera() -> Node:
	return main_cam

func set_height_limit(min_height: float, max_height: float) -> void:
	"""设置相机的高度上限与下限"""
	if not main_cam:
		push_error("主相机未设置")
		return
	
	if min_height >= max_height:
		push_error("最小高度必须小于最大高度")
		return
	
	# 检查是否有正在运行的tween动画
	if current_tween and current_tween.is_valid():
		# 存储延迟的高度限制设置
		pending_height_limits = {
			"min_height": min_height,
			"max_height": max_height
		}

		return
	
	# 立即应用高度限制设置
	_apply_height_limits(min_height, max_height)

func _apply_height_limits(min_height: float, max_height: float) -> void:
	"""内部函数：应用高度限制设置"""
	# 设置相机的高度限制
	main_cam.min_camera_height = min_height
	main_cam.max_camera_height = max_height
	


func reset_height_limit() -> void:
	"""重置相机高度限制为默认值"""
	if not main_cam:
		push_error("主相机未设置")
		return
	
	# 使用main_cam中的默认值
	var default_min_height = main_cam.default_min_camera_height
	var default_max_height = main_cam.default_max_camera_height
	
	# 检查是否有正在运行的tween动画
	if current_tween and current_tween.is_valid():
		# 存储延迟的高度限制设置
		pending_height_limits = {
			"min_height": default_min_height,
			"max_height": default_max_height
		}
		print("CameraManager: Tween正在运行，延迟重置高度限制")
		return
	
	# 立即应用重置
	_apply_height_limits(default_min_height, default_max_height)
	
func focus(target_position: Vector3, auto_duration: bool = false, duration: float = 1.0, 
		   ease_type: int = Tween.EASE_OUT, trans_type: int = Tween.TRANS_EXPO) -> void:
	if not main_cam:
		push_error("主相机未设置")
		return
	
	# 如果有正在运行的tween，先停止它
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
		print("CameraManager: 取消之前的相机动画")
	
	var start_position = main_cam.global_position
	
	# 根据auto_duration参数决定是否使用智能时间计算
	var final_duration = duration
	if auto_duration:
		var distance = start_position.distance_to(target_position)
		final_duration = calculate_smooth_duration(distance, duration)
	
	# 创建新的Tween
	var tween = create_tween()
	tween.set_parallel(true)  # 允许并行动画
	
	# 存储当前tween引用
	current_tween = tween
	
	# 连接tween完成信号
	tween.finished.connect(_on_tween_finished)

	# 为相机位置创建tween动画
	tween.tween_property(main_cam, "global_position", target_position, final_duration).set_ease(
		ease_type).set_trans(trans_type)

	# 为目标高度创建tween动画
	tween.tween_method(Callable(main_cam, "set_target_height"), start_position.y, target_position.y, final_duration).set_ease(
		ease_type).set_trans(trans_type)
	
	print("CameraManager: 开始相机动画，目标位置: ", target_position, ", 持续时间: ", final_duration)


func _on_tween_finished() -> void:
	"""Tween动画完成后的回调函数"""
	
	# 清除当前tween引用
	current_tween = null
	
	# 检查是否有延迟的高度限制设置
	if pending_height_limits.has("min_height") and pending_height_limits.has("max_height"):
		_apply_height_limits(pending_height_limits["min_height"], pending_height_limits["max_height"])
		pending_height_limits.clear()
	

func calculate_smooth_duration(distance: float, _base_duration: float) -> float:
	"""根据距离平滑计算动画时间"""
	# 定义参数
	var min_distance = 20.0    # 最小考虑距离
	var max_distance = 200.0  # 最大考虑距离
	var min_duration = 0.5     # 最小动画时间
	var max_duration = 2.0     # 最大动画时间
	
	# 将距离映射到0-1范围
	var normalized_distance = clamp((distance - min_distance) / (max_distance - min_distance), 0.0, 1.0)
	
	# 使用平滑步函数让变化更自然
	var smooth_factor = smoothstep(0.0, 1.0, normalized_distance)
	
	# 插值计算最终时间
	return lerp(min_duration, max_duration, smooth_factor)
