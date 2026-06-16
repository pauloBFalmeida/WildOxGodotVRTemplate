extends Node

@export var player_spawn: PlayerSpawn

@onready var hud: Hud = $Hud
@onready var marcadores: Marcadores = $"../Marcadores"

var jogadorVR: JogadorVR

func _ready() -> void:
	#GameGlobal.comecarYoga.connect(comecar_yoga)
	# pega o jogador vr
	player_spawn.player_spawned.connect(_ajustar_jogador_vr)
	# 
	for i in range(20):
		await get_tree().process_frame
	comecar_yoga()


func _ajustar_jogador_vr(current_player: Node3D) -> void:
	# pega o jogador VR caso exista
	if (current_player is JogadorVR):
		jogadorVR = player_spawn.current_player
	else:
		return

func comecar_yoga() -> void:
	marcadores.iniciar()
