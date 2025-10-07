@abstract
class_name JzaPanel
extends Control

@export var exit_button: Control

func exit() -> Node:
	GlobalNodes.UIManager.back_to_main()
	return self
@abstract
func init_panel(data)

func _ready() -> void:
	connect_signals()

@abstract
# 虚方法：清理和释放资源
func cleanup()


@abstract
# 虚方法：刷新界面内容
func refresh()

# 虚方法：连接信号
func connect_signals():
	exit_button.pressed.connect(exit)

@abstract
# 虚方法：断开信号
func disconnect_signals()
