extends Manager

var current_turn:int = 0

signal turn_changed(new_turn:int)

func _ready() -> void:
	super._ready()

func next_turn() -> void:
	print("回合" + str(current_turn) + "开始")

	var update_action = UpdateAllTechProgressAction.new()

	GlobalNodes.managers.ActionManager.add_action(update_action)

	GlobalSignalBus.turn_phase.emit(GlobalSignalBus.TurnPhase.Action)
	await GlobalSignalBus.turn_phase_completed
	GlobalSignalBus.turn_phase.emit(GlobalSignalBus.TurnPhase.FleetMove)
	await GlobalSignalBus.turn_phase_completed
	GlobalSignalBus.turn_phase.emit(GlobalSignalBus.TurnPhase.Animation)
	await GlobalSignalBus.turn_phase_completed
	GlobalNodes.managers.PlanetManager.trigger_planet_update()
	await GlobalSignalBus.all_planet_update_completed
	GlobalNodes.managers.StellarManager.trigger_stellar_update()
	await GlobalSignalBus.all_stellar_update_completed
	current_turn += 1
	turn_changed.emit(current_turn)
	print("回合" + str(current_turn) + "结束")
	GlobalSignalBus.turn_finished.emit()
