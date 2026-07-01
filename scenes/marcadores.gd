class_name Marcadores
extends Node3D

var hud: Hud

@export var tempo_inspirar: float = 5.0
@export var tempo_expirar: float = 5.0

var posicoes: Array[PosExercicio]

func _ready() -> void:
	for c in get_children():
		if c is PosExercicio:
			posicoes.append(c)
			c.hide()
	
	await get_tree().create_timer(0.1).timeout
	hud = get_tree().get_first_node_in_group("HUD")


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
		_mostrar_respiracao(posicoes[0].visible)
	if Input.is_action_just_pressed("debug_o"):
		posicoes[1].visible = not posicoes[1].visible
		_mostrar_respiracao(posicoes[1].visible)


func _mostrar_respiracao(inspirar: bool) -> void:
	if inspirar:
		hud.inspire(tempo_inspirar)
	else:
		hud.expire(tempo_expirar)

func iniciar() -> void:
	#_prox()
	pass
