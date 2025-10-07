extends Manager

var id_counter: int = 100000000

func _ready() -> void:
	super._ready()

func generate_id() -> int:
	id_counter += 1
	return id_counter