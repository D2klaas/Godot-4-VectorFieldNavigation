extends Area3D

@export_node_path("Area3D") var portal_end


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered",self._on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_body_entered(body):
	if body.just_teleported == true:
		body.just_teleported = false
		return
	body.just_teleported = true
	body.global_transform.origin = get_node(portal_end).global_transform.origin + Vector3(0,0.5,0)
