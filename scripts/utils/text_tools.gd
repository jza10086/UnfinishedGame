@tool
class_name TextTools

# 颜色相关的BBCode格式化函数

## 将文本包装为指定颜色名称的BBCode格式
static func colorize(text: String, color_name: String) -> String:
	return "[color=%s]%s[/color]" % [color_name, text]

# 描边相关的BBCode格式化函数

## 为文本添加描边效果
static func outline(text: String, color_name: String = "black", size: int = 1) -> String:
	return "[outline_size=%d][outline_color=%s]%s[/outline_color][/outline_size]" % [size, color_name, text]

# 整合函数 - 同时设置颜色和描边


## 同时设置文本颜色和描边
static func text_to_BBcode(text: String, text_color_name: String, outline_color_name: String = "black", outline_size: int = 1) -> String:
	var colored_text = colorize(text, text_color_name)
	return outline(colored_text, outline_color_name, outline_size)



#region 快速BBcode函数
static func BBcode_warning(text: String) -> String:
	return text_to_BBcode(text, "#FF4444", "black", 9)

static func BBcode_bonus(text: String) -> String:
	return text_to_BBcode(text, "lime", "black", 9)

static func BBcode_basic(text: String) -> String:
	return text_to_BBcode(text, "yellow", "black", 9)

static func BBcode_max(text: String) -> String:
	return text_to_BBcode(text, "orange", "black", 9)


#endregion
