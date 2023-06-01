extends RefCounted
class_name VFNConnection

##physical distance from one node to the other
#var distance:float = 0
#the connected node
var node_b:VFNNode
#the effort (mostly distance) from this node to node_b
var effort:float = 0
#the physical steepness between the nodes
var steepness:float = 0
#connection disabled
var disabled:bool = false
