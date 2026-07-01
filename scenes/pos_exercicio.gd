class_name PosExercicio
extends Node3D

var marcadores : Array[Marcador]

@export var tempo_inspirar: float = 1.5
@export var tempo_expirar: float = 1.5

@onready var hud: Hud = $"../../Manager/Hud"

@export var tipo : int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for c in get_children():
		if c is Marcador:
			marcadores.append(c)
			c.process_mode = Node.PROCESS_MODE_DISABLED

func iniciar() -> void:
	for marcador in marcadores:
		marcador.process_mode = Node.PROCESS_MODE_DISABLED
		marcador.entrou.connect(add.bind(+1))
		marcador.saiu.connect(add.bind(-1))

var valor = 0
func add(v: int = 1) -> void:
	valor += v
	if valor == marcadores.size():
		respirar()

var respirou:= false
func respirar() -> void:
	if respirou: return
	respirou = true
	
	hud.inspire(tempo_inspirar)
	
	await hud.inspirou_fim
	
	hud.expire(tempo_expirar)
	
	await hud.expirou_fim
	
	prox()

signal fim
func prox() -> void:
	fim.emit()
