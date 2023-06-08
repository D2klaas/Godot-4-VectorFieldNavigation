@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("VFNMap","Node3D",preload("res://addons/VectorFieldNavigation/classes/VFNMap.gd"),preload("res://addons/VectorFieldNavigation/vfn_icon_mono.png"))


func _exit_tree():
	remove_custom_type("VFNMap")
