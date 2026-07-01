class_name Hud
extends Control

signal inspirou_fim

@onready var meio: Control = $Meio

@onready var circulo_preenc: Sprite2D = $Meio/Base/CirculoPreenc
@onready var texto: Label = $Meio/Texto

func _ready() -> void:
	meio.hide()

func inspire(tempo: float) -> void:
	meio.show()
	texto.text = "Inspire"
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		circulo_preenc,
		"scale",
		Vector2.ONE,
		tempo
	).from(Vector2.ZERO)
	
	tween.finished.connect(func(): inspirou_fim.emit() )
	
	await tween.finished
	meio.hide()


func expire(tempo: float) -> void:
	meio.show()
	texto.text = "Expire"
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		circulo_preenc,
		"scale",
		Vector2.ZERO,
		tempo
	).from(Vector2.ONE)
	
	await tween.finished
	meio.hide()
