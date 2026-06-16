class_name Marcadores
extends Node3D

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
	pos.iniciar()
	pos.fim.connect(_prox)

func iniciar() -> void:
	_prox()
