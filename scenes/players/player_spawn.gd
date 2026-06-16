class_name PlayerSpawn
extends Node3D

signal player_spawned(player: Node3D)

# Player scene paths
## = "res://scenes/players/VRPlayer.tscn"
@export var vr_player : PackedScene
## = "res://scenes/players/FPSPlayer.tscn"
@export var fps_player : PackedScene

# Reference to the current player instance
var current_player: Node3D


func spawn_player(use_vr: bool):
	# Load the appropriate player scene
	var player_scene = vr_player if use_vr else fps_player
	
	if player_scene:
		var player_instance = player_scene.instantiate()
		current_player = player_instance
		
		# Add to the main scene
		#var main_scene = get_tree().current_scene
		#main_scene.add_child(player_instance)
		add_child(player_instance)
		
		# For desktop mode, ensure mouse capture
		if not use_vr:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		player_instance.global_position = global_position
		player_instance.global_rotation = global_rotation
		
		player_spawned.emit(player_instance)
		
		print("Spawned " + ("VR" if use_vr else "FPS") + " player")
	else:
		push_error("Failed to load player scene: " + player_scene.name)
