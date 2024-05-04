@tool
extends Node3D
class_name VFNMap


## Vector-Field-Navigation-Map
##
## This is the base class for a grid map for VFN-Navigation.
## It holds all nodes of the grid and features map modification tools
 

##print debug message to the console
var debug:bool = true
## all nodes of the grid
var nodes:Array[VFNNode]

## scale of a map tile
## (1.5 means every tile is 1.5 by 1.5)
@export var field_scale:float = 1.0 :
	set( value ):
		field_scale = value
		if _is_init:
			for x in size.x:
				for y in size.y:
					#all nodes must refresh their world position
					nodes[x*size.x+y].height = nodes[x*size.x+y].height
		update_debug_mesh()
		emit_signal("nodes_changed")

## scale of height
@export var height_scale:float = 1.0 : 
	set( value ):
		height_scale = value
		if _is_init:
			for x in size.x:
				for y in size.y:
					#all nodes must refresh their world position
					nodes[x*size.x+y].height = nodes[x*size.x+y].height
		update_debug_mesh()
		emit_signal("nodes_changed")

## the maps width and depth
@export var size:Vector2i :
	set( value ):
		if size == value:
			return
		size = value
		update_debug_mesh()
		init()

## draw a debug mesh
@export var draw_debug:bool :
	set( value ):
		draw_debug = value
		update_debug_mesh()

var _debug_mesh:MeshInstance3D
var _is_init:bool
var _is_ready:bool

## use this image to fill the maps data
@export var heightmap:Texture2D :
	set( value ):
		heightmap = value
		if _is_init and use_heightmap:
			create_from_image( heightmap.get_image() )
		update_debug_mesh()

## enable heightmap usage
@export var use_heightmap:bool :
	set( value ):
		use_heightmap = value
		if _is_init and heightmap and use_heightmap:
			create_from_image( heightmap.get_image() )
		update_debug_mesh()

## count of all connections in all nodes
var connection_count:int = 0

const NODE_N:int = 0
const NODE_E:int = 1
const NODE_S:int = 2
const NODE_W:int = 3
const NODE_NE:int = 4
const NODE_SE:int = 5
const NODE_SW:int = 6
const NODE_NW:int = 7

const CONS = [
	Vector2i( 0, -1),
	Vector2i( 1,  0),
	Vector2i( 0,  1),
	Vector2i(-1,  0),
	Vector2i( 1, -1),
	Vector2i( 1,  1),
	Vector2i(-1,  1),
	Vector2i(-1, -1),
]

##the map has significant changes in the structure
signal map_changed
##some connections have changed
signal connections_changed
##some nodes have changed
signal nodes_changed


func _ready():
	await get_tree().process_frame #await first frame, so that the heightmap can be used
	_is_ready = true
	if heightmap and use_heightmap:
		d("processing export heightmap")
		var img =  heightmap.get_image()
		create_from_image( img )
	else:
		init()
	_is_init = true
	update_debug_mesh()


## initializes the data structure for the map
func init( ):
	if not _is_ready:
		return
	
	d("init map with "+str(size))
	var protonode = VFNNode.new()
	var node
	mod_fields.clear()
	nodes.clear()
	nodes.resize(size.x*size.y)
	connection_count = 0
	for x in size.x:
		for y in size.y:
			node = protonode.duplicate()
			connection_count += 8
			node.map = self
			node.pos = Vector2i(x,y)
			nodes[node.field_index] = node
	
	var c_node:VFNNode
	var n_node:VFNNode
	var n_index:int
	var connection:VFNConnection
	var c:Vector2i
	for x in size.x:
		for y in size.y:
			c_node = nodes[x*size.x+y]
			for ci in CONS.size():
				c = CONS[ci]
				n_index = (x+c.x) * size.x + (y+c.y)
				if n_index >= 0 and n_index < nodes.size():
					n_node = nodes[n_index]
					connection = VFNConnection.new()
					connection.other_node = n_node
					connection.effort = c_node.world_position.distance_to(n_node.world_position)
					connection.steepness = (c_node.world_position.y - n_node.world_position.y) / c_node.world_position_2d.distance_to(n_node.world_position_2d)
					c_node.connections[ci] = connection
	
	d("created "+str(nodes.size())+" nodes with "+str(connection_count)+" connections")
	
	emit_signal("map_changed")


##get node object at position pos
func get_node_at( pos:Vector2i ) -> VFNNode:
	var id = pos.x*size.x+pos.y
	if id >= 0 and id < size.x*size.y:
		return nodes[id]
	return null


## create a navigation field from this map
func create_field( ) -> VFNField:
	var field:VFNField
	field = VFNField.new( self )
	
	return field


## set the tiles heights based on an image
func create_from_image( img:Image, g_channel:VFNModField = null, b_channel:VFNModField = null, a_channel:VFNModField = null ):
	if not img:
		return
	var _size = img.get_size()
	if _size.x == 0 or _size.y == 0:
		return
	
	size = _size
	
	var nx:int
	var ny:int
	var c:Color
	img.decompress()
	for x in size.x:
		for y in size.y:
			c = img.get_pixel(x,y)
			set_height( Vector2i(x, y), c.r )
			if g_channel:
				g_channel.set_value( Vector2i(x,y), c.g)
			if b_channel:
				b_channel.set_value( Vector2i(x,y), c.g)
			if a_channel:
				a_channel.set_value( Vector2i(x,y), c.g)
	
	for c_node in nodes:
		for connection in c_node.connections:
			if connection:
				connection.effort = c_node.world_position.distance_to(connection.other_node.world_position)
#				connection.steepness = (c_node.world_position.y - connection.other_node.world_position.y) / c_node.world_position_2d.distance_to(connection.other_node.world_position_2d)
				connection.steepness = (connection.other_node.height - c_node.height) / c_node.rel_position.distance_to(connection.other_node.rel_position)


func ______MODIFY():
	pass


## adds a penalty to every node around cliffs or drops
func add_penalty_height_margin( field:VFNModField, margin:int, strength:float ):
	var c_node:VFNNode
	var n_node:VFNNode
	var n_index:int
	var dh:float
	var penalty:float
	var dist:float
	
	for x in size.x:
		for y in size.y:
			c_node = nodes[x*size.x+y]
			penalty = 0
			for _x in range(-margin,margin+1):
				for _y in range(-margin,margin+1):
					n_index = (x+_x) * size.x + (y+_y)
					if n_index >= 0 and n_index < nodes.size():
						n_node = nodes[n_index]
						dist = Vector2(x,y).distance_to(Vector2(x+_x,y+_y))
						if dist > 0:
							dh = (c_node.height - n_node.height) / dist
							dh = abs(dh)
							field.set_value(Vector2i(x,y),dh * strength)


func ______MODIFY_NODES():
	pass


## set the height on node at x,y
func set_height( pos:Vector2i, height:float ):
	nodes[pos.x*size.x+pos.y].height = height
	emit_signal("nodes_changed")


## get the height off node at x,y
func get_height( pos:Vector2i ) -> float:
	return nodes[pos.x*size.x+pos.y].height


## connect non neighboring nodes
func add_portal( a:Vector2i, b:Vector2i ) -> VFNConnection:
	var c_node:VFNNode = get_node_at( a )
	var n_node:VFNNode = get_node_at( b )
	
	if c_node and n_node:
		var vfc:VFNConnection = VFNConnection.new()
		vfc.effort = 0.1
		vfc.other_node = n_node
		c_node.connections.append( vfc )
		connection_count += 1
		
		emit_signal("connections_changed")
		return vfc
	else:
		return null


## disables the node at pos
func disable_node( pos:Vector2i ):
	var n:VFNNode = get_node_at( pos )
	if n:
		n.disabled = true


## enables the node at pos
func enable_node( pos:Vector2i ):
	var n:VFNNode = get_node_at( pos )
	if n:
		n.disabled = false


func ______RETRIEVING():
	pass


# get a node by its index number
func get_node_from_index( index:int ) -> VFNNode:
	if index < 0 or index >= nodes.size():
		return null
	else:
		return nodes[index]


func ______MOD_FIELDS():
	pass


var mod_fields:Array[VFNModField]

## adds a modification field to this map with a name
func add_mod_field( name:String ) -> VFNModField:
	var mf = VFNModField.new(self)
	mf.name = name
	mod_fields.append(mf)
	return mf


func ______SERIALIZATION():
	pass


##serialize this map to a PackedByteArray
func serialize() -> PackedByteArray:
	var data:StreamPeerBuffer = StreamPeerBuffer.new()
	data.put_string("v0.1") #Version
	data.put_float(field_scale)
	data.put_float(height_scale)
	data.put_u16(size.x)
	data.put_u16(size.y)
	
	for n in nodes:
		n.serialize( data )
	
	data.put_u8(mod_fields.size())
	for mf in mod_fields:
		mf.serialize( data )
	
	d("serialized data ("+str(data.data_array.size())+" bytes)")
	return data.data_array


##unserialize this map from a PackedByteArray
func unserialize( _data:PackedByteArray ):
	var data:StreamPeerBuffer = StreamPeerBuffer.new()
	data.data_array = _data
	
	var v = data.get_string()
	if v != "v0.1":
		d("cannot unserialze data version is "+v+" but must be v0.1")
		return false
	d("unserialze data version "+v)
	
	field_scale = data.get_float()
	height_scale = data.get_float()
	var _size:Vector2i
	_size.x = data.get_u16()
	_size.y = data.get_u16()
	size = _size
	init()
	
	var n
	for node in nodes:
		node.unserialize( data )
	
	var modfield_count = data.get_u8()
	var mf:VFNModField
	for i in modfield_count:
		mf = add_mod_field("")
		mf.unserialize( data )
	d("extracted "+str(modfield_count)+" modfields")


func ______DEBUG():
	pass


## redraw/update the debug mesh
func update_debug_mesh( field:VFNField=null ):
	if not draw_debug:
		return
	
	if not _is_init:
		return
	
	if size.x == 0 or size.y == 0:
		return
	
	if nodes.size() == 0 or size.x*size.y != nodes.size():
		return
	
	if not is_instance_valid(_debug_mesh):
		_debug_mesh = get_node_or_null("__VectorFieldNavigationMapDebugMesh__")
	
	if not _debug_mesh:
		_debug_mesh = MeshInstance3D.new()
		add_child(_debug_mesh)
		_debug_mesh.mesh = ImmediateMesh.new()
		_debug_mesh.material_override = load("res://addons/VectorFieldNavigation/materials/matVectorFieldNavigationDebugMap.tres")
		
	_debug_mesh.mesh.clear_surfaces()
	_debug_mesh.mesh.surface_begin( Mesh.PRIMITIVE_POINTS )
	

	var c:Color
	for n in nodes:
		if field:
			if field.field_target[n.field_index]:
				c = nodes[field.field_target[n.field_index]].color
				c.v = 1.0 - field.field_ef[n.field_index] / field.heighest_ef
			else:
				c = Color.GRAY
		else:
			c.v = n.height 
		_debug_mesh.mesh.surface_set_color( c ) 
		_debug_mesh.mesh.surface_add_vertex( n.world_position )
	_debug_mesh.mesh.surface_end()


func d( value ):
	if debug:
		print("VFN-Map: "+str(value) )


