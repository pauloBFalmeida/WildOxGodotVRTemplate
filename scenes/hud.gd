class_name Hud
extends Control

signal inspirou_fim

@onready var circulo_preenc: Sprite2D = $Meio/Base/CirculoPreenc
@onready var texto: Label = $Meio/Texto

func inspire(tempo: float) -> void:
	var tween := create_tween()
	tween.tween_property(
		circulo_preenc,
		"scale",
		1.0,
		tempo
	).from_current()
	
	tween.finished.connect(func(): inspirou_fim.emit() )
	
	texto.text = "Inspire"
	


func expire(tempo: float) -> void:
	var tween := create_tween()
	tween.tween_property(
		circulo_preenc,
		"scale",
		0.0,
		tempo
	).from_current()
	
	texto.text = "Expire"
