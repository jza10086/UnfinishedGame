# 可视步骤的基类，定义了所有步骤必须拥有的接口。
class_name VisualStepBase
extends RefCounted

# 每个步骤执行完毕后，必须发出此信号。
signal finished

# 执行此步骤的核心逻辑。
# 这是一个虚方法，子类必须重写它。
func execute():
	# 使用 assert 确保任何忘记重写此方法的子类都会在调试时报错。
	assert(false, "子类必须重写 execute() 方法")

func _on_finished():
	assert(false, "子类必须重写 _on_finished() 方法")
	emit_signal("finished")
