class_name JogadorVR
extends XROrigin3D

@onready var hand_col_L: VRHandCollider = $LeftController/VRHandCollider
@onready var hand_col_R: VRHandCollider = $RightController/VRHandCollider

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
