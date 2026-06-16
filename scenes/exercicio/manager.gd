extends Node

@export var player_spawn: PlayerSpawn

var jogadorVR: JogadorVR

func _ready() -> void:
	# pega o jogador vr
	player_spawn.player_spawned.connect(_ajustar_jogador_vr)
	# 


func _ajustar_jogador_vr(current_player: Node3D) -> void:
	# pega o jogador VR caso exista
	if (current_player is JogadorVR):
		jogadorVR = player_spawn.current_player
	else:
		return
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("jogadorVR")
	print(jogadorVR)
	jogadorVR.hand_col_L.object_grabbed.connect(_grabbed)

func _grabbed(obj: Node3D) -> void:
	print("grabbed")
	print(obj.name)
	pass
