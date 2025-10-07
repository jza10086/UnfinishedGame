extends BoxContainer

var resource_label = preload("res://scenes/ui/components/resource_label.tscn")


# 设置资源容器信息（从BonusResource解析）
func set_resources(bonus_resource: BonusResource):
	"""
	解析BonusResource并为每个资源类型创建resource_label
	参数: bonus_resource - BonusResource实例
	"""
	if not bonus_resource:
		clear_resources()
		return
	
	# 清空现有的resource_label子节点
	clear_resources()
	
	# 获取所有资源类型并排序
	var resource_keys = bonus_resource.get_data_types()
	resource_keys.sort()
	
	# 为每个资源类型创建resource_label
	for resource_type in resource_keys:
		var final_value = bonus_resource.get_result(resource_type)
		
		# 跳过值为0的资源（可选）
		if final_value == 0:
			continue
		
		# 实例化resource_label
		var label_instance = resource_label.instantiate()
		
		# 设置resource_key
		label_instance.resource_key = resource_type
		
		# 获取来源信息
		var sources_dict = bonus_resource.get_sources(resource_type)
		
		# 构建resource_data字典
		var resource_data = {
			"value": final_value
		}
		
		# 如果有来源信息，添加到data中
		if sources_dict.size() > 0:
			resource_data["sources"] = sources_dict
		
		# 设置resource_label的信息
		label_instance.set_info(resource_data)
		
		# 添加到容器中
		add_child(label_instance)

# 清空所有resource_label子节点
func clear_resources():
	"""清空容器中的所有resource_label子节点"""
	for child in get_children():
		child.queue_free()
