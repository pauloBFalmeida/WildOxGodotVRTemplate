class_name Treinador
extends Node3D

@onready var animation_player: AnimationPlayer = $pessoa_mov/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func comecar_exercicio() -> void:
	animation_player.play("Action")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_k"):
		animation_player.stop()
		animation_player.play("Action")
