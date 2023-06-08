extends RefCounted
class_name VFNConnection

##physical distance from one node to the other
#var distance:float = 0
#the connected node
var other_node:VFNNode
#the effort (mostly distance) from this node to node_b
var effort:float = 0
#the physical steepness between the nodes
var steepness:float = 0
#connection disabled
var disabled:bool = false

##serialize this object into buffer stream
func serialize( data:StreamPeer ):
	data.put_16(other_node.pos.x)
	data.put_16(other_node.pos.y)
	data.put_8(int(disabled))
	data.put_float(effort)
	data.put_float(steepness)


##unserialize this object from buffer stream
func unserialize( data:StreamPeer ):
	var op:Vector2i
	op.x = data.get_16()
	op.y = data.get_16()
	other_node = other_node.map.get_node_at(op)
	disabled = data.get_8()
	effort = data.get_float()
	steepness = data.get_float()
