extends Node

@export var player_spawn: PlayerSpawn

@onready var marcadores: Marcadores = $"../Marcadores"
@onready var treinador: Treinador = $"../Treinador"

var jogadorVR: JogadorVR

func _ready() -> void:
	#GameGlobal.comecarYoga.connect(comecar_yoga)
	# pega o jogador vr
	player_spawn.player_spawned.connect(_ajustar_jogador_vr)
	# 
	await get_tree().create_timer(1.5).timeout
	comecar_yoga()


func _ajustar_jogador_vr(current_player: Node3D) -> void:
	# pega o jogador VR caso exista
	if (current_player is JogadorVR):
		jogadorVR = player_spawn.current_player
	else:
		return

func comecar_yoga() -> void:
	marcadores.iniciar()
	treinador.comecar_exercicio()
