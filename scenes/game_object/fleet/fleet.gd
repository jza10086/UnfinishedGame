class_name Fleet
extends Unit

# 唯一标识符
var fleet_id: int = -1  # 6位数ID，由FleetManager分配

# 所有权信息
var owner_faction: int = -1  # 所属阵营ID，-1表示无主

# 基础属性
var move_point: int = 2
var fleet_height: float = 10.0  # 舰队高度偏移

# 节点引用
@onready var fleet_sprite = $Sprite3D
@onready var ShipContainer = $ShipContainer
@onready var fleet_collision_shape = $FleetCollisionShape

# 资源
var ship_scene: PackedScene = preload("res://scenes/game_object/ship/ship.tscn")

# 位置和移动状态
var current_stellar_id: int = -1  # 当前恒星系ID
var target_stellar_id: int = -1  # 目标恒星系ID
var target_position: Vector3

var moving_pos_path: Array = []  # 用于存储移动路径点

# 舰船管理
var ships: Array = []

# 排列配置
var ships_per_column: int = 3
var ship_spacing: float = 5.0

func _init() -> void:
	unit_type = GlobalEnum.UnitType.FLEET





# 所有权管理方法
func set_faction_owner(faction_id: int):
	"""设置舰队所有者"""
	owner_faction = faction_id

func get_faction_owner() -> int:
	"""获取舰队所有者，-1表示无主"""
	return owner_faction


func _ready() -> void:
	super._ready()



func create_ship(ship_type: String) -> Node3D:
	var ship_instance = ship_scene.instantiate()
	ShipContainer.add_child(ship_instance)
	ship_instance.set_basic_info(ship_type)
	
	# 设置Ship的初始世界位置为Fleet的位置
	# 由于Ship是top_level节点，需要显式设置其世界坐标
	ship_instance.global_position = self.global_position
	
	ships.append(ship_instance)
	return ship_instance


#region fleet移动
# 执行单步移动 - 使用 moving_pos_path 中的第一个点作为目标
func fleet_move(queue_num) -> bool:
	if moving_pos_path.is_empty():
		return false
	# 移除已完成的路径点
	target_position = moving_pos_path[0]
	apply_animation(queue_num)
	moving_pos_path.remove_at(0)
	print("Fleet: 单步移动完成","剩余移动队列：",moving_pos_path)
	return true

func set_current_stellar_id(stellar_id: int):
	current_stellar_id = stellar_id

func get_current_stellar_id() -> int:
	return current_stellar_id

func get_current_stellar() -> int:
	# 返回当前恒星系ID
	return current_stellar_id

func set_target_stellar_id(stellar_id: int):
	target_stellar_id = stellar_id

func apply_animation(queue_num):
	var fleet_move_step = FleetMoveStep.new(self,target_position)
	AnimationSequencer.add_animation(fleet_move_step,queue_num)

#endregion

#region fleet射击

func fleet_fire(target_fleet):
	if not _validate_fire_target(target_fleet):
		return
	
	print("舰队开始射击，舰船数量: ", ships.size(), " 目标舰队舰船数量: ", target_fleet.ships.size())
	
	for ship in ships:
		var target_ship = target_fleet.ships[randi() % target_fleet.ships.size()]
		var target_hit_position = target_ship.get_random_hit_area()
		ship.ship_fire(target_hit_position)
	
	print("舰队射击完成")

func _validate_fire_target(target_fleet) -> bool:
	if target_fleet == null:
		push_error("目标舰队为空")
		return false
	
	if target_fleet.ships.size() == 0:
		print("目标舰队没有舰船")
		return false
	
	if ships.size() == 0:
		print("当前舰队没有舰船")
		return false
	
	return true

#endregion
	
#region UI 显示

func update_sprite_scale():
	var camera = GlobalNodes.managers.CameraManager.get_camera()
	var camera_y = camera.global_position.y
	var scale_factor = camera_y * 1.5 / 50.0 / 7.5
	var clamped_scale = clamp(scale_factor, 3.0 / 7.5, 12.0 / 7.5)
	var scale_vector = Vector3(clamped_scale, clamped_scale, clamped_scale)
	
	# 统一缩放所有组件
	fleet_sprite.scale = scale_vector
	fleet_collision_shape.scale = scale_vector
	preview_model.scale = scale_vector
	highlight_model.scale = scale_vector * 4.4
	
	# 计算并设置透明度
	var alpha_value = 1.0
	if scale_factor < 3.0 / 7.5:
		alpha_value = 1.0 - remap(scale_factor, 2.0 / 7.5, 3.0 / 7.5, 1.0, 0.0)
	
	_update_component_alpha(alpha_value)

func _update_component_alpha(alpha_value: float):
	fleet_sprite.modulate.a = alpha_value
	
	if preview_model:
		var material = preview_model.mesh.surface_get_material(0)
		if material:
			var base_alpha = 45.0 / 255.0
			var final_alpha = clamp(base_alpha * alpha_value, 0.0, 1.0)
			material.albedo_color.a = final_alpha
	
		# 为highlight_model设置材质透明度（同样的逻辑和参数）
	if highlight_model and is_selected:
		var base_alpha = 255.0 / 255.0  # 基础透明度值
		# 直接从mesh获取材质
		var material = highlight_model.mesh.surface_get_material(0)
		
		if material:
			# 将计算出的alpha_value映射到基础透明度上
			var final_alpha = base_alpha * alpha_value
			final_alpha = clamp(final_alpha, 0.0, 1.0)  # 钳制alpha值在0-1之间
			material.albedo_color.a = final_alpha

#endregion

#region 外部调用
func _check_fleet_moveable():
	if moving_pos_path.is_empty():
		return false
	return true
