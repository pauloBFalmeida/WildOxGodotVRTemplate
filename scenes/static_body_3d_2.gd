class_name Marcador
extends Area3D

signal entrou
signal saiu

func _on_area_entered(area: Area3D) -> void:
	entrou.emit()
	print("entrou")
	hide()

func _on_area_exited(area: Area3D) -> void:
	saiu.emit()
	show()
