@tool
extends Node3D

@export var mesh: Mesh:
	set(v):
		mesh = v
		$StaticBody3D/MeshInstance3D.mesh = v

@export var collision_shape: Shape3D:
	set(v):
		collision_shape = v
		$StaticBody3D/CollisionShape3D.shape = v
