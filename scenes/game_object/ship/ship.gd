extends Node3D
class_name Ship

# 信号定义 (Godot 4.x格式)
signal move_completed()  # 舰船移动完成信号

var main_weapon:Node
var hit_areas:Array
var health:float = 100.0
var atk:float = 50.0 
var def:float = 5.0
var ship_type:String = "battleship" # 舰船类型
var size:int = 1 # 占用舰队容量
var describe:String = "一艘强大的战列舰"
var current_stellar:String = "" # 当前所在恒星系
@onready var ModelContainer = $ModelContainer

# 资源
var ship_move_step_script = preload("res://scripts/visual_step/ship_move_step.gd")

# 射击特效场景预加载
var fire_scene: PackedScene = preload("res://assets/model/ships/lazer/lazer.tscn") # 射击特效场景

func set_basic_info(input_type:String):
	# 从ShipJsonLoader获取舰船类型数据
	var ship_data = ShipJsonLoader.get_ship_type(input_type)
	
	# 如果找不到舰船数据，使用默认值并输出错误
	if ship_data.is_empty():
		push_error("找不到舰船类型: " + input_type + "，使用默认属性")
		ship_type = input_type
		return
	
	# 设置舰船属性
	ship_type = ship_data["type"]
	describe = ship_data["describe"]
	health = ship_data["health"]
	atk = ship_data["atk"]
	def = ship_data["def"]
	self.scale = Vector3.ONE * ship_data["size"]
	# 自动创建3D模型
	if ship_data.has("model_path"):
		var ship_instance = create_model(ship_data["model_path"])
		var weapon_node = ship_instance.find_child("MainWeapon")
		main_weapon = weapon_node if weapon_node != null else self
		
		var hit_areas_container = ship_instance.find_child("HitAreas")
		if hit_areas_container != null and hit_areas_container.get_children().size() > 0:
			hit_areas = hit_areas_container.get_children()
		else:
			hit_areas = [self]  # 如果没有找到HitAreas容器或容器为空，使用self作为唯一的命中区域
		
func create_model(model_path:String) -> Node:
	var ship_scene = load(model_path)
	if ship_scene != null:
		var ship_instance = ship_scene.instantiate()
		ModelContainer.add_child(ship_instance)
		return ship_instance
	else:
		push_error("无法加载舰船模型: " + model_path)
		return



#region ship操作

func move_ship(target_position: Vector3, rotation_speed: float = 90.0, movement_speed: float = 50.0) -> void:
	# 创建移动动画步骤，传递速度参数
	var move_step = ship_move_step_script.new(self, target_position, rotation_speed, movement_speed)
	
	# 连接完成信号
	move_step.finished.connect(_on_move_step_finished)
	
	# 执行移动动画
	move_step.execute()

# 移动步骤完成回调
func _on_move_step_finished():
	print("Ship: 移动完成 - ", name)
	move_completed.emit()

func ship_fire(target: Vector3, scale_coeff: float = 1.0):
	# 1. 从池中请求一个激光实例
	var laser = VFXPool.get_laser()

	# 2. 将它添加到主场景中
	get_tree().current_scene.add_child(laser)

	# 3. 调用它的 shoot 方法，激活特效
	laser.shoot(main_weapon.global_position, target, scale_coeff)

func get_random_hit_area() -> Vector3:
	# 从hit_areas中随机选择一个节点，返回其全局位置
	if hit_areas.size() > 0:
		var hit_area_node = hit_areas[randi() % hit_areas.size()]
		return hit_area_node.global_position
	else:
		push_error("没有可用的命中区域")
		return global_position  # 如果没有命中区域，返回舰船自身的位置

#endregion
