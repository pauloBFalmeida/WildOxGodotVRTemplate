class_name Marcadores
extends Node3D

@export var hud: Hud

var posicoes: Array[PosExercicio]

func _ready() -> void:
	for c in get_children():
		if c is PosExercicio:
			posicoes.append(c)
			c.hide()
	


func _prox() -> void:
	if posicoes.size() <= 0:
		return
	
	var pos : PosExercicio = posicoes.pop_front()
	pos.show()
	pos.iniciar()
	pos.fim.connect(_prox)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_i"):
		posicoes[0].visible = not posicoes[0].visible
		hud.inspire(3.5)
	if Input.is_action_just_pressed("debug_o"):
		posicoes[1].visible = not posicoes[1].visible
		hud.expire(3.5)


func iniciar() -> void:
	#_prox()
	pass
