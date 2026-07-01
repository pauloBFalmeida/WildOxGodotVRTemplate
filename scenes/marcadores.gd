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
	pos.show()
	pos.iniciar()
	pos.fim.connect(_prox)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_i"):
		posicoes[0].visible = not posicoes[0].visible
	if Input.is_action_just_pressed("debug_o"):
		posicoes[1].visible = not posicoes[1].visible


func iniciar() -> void:
	#_prox()
	pass
