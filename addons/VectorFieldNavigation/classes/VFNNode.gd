@tool
extends Resource
class_name VFNNode

## the node class for the VectorFieldMap
## 
## This field mdofies the effort needed to reach nodes
## The higher the value for a node the less "attractive" the node is to use

## the associated map
var map:VFNMap
## all connections that lead to this field
var connections:Array[VFNConnection]
## the positon scaled by the scale factors, relative to the map node
var world_position:Vector3
## the positon scaled by the scale factors, relative to the map node, only in the x,z plane
var world_position_2d:Vector2
## the relative position on the grid
var rel_position:Vector3
## this's nodes index number in field arrays
var vf_index:int
## a random color for debug purposes
var color:Color
## node is disabled, gets excluded from calculation
var disabled:bool = false
## position on the grid
var pos:Vector2i :
	set( value ):
		pos = value
		vf_index = pos.x * map.size.x + pos.y

## height of the node
var height:float :
	set( value ):
		height = value
		world_position = Vector3(map.field_scale,0,map.field_scale) / 2.0 + Vector3( pos.x * map.field_scale, height * map.height_scale, pos.y * map.field_scale )
		world_position_2d = Vector2(map.field_scale,map.field_scale) / 2.0 + Vector2( pos.x * map.field_scale, pos.y * map.field_scale )
		rel_position = Vector3(pos.x,height,pos.y)


func _init():
	color = Color.from_hsv(randf(),1,1)
	connections.resize(8)


