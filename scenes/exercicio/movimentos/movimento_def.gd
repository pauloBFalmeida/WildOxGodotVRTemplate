class_name MovimentoDef
extends Resource

@export var marcadores_pos: PackedScene

@export var animacao_id : String = ""

func iniciar(marcadores_base: Node3D) -> void:
	var marcadores = marcadores_pos.instantiate()
	# limpa os anteriores
	for c in marcadores_base.get_children():
		c.queue_free()
	# bota nos novos
	marcadores_base.add_child(marcadores)
	
