extends RefCounted
class_name VFNModField

## Modifier field for VectorFieldMap
## 
## This field mdofies the effort needed to reach nodes
## The higher the value for a node the less "attractive" the node is to use


## the field is dynamic, value do not get cached
var dynamic:bool = false
## only the highest number get set
var upmost:bool = false
## nodes with a field value of < 0.5 cannot be walked on
var boolean:bool = false
##the fields effort value
var field:PackedFloat32Array
## the associated map
var map:VFNMap
## name of the modfield
var name:String


func _init( _map:VFNMap ):
	map = _map
	map.connect("map_changed",self._reinit)
	_reinit()


func _reinit():
	field.resize( map.nodes.size() )


## reset the whole filed to zero
func clear():
	field.fill(0)


## set the node value at pos
func set_value( pos:Vector2i, value:float ):
	var i = pos.x*map.size.x+pos.y
	
	if boolean:
		if round(value) > 0:
			value = 1
		else:
			value = -1
	
	if upmost:
		value = max( field[i], value )
	
	field[i] = value


## set the node value at pos
func set_value_from_world( wpos:Vector3, value:float, clamp:bool=true ):
	var p:Vector3 = map.to_local( wpos )
	p = p.round() / map.field_scale
	var n:Vector2i = Vector2i(p.x,p.z)
	if clamp:
		n = Vector2i(p.x,p.z).clamp(Vector2i.ZERO,map.size)
	set_value( n, value )


## set the node value at pos
func add_value( pos:Vector2i, value:float ):
	var i = pos.x*map.size.x+pos.y
	
	if upmost:
		value = max( field[i], value )
		field[i] = value
		return
	
	
	if boolean:
		if round(value) > 0:
			value = 1
		else:
			value = -1
		field[i] = value
		return
	
	field[i] += value


## set the node value at pos
func add_value_from_world( wpos:Vector3, value:float, clamp:bool=true ):
	var p:Vector3 = map.to_local( wpos )
	p = p.round() / map.field_scale
	var n:Vector2i = Vector2i(p.x,p.z)
	if clamp:
		n = Vector2i(p.x,p.z).clamp(Vector2i.ZERO,map.size)
	add_value( n, value )


## get the nodes value at pos
func get_value( pos:Vector2i ):
	return field[pos.x*map.size.x+pos.y]


## fade the whole field by factor f 
## (0.9 means the field gets faded by 10%)
func fade( f:float ):
	for i in field.size():
		field[i] *= f

## not yet implemented
func blur_fade( f:float ):
	var _f:float
	var i:int
	var _field:PackedFloat32Array = field.duplicate()
	for x in range(1,map.size.x-1):
		for y in range(1,map.size.y-1):
			i = x*map.size.x + y
			for _x in range(-1,2):
				for _y in range(-1,2):
					_field[i] += field[(x+_x)*map.size.x + y+_y]
			_field[i] /= 9
	field = _field
	fade(f)


##serialize this object into buffer stream
func serialize( data:StreamPeer ):
	data.put_string(name)
	data.put_u8(int(dynamic))
	data.put_u8(int(upmost))
	data.put_u8(int(boolean))
	data.put_var(field)


##unserialize this object from buffer stream
func unserialize( data:StreamPeer ):
	name = data.get_string()
	dynamic = data.get_u8()
	upmost = data.get_u8()
	boolean = data.get_u8()
	field = data.get_var()
