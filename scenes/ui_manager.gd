extends CanvasLayer



@export var main_hud:Control

var current_panel: Control = main_hud

var info_pop: Control

var diplomatcy_panel_scene = preload("res://scenes/ui/panel/diplomacy_panel.tscn")
var stellar_panel_scene = preload("res://scenes/ui/panel/stellar_panel.tscn")
var general_tech_panel_secne = preload("res://scenes/ui/components/tech_system/general_tech_panel.tscn")
var core_tech_panel_scene = preload("res://scenes/ui/panel/core_tech_panel.tscn")


func _ready() -> void:
	current_panel = main_hud
	
func change_panel(panel:PackedScene,data):
	var panel_instance = panel.instantiate()
	panel_instance.init_panel(data)
	add_child(panel_instance)
	if current_panel == main_hud:
		current_panel.hide()
	else:
		current_panel.queue_free()
	current_panel = panel_instance
	
func back_to_main():
	current_panel.hide()
	current_panel = main_hud
	main_hud.show()
