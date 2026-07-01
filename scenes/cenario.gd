extends StaticBody3D

@onready var stone_circle: Node3D = $StoneCircle
@onready var univas: Node3D = $Univas

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_p"):
		univas.visible = stone_circle.visible
		stone_circle.visible = not stone_circle.visible
