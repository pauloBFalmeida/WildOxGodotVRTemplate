class_name Menu
extends Node3D

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_u"):
		visible = not visible
