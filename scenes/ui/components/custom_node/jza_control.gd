@tool
extends Control
class_name JzaControl

@export var texture: Texture : set = set_texture
@export var show_name: bool = true : set = set_show_name
@export var disabled: bool = false : set = set_disabled


func set_texture(value: Texture):
	texture = value
	_notify_parent_update()

func set_show_name(value: bool):
	show_name = value
	_notify_parent_update()

func set_disabled(value: bool):
	disabled = value
	_notify_parent_update()

func _notify_parent_update():
	# 通知父节点（如果是 JzaTabContainer）更新显示
	if get_parent() and get_parent() is JzaTabContainer:
		var parent_tab = get_parent() as JzaTabContainer
		parent_tab.call_deferred("refresh_tabs")

var test = GlobalConfig.ui_fade_time

# 渐隐动画的默认持续时间
var fade_duration: float = 0.0

# 渐隐动画的Tween实例
var fade_tween: Tween

## 执行渐隐效果，动画完成后隐藏控件
## @param duration: 渐隐动画持续时间，默认使用fade_duration
## @param ease_type: 缓动类型，默认为EASE_OUT
## @param trans_type: 过渡类型，默认为TRANS_QUART
func fade_out(duration: float = fade_duration, ease_type: Tween.EaseType = Tween.EASE_OUT, trans_type: Tween.TransitionType = Tween.TRANS_QUART):
	"""
	渐隐效果函数
	- duration: 动画持续时间，-1表示使用默认值
	- ease_type: 缓动类型
	- trans_type: 过渡类型
	"""
	
	# 停止之前的动画
	if fade_tween:
		fade_tween.kill()
	
	# 确保控件可见且透明度设置为起始状态
	show()
	
	# 创建新的Tween
	fade_tween = create_tween()
	
	# 设置渐隐动画：从当前modulate.a渐变到0
	fade_tween.tween_method(_update_fade_alpha, modulate.a, 0.0, duration)
	fade_tween.tween_callback(_on_fade_out_completed)
	
	# 设置缓动类型
	fade_tween.set_ease(ease_type)
	fade_tween.set_trans(trans_type)

## 执行渐现效果
## @param duration: 渐现动画持续时间，默认使用fade_duration
## @param ease_type: 缓动类型，默认为EASE_OUT
## @param trans_type: 过渡类型，默认为TRANS_QUART
func fade_in(duration: float = -1, ease_type: Tween.EaseType = Tween.EASE_OUT, trans_type: Tween.TransitionType = Tween.TRANS_QUART):
	"""
	渐现效果函数（作为渐隐的对应功能）
	- duration: 动画持续时间，-1表示使用默认值
	- ease_type: 缓动类型
	- trans_type: 过渡类型
	"""
	
	# 如果没有指定持续时间，使用默认值
	if duration < 0:
		duration = fade_duration
	
	# 停止之前的动画
	if fade_tween:
		fade_tween.kill()
	
	# 确保控件可见
	show()
	
	# 创建新的Tween
	fade_tween = create_tween()
	
	# 设置渐现动画：从当前modulate.a渐变到1
	fade_tween.tween_method(_update_fade_alpha, modulate.a, 1.0, duration)
	
	# 设置缓动类型
	fade_tween.set_ease(ease_type)
	fade_tween.set_trans(trans_type)

## 更新透明度的内部方法
## @param alpha: 新的透明度值
func _update_fade_alpha(alpha: float):
	modulate.a = alpha

## 渐隐动画完成后的回调
func _on_fade_out_completed():
	hide()
	print("JzaControl: 渐隐动画完成，控件已隐藏")

## 立即隐藏控件（无动画）
func instant_hide():
	if fade_tween:
		fade_tween.kill()
	hide()

## 立即显示控件（无动画，完全不透明）
func instant_show():
	if fade_tween:
		fade_tween.kill()
	modulate.a = 1.0
	show()
