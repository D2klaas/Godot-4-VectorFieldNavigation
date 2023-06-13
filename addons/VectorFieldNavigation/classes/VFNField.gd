extends RefCounted
class_name VFNField

##print debug message to the console
var debug:bool = true
##the map used for this field (do not change)
var map:VFNMap
##set targets
var targets:Array
var index_of_targets:Dictionary
##heighest effort used on the field
var heighest_ef:float
##stop calculation if more nodes processed than n * node_count
var calc_cutoff_factor:int = 10

##current thread
var thread:Thread
var _kill_thread:bool
var field_mutex:Mutex

var field_ef:PackedFloat32Array
var field_target:PackedInt32Array
var field_aim:PackedInt32Array
var _field_vector:PackedVector3Array #working vectorfield
var field_vector:PackedVector3Array
var field_open_mask:PackedInt32Array

#connection cache vars
var connection_cache:PackedFloat32Array
var connection_cache_index:PackedInt32Array
var connection_cache_current_index:int = -1

const VERY_HIGH_NUMBER:int = 9999999999

## modifiers for calculations
var effort_cutoff:float = VERY_HIGH_NUMBER :
	set(value):
		effort_cutoff = value

## the factor on upward direction, the higher the more effort on climbs
var climb_factor:float = 0.0 :
	set(value):
		if value == climb_factor:
			return
		climb_factor = value
		connection_cache_current_index = -1

## the cutoff in upward direction, if a connection is more steep than this, it wont be used
var climb_cutoff:float = VERY_HIGH_NUMBER :
	set(value):
		if value == climb_cutoff:
			return
		climb_cutoff = value
		connection_cache_current_index = -1

## the factor on downward direction, the higher the more effort on drops
var drop_factor:float = 0.0 :
	set(value):
		if value == drop_factor:
			return
		drop_factor = value
		connection_cache_current_index = -1

## the cutoff in downward direction, if a connection is more steep than this, it wont be used
var drop_cutoff:float = VERY_HIGH_NUMBER :
	set(value):
		if value == drop_cutoff:
			return
		drop_cutoff = value
		connection_cache_current_index = -1

## the factor used on mod fields
var field_effort_factor:float = 1 :
	set(value):
		if value == field_effort_factor:
			return
		field_effort_factor = value
		connection_cache_current_index = -1



signal thread_finished
## the calculation finished successful:bool true/false
signal calculated


func _init( _map:VFNMap ):
	field_mutex = Mutex.new()
	connect("thread_finished",self._on_thread_finished,CONNECT_DEFERRED)
	_map.connect("map_changed", self._on_map_changed )
	_map.connect("connections_changed", self._on_connections_changed )
	_map.connect("nodes_changed", self._on_nodes_changed )
	
	map = _map


func _on_map_changed():
	connection_cache_current_index = -1


func _on_connections_changed():
	connection_cache_current_index = -1


func _on_nodes_changed():
	connection_cache_current_index = -1


# everything about targets
func ______TARGETS():
	pass


## clear all set targets
func clear_targets():
	targets.clear()


##adds a target for this field at x:int,y:int
##data can be any additional information for this target
func add_target( pos:Vector2i, data=null ) -> VFNTarget:
	var c_index = pos.x * map.size.x + pos.y
	if c_index < 0 and c_index >= map.nodes.size():
		return null
	
	var target:VFNTarget = VFNTarget.new()
	target.pos = pos
	target.data = data
	target.node = map.nodes[c_index]
	targets.append( target )
	
	return target


##adds a target for this field at world position
##data can be any additional information for this target
func add_target_from_world( wpos:Vector3, data=null, clamp=true ) -> VFNTarget:
	var p:Vector3 = map.to_local( wpos )
	p = p.round() / map.field_scale
	var n:Vector2i = Vector2i(p.x,p.z)
	if clamp:
		n = Vector2i(p.x,p.z).clamp(Vector2i.ZERO,map.size)
	return add_target( n, data )


## remove a target
func remove_target( pos ):
	if pos is Vector2i:
		for i in targets.size():
			if targets[i].pos.x == pos.x and targets[i].pos.y == pos.y:
				targets.remove_at(i)
				return true
		return false
	
	if pos is VFNTarget:
		for i in targets.size():
			if targets[i] == pos:
				targets.remove_at(i)
				return true
		return false


## remove multiply target
func remove_targets( destinations:Array[Vector2i] ):
	var del:Array[int]
	for d in destinations:
		remove_target( d )
		del.append( d.x*map.size.x + d.y )


# everything about calculating
func ______MODFIELD():
	pass


var modfield_weights:Dictionary

##weight for a modfield of the map
func set_modfield( name:String, weight:float ):
	for mf in map.mod_fields:
		if mf.name == name:
			modfield_weights[name] = weight
			return true
	return false


func ______CALCULATION():
	pass


## kills the running calculation thread
func stop_calculation():
	_kill_thread = true


## calculate the field solution in a thread, add a callback to be called if finished
func calculate_threaded( callback = null, kill_existing_thread:bool=true ):
	if thread:
		if kill_existing_thread and thread.is_started():
			emit_signal("calculated",false) # dispatch old callback or else race condition will occure
			_kill_thread = true
			await calculated
		else:
			return false
	
	thread = Thread.new()
	
	if callback is Callable:
		connect("calculated", callback, CONNECT_ONE_SHOT)
	
	d("--- start calculation thread")
	init_fields()
	thread.start( self.calculate )
	d("thread running")
	return true


func _on_thread_finished():
	if thread:
		d("wait thread to finish")
		var r = thread.wait_to_finish()
		if r:
			d("thread finished successful")
			field_vector = _field_vector

			#release some memory
			_field_vector = PackedVector3Array()
			field_open_mask.clear()
			thread = null
			emit_signal("calculated", true)
		else:
			d("thread failed")
			thread = null
			emit_signal("calculated", false)
		


## clear the connections cache
func clear_cache():
	d("init cache field")
	connection_cache.resize( map.connection_count )
	connection_cache.fill(0)
	connection_cache_index.resize( map.size.x * map.size.y )
	connection_cache_index.fill(-1)
	connection_cache_current_index = 0


## reinit all data fields
func init_fields():
	field_mutex.lock()
	
	#resize and clear the effort field
	field_ef.resize( map.size.x * map.size.y )
	field_ef.fill(VERY_HIGH_NUMBER)
	
	#fill field aims list with null
	field_aim.resize( map.size.x * map.size.y )
	field_aim.fill(-1)
	
	field_target.resize( map.size.x * map.size.y )
	field_target.fill(-1)
	
	_field_vector.clear()
	_field_vector.resize( map.size.x * map.size.y )
	
	field_mutex.unlock()


## calculate unthreaded
## call init_fields when use manualy
func calculate():
	var t_start = Time.get_ticks_msec()
	
	if connection_cache_current_index == -1:
		clear_cache()
	
	field_open_mask.resize( map.size.x * map.size.y )
	field_open_mask.fill(0)
	
	#init the open list
	var openlist:Array[int]
	for t in targets:
		#insert targets into the openlist
		openlist.append( t.node.field_index )
		field_ef[ t.node.field_index ] = 0.0
		field_aim[ t.node.field_index ] = t.node.field_index
		field_open_mask[ t.node.field_index ] = 1
		field_target[ t.node.field_index ] = t.node.field_index
		index_of_targets[t.pos.x * map.size.x + t.pos.y] = t
	
	#neighbour tile index
	var nx:int
	var ny:int
	var ef:float
	var _ef:float
	var c_node_ef:float
	var c_node:VFNNode
	var n_node:VFNNode
	var dist:float
	
	var max_steps:int = field_ef.size() * calc_cutoff_factor
	var steps:int = 0
	heighest_ef = 0.0
	
	var n_index:int
	var c_index:int
	var cache_index:int
	
	var skips_1:int
	var skips_2:int
	var skips_cache:int
	var from_cache:int = 0
	var cached:int = 0
	
	var con_index:int = 0
	
	var mf:VFNModField
	var static_mod_fields:Array
	var static_mod_fields_weights:Array[float]
	var dynamic_mod_fields:Array
	var dynamic_mod_fields_weights:Array[float]
	
	for _mf in map.mod_fields:
		if _mf.dynamic:
			if modfield_weights.has(_mf.name):
				if modfield_weights[_mf.name] > 0:
					dynamic_mod_fields.append(_mf)
					dynamic_mod_fields_weights.append(modfield_weights[_mf.name])
				else:
					pass
			else:
				dynamic_mod_fields.append(_mf)
				dynamic_mod_fields_weights.append(1)
		else:
			if modfield_weights.has(_mf.name):
				if modfield_weights[_mf.name] > 0:
					static_mod_fields.append(_mf)
					static_mod_fields_weights.append(modfield_weights[_mf.name])
				else:
					pass
			else:
				static_mod_fields.append(_mf)
				static_mod_fields_weights.append(1)
	
	
	while openlist.size() > 0:
		steps += 1
		if steps > max_steps:
			d("calculation limit reached")
			d("openlist count: "+str(openlist.size()))
			emit_signal("thread_finished")
			return false
		
		if _kill_thread:
			_kill_thread = false
			d("thread terminated")
			emit_signal("thread_finished")
			return false
		
		c_index = openlist.pop_front()
		field_open_mask[c_index] = 0
		c_node = map.nodes[c_index]
		
		#if current node is disabled, skip calculation
		if c_node.disabled:
			continue
		
		# init cache if not present
		cache_index = connection_cache_index[c_index]
		if cache_index == -1:
			cache_index = connection_cache_current_index
			connection_cache_index[c_index] = connection_cache_current_index
			connection_cache_current_index += c_node.connections.size()
		
		# dynamic mod field penaltys for this c_node
		c_node_ef = 0
		for i in dynamic_mod_fields.size():
			mf = dynamic_mod_fields[i]
			if mf.boolean and mf.field[c_index] == -1:
				continue
			c_node_ef += mf.field[c_index] * field_effort_factor * dynamic_mod_fields_weights[i]
		
		
		con_index = -1
		for c in c_node.connections:
			con_index += 1
			
			#load cache
			_ef = connection_cache[cache_index + con_index]
			
			if _ef == -1:
				skips_cache += 1
				continue
			
			if not c:
				connection_cache[cache_index + con_index] = -1
				cached += 1
				continue
			
			n_node = c.other_node
			n_index = n_node.field_index
			
			if field_ef[c_index] > field_ef[n_index]:
				skips_1 += 1
				continue
			
			#calculate effort
			ef = field_ef[c_index] + c_node_ef
			if _ef == 0:
				#cache is empty ... calculate effort
				cached += 1
				
				if c.steepness == 0:
					pass
				elif c.steepness > 0:
					if climb_cutoff < c.steepness:
						_ef = -1
					else:
						_ef += climb_factor * c.steepness
				else:
					if drop_cutoff < -c.steepness:
						_ef = -1
					else:
						_ef += drop_factor * -c.steepness
				
				if n_node.disabled:
					_ef = -1
				
				if _ef == -1:
					connection_cache[cache_index + con_index] = -1
					
					#dont cut corners
					match con_index:
						0:
							#disable nw and ne
							connection_cache[cache_index + 4] = -1
							connection_cache[cache_index + 7] = -1
							#print("!")
						1:
							#disable ne and se
							connection_cache[cache_index + 4] = -1
							connection_cache[cache_index + 5] = -1
						2:
							#disable se and sw
							connection_cache[cache_index + 5] = -1
							connection_cache[cache_index + 6] = -1
						3:
							#disable nw and sw
							connection_cache[cache_index + 6] = -1
							connection_cache[cache_index + 7] = -1
					
					continue
				
				#add connection's effort
				_ef += c.effort
				
				#add static mod fields
				for i in static_mod_fields.size():
					mf = static_mod_fields[i]
					if mf.boolean and mf.field[c_index] == -1:
						connection_cache[cache_index + con_index] = -1
						continue
					_ef += mf.field[c_index] * field_effort_factor * static_mod_fields_weights[i]
				
				connection_cache[cache_index + con_index] = _ef
			else:
				from_cache += 1
			
			ef += _ef
			
			#next node to current node effort is smaller
			if ef < field_ef[n_index] and ef < effort_cutoff:
				field_ef[n_index] = ef
				field_aim[n_index] = c_index
				_field_vector[n_index] = n_node.world_position.direction_to(c_node.world_position)
				field_target[n_index] = field_target[c_index]
				if field_open_mask[n_index] != 1:
					openlist.append( n_index )
					field_open_mask[n_index] = 1
				heighest_ef = max(heighest_ef,ef)
	
	var t_end = Time.get_ticks_msec()
	d("Steps taken: "+str(steps)+"["+str(map.size.x*map.size.y)+"] in "+str(t_end-t_start)+"msec   heighest effort:"+str(heighest_ef))
	d("Skips by effort check: "+str(skips_1))
	d("Skips by cache: "+str(skips_cache))
	d("from cache: "+str(from_cache))
	d("cached: "+str(cached))
	emit_signal("thread_finished")
	
	return true


func ______RETRIEVING():
	pass


## get the index number of the node where this node is pointing to from world position
func get_aim_world( global_position:Vector3, clamp:bool=true ) -> int:
	var p:Vector3 = map.to_local( global_position )
	p = p.round() / map.field_scale
	var n:Vector2i = Vector2i(p.x,p.z)
	if clamp:
		n = Vector2i(p.x,p.z).clamp(Vector2i.ZERO,map.size)
	var index = n.x*map.size.x+n.y
	if index < 0 or index >= field_vector.size():
		return -1
	else:
		return field_aim[index]


## get VFNNode for world position
func get_node_world( wpos:Vector3, clamp:bool=true ) -> VFNNode:
	var p:Vector3 = map.to_local( wpos )
	p = p.round() / map.field_scale
	var n:Vector2i = Vector2i(p.x,p.z)
	if clamp:
		n = Vector2i(p.x,p.z).clamp(Vector2i.ZERO,map.size)
	var index = n.x*map.size.x+n.y
	if index < 0 or index >= field_vector.size():
		return null
	else:
		return map.nodes[index]


## get VFNTarget for world position
func get_target_world( wpos:Vector3, clamp:bool=true ) -> VFNTarget:
	var p:Vector3 = map.to_local( wpos )
	p = p.round() / map.field_scale
	var n:Vector2i = Vector2i(p.x,p.z)
	if clamp:
		n = Vector2i(p.x,p.z).clamp(Vector2i.ZERO,map.size)
	var index = n.x*map.size.x+n.y
	if index < 0 or index >= field_vector.size():
		return null
	else:
		return index_of_targets[field_target[index]]


func get_vector_world( wpos:Vector3, clamp:bool=true ) -> Vector3:
	var p:Vector3 = map.to_local( wpos )
	p = p.round() / map.field_scale
	var n:Vector2i = Vector2i(p.x,p.z)
	if clamp:
		n = Vector2i(p.x,p.z).clamp(Vector2i.ZERO,map.size)
	var index = n.x*map.size.x+n.y
	if index < 0 or index >= field_vector.size():
		return Vector3(0,0,0)
	else:
		return field_vector[index]


## get movement vector for world position smoothed by the neighboring fields
func get_vector_smooth_world( wpos:Vector3, clamp:bool=true  ) -> Vector3:
	var p:Vector3 = map.to_local( wpos )
	p = p.round() / map.field_scale
	var n:Vector2i = Vector2i(p.x,p.z)
	if clamp:
		n = Vector2i(p.x,p.z).clamp(Vector2i.ZERO,map.size)
	var index = n.x*map.size.x+n.y
	if index < 0 or index >= field_vector.size():
		return Vector3(0,0,0)
	else:
		var node:VFNNode = map.nodes[index]
		var d:float = wpos.distance_to(node.world_position)
		var v:Vector3 = field_vector[index]
		for c in node.connections:
			if not c:
				continue
			d = wpos.distance_to(c.other_node.world_position)
			v += field_vector[c.other_node.field_index] * ( d / 3 )
		return v.normalized()


func ______DEBUG():
	pass


## generates a heatmap based on the tiles effort to the closest target
func get_effort_heatmap() -> Image:
	var img:Image = Image.create( map.size.x, map.size.y, false, Image.FORMAT_RGB8 )
	var c:Color
	var ef:float
	for n in map.nodes:
		ef = field_ef[n.field_index]
		c = Color.from_hsv( ef / heighest_ef, 1, 1 )
		if ef == 0:
			c = Color.BLACK
		img.set_pixelv( n.pos, c )
	return img


## generates a heatmap based on the tiles designated target
func get_target_heatmap() -> Image:
	var img:Image = Image.create( map.size.x, map.size.y, false, Image.FORMAT_RGB8 )
	var c:Color
	var ef:float
	for n in map.nodes:
		ef = field_ef[n.field_index]
		if field_target[n.field_index]:
			c = map.nodes[field_target[n.field_index]].color
			c.v = 1.0 - ef / heighest_ef
		else:
			c = Color.GRAY
		if ef == 0:
			c = Color.BLACK
		img.set_pixelv( n.pos, c )
	return img


func get_penalty_heatmap() -> Image:
	var img:Image = Image.create( map.size.x, map.size.y, false, Image.FORMAT_RGB8 )
	var c:Color = Color.WHITE
	var ef:float
	for n in map.nodes:
		c.v = 1
		for mf in map.mod_fields:
			c.v -= mf.get_value(n.pos) * 0.05
		img.set_pixelv( n.pos, c )
	return img


func d( value ):
	if debug:
		print("VFN-Field: "+str(value) )


class VFNTarget extends RefCounted:
	var pos:Vector2i
	var data = null
	var id:int
	var node:VFNNode
	var color:Color
	
	func _init():
		color = Color.from_hsv(randf(),1,1)
