extends Area3D

@onready var csg_sphere_3d: CSGSphere3D = $CSGSphere3D

var pos_init: Vector3

func _ready() -> void:
	pos_init = csg_sphere_3d.position


func _on_area_entered(area: Area3D) -> void:
	print(area)
	csg_sphere_3d.position = pos_init + Vector3(0,5,0)


func _on_area_exited(area: Area3D) -> void:
	print(area)
	csg_sphere_3d.position = pos_init
