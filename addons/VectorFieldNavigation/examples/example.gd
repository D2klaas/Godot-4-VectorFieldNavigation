extends Node3D

## the VFN field
var field:VFNField
var occupied_field:VFNModField
var update:bool = false

func _ready():
	# set default values
	$GUI.effort_cutoff = 800
	$GUI.climb_factor = 4.1
	$GUI.climb_cutoff = 0.2
	$GUI.drop_factor = 4.1
	$GUI.drop_cutoff = 0.2
	$GUI.field_effort_factor = 1.0
	
	# wait first rendered frame to get the image
	await get_tree().process_frame
	var img:Image = %OrgMap.texture.get_image()
	# get the map
	var map:VFNMap = $VectorMap
	# init the map from an image
	map.create_from_image( img )
	
	#add portals between two fields (both directions)
	map.add_portal(Vector2i(25,60),Vector2i(80,44))
	map.add_portal(Vector2i(80,44),Vector2i(25,60))
	
	# create a penalty field for edge penalties
	# keeping entities from gliding along the walls
	var penalty_field:VFNModField = map.add_mod_field("margin")
	penalty_field.upmost = true
	
	# here is another penalty field as descriped in the readme
	# but its for later ... not now
#	occupied_field = map.add_mod_field("occupied")
#	occupied_field.dynamic = true

	
	# add some penalty margin arround cliffs in the created modField
	map.add_penalty_height_margin(penalty_field,3,10)
	
	# center the camera over the terrain
	$cam_base.position = Vector3(map.size.x/2, 0, map.size.y/2)
	# init the terrain collider
	$scenery/terrain/shape.shape.map_width = map.size.x
	$scenery/terrain/shape.shape.map_depth = map.size.y
	$scenery/terrain/shape.position = map.position * -1
	
	# create some units
	var u
	var _unit = load("res://addons/VectorFieldNavigation/examples/unit.tscn")
	for i in 100:
		u = _unit.instantiate()
		add_child(u)
		u.occupied_field = occupied_field
		u.linear_velocity = Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1)) * 5
		u.linear_velocity = Vector3(0,0,0)
		u.position = Vector3(randi_range(10,map.size.x-10),10,randi_range(10,map.size.y-10)) 
	
	$scenery/terrain/shape.position = Vector3(map.size.x/2, 0, map.size.y/2)
	for x in map.size.x:
		for y in map.size.y:
			$scenery/terrain/shape.shape.map_data[x*map.size.x+y] = map.get_height(Vector2i(y,x)) * map.height_scale
	
	$scenery/terrain/mesh.scale.y = map.height_scale
	$scenery/terrain/mesh.mesh = create_heightmap_mesh( map.size.x, map.size.y, map )


func _on_button_pressed():
	var map = $VectorMap
	if not field:
		#create a field
		field = map.create_field( )
		#connect units with the field
		var units = get_tree().get_nodes_in_group("unit")
		for unit in units:
			unit.field = field
	
	# if you want to weight the influence of a modfield you can do it like this
	field.set_modfield("margin",1) # factor 1 is default
	
	#comes later
#	occupied_field.clear()
	
	# set gui values to field modifiers
	field.effort_cutoff = $GUI.effort_cutoff
	field.climb_factor = $GUI.climb_factor
	field.climb_cutoff = $GUI.climb_cutoff
	field.drop_factor = $GUI.drop_factor
	field.drop_cutoff = $GUI.drop_cutoff
	field.field_effort_factor = $GUI.field_effort_factor
	
	# clear all assigned target nodes
	field.clear_targets()
	
	var pos:Vector2i
	if true:
		for i in $GUI.gen_targets:
			var h:float = 1
			while h > 0.1:
				pos.x = randi_range(10,map.size.x-10)
				pos.y = randi_range(10,map.size.y-10)
				h = map.get_height( pos )
				if h < 0.1:
					field.add_target( pos )
	else:
		field.add_target( Vector2i(105,15) )
	
	update = false
	field.calculate_threaded( self._on_calculated.bind(field), true )


func _on_calculated( succesful, field ):
	if not succesful:
		return
	var tex
	$VectorMap.update_debug_mesh( field )
	tex = ImageTexture.create_from_image(field.get_target_heatmap())
	%TargetMap.texture = tex
	tex = ImageTexture.create_from_image(field.get_penalty_heatmap())
	%PenaltyMap.texture = tex
	tex = ImageTexture.create_from_image(field.get_effort_heatmap())
	%EffortMap.texture = tex
	$scenery/terrain/mesh.material_override.albedo_texture = %TargetMap.texture
	
	update = true


func _process(delta):
	$cam_base.rotate_y(delta*0.05)


func create_heightmap_mesh( _x:int, _y:int, heights=null ):
	var st:SurfaceTool = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v:Vector3
	var h:float
	for x in _x-1:
		for y in _y-1:
			h = heights.get_height(Vector2i(x,y))
			v = Vector3(x,h,y)
			v.y = heights.get_height(Vector2i(v.x,v.z))
			st.set_uv(Vector2(v.x/_x,v.z/_y))
			st.add_vertex(v)
			v = Vector3(x+1,h,y)
			v.y = heights.get_height(Vector2i(v.x,v.z))
			st.set_uv(Vector2(v.x/_x,v.z/_y))
			st.add_vertex(v)
			v = Vector3(x+1,h,y+1)
			v.y = heights.get_height(Vector2i(v.x,v.z))
			st.set_uv(Vector2(v.x/_x,v.z/_y))
			st.add_vertex(v)
			
			v = Vector3(x,h,y)
			v.y = heights.get_height(Vector2i(v.x,v.z))
			st.set_uv(Vector2(v.x/_x,v.z/_y))
			st.add_vertex(v)
			v = Vector3(x+1,h,y+1)
			v.y = heights.get_height(Vector2i(v.x,v.z))
			st.set_uv(Vector2(v.x/_x,v.z/_y))
			st.add_vertex(v)
			v = Vector3(x,h,y+1)
			v.y = heights.get_height(Vector2i(v.x,v.z))
			st.set_uv(Vector2(v.x/_x,v.z/_y))
			st.add_vertex(v)
			
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


func _on_timer_timeout():
	#comes later
	return
	occupied_field.blur_fade(0.8)
	if update:
		update = false
		field.calculate_threaded( self._on_calculated.bind(field) )

