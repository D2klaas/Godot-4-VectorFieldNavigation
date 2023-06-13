# Godot-4-VectorFieldNavigation - Dokumentation

### VFNMap
The base data of the navigation map.

**Properties**
* `field_scale:float = 1`\
  scale of a map tile\
  (1.5 means every tile is 1.5 by 1.5)

* `height_scale:float = 1`\
  scale of height\
  (tiles height is height (0 to 1) multiplied by height_scale

* `size:Vector2i`\
  dimensions of the map

* `draw_debug:bool = false`\
  wether draw a pointcloud for visual reference

* `heightmap:Texture2D`\
  use this image to initialize the map

* `use_heightmap:bool = false`\
  use the heightmap

**Signals**

* `map_changed`\
  _emited when the map changed substantially
  
* `connections_changed`\
  _emited when connections changed (cache will be cleared)
  
* `nodes_changed`\
   _emited when nodes changed (cache will be cleared)
  
**Methods**

* `init( ) -> void`\
  initializes the maps data structure\
  must not be called manually

* `get_node_at( pos:vector2i ) -> VFNNode`\
  get node-object at index position pos


* `create_field( ) -> VFNField`\
  create field based on this map for calculation solutions


* `create_from_image( img:Image, g_channel:VFNModField=null, b_channel:VFNModField=null, a_channel:VFNModField=null )`\
  initializes this map based on an heightmap image\
  r channel is allways the node height\
  g, b and a channel can be used for modfields


* `add_penalty_height_margin( field:VFNModField, margin:int, strength:float )`\
  adds penalty to a modfield around slopes and cliffs\
  useful for keeping entities from gliding along walls to reach there targets


* `set_height( pos:Vector2i, height:float )`\
  set nodes height at pos to height\
  height should be between 0 and 1, scale the height with the height_scale property


* `get_height( pos:Vector2i ) -> float`\
  get nodes height at grid position pos


* `add_portal( a:Vector2i, b:Vector2i ) -> VFNConnection`\
  adds a portal connection from a to b\
  returns a connection object where you can set effort etc.


* `disable_node( pos:Vector2i )`\
  disables the node at pos\
  The node will be excluded when calculating


* `enable_node( pos:Vector2i )`\
  enables the node at pos\
  The node will be included when calculating


* `update_debug_mesh( field:VFNField=null )`\
  redraws the debug mesh\
  when a field is given, effort will be shown with color


* `add_mod_field( name:String ) -> VFNModField`\
  adds a named modfield to the map\
  see modfields for further explanations


* `get_node_from_index( index:int ) -> VFNNode`\
  get VFNNode object from index number or -1 if not exist/valid


* `serialize() -> PackedByteArray`\
  serializes all data from this map to a packedByteArray\
  useful to store pre-processed maps into files


* `unserialize( data:PackedByteArray )`\
  rebuild map data from this serialized PackedByteArray
  useful to restore pre-processed maps from files



### VFNField
Field for calculating solutions based on a VFNMap.

**Properties**

* `effort_cutoff:float`\
  stop calculation further when final effort is higher as this number

* `climb_factor:float = 0.0`\
  additional penalty factor for upward steepness

* `climb_cutoff:float = `\
  the cutoff in upward direction, if a connection is more steep than this, it wont be used

* `drop_factor:float = 0.0`\
  additional penalty factor for downward steepness

* `drop_cutoff:float`\
  the cutoff in downward direction, if a connection is more steep than this, it wont be used


* `field_effort_factor:float = 1`\
  additionaly penalty factor on modfields


**Signals**

* `calculated( succesful:bool )`\
  the calculation has finished
  
  
**Methods**

* `add_target( pos:Vector2i, data=null ) -> VFNTarget`\
  adds a new target at pos


* `clear_targets()`\
  remove all targets


* `remove_target( pos )`\
  remove target at pos Vector2i or VFNTarget


* `remove_targets( destinations:Array[Vector2i]`\
  remove targets at positions

* `set_modfield( name:String, weight:float )`\
  weights the modfield by weight\
  weight 0 disables the influenz of the modfield\
  weight multiplies the field effort like ...\
  effort += modffield_node_value * field_effort_factor * modfield_weight


* `calculate_threaded( callback = null, kill_existing_thread:bool=true )`\
  starts threaded calculation\
  calls callback after finish when successful


* `stop_calculation()`\
  kills the running calculation thread.\
  Signal calculated will still be called with flag unsuccessful 


* `get_aim_world( global_position:Vector3, clamp:bool=true ) -> int`\
  get the index number of the node where this node is pointing to from world position


* `get_target_world( global_position:Vector3, clamp:bool=true ) -> VFNTarget`\
  gets target for world position global_position, clamp true will clamp position to the map


* `get_vector_world( global_position:Vector3, clamp:bool=true ) -> Vector3`\
  gets movement vector for world position global_position, clamp true will clamp position to the map


* `get_vector_smooth_world( global_position:Vector3, clamp:bool=true  ) -> Vector3`\
  gets movement vector for world position global_position, clamp true will clamp position to the map
  will smooth vector with neighbouring fields

* `get_effort_heatmap() -> Image`\
  visual representation of effort for debug purpose


* `get_penalty_heatmap() -> Image`\
  visual representation of penalties for debug purpose\
  not yet implemented


### VFNModField
Field for modifing pathfinding effort.

**Properties**
* `dynamic:bool = false`\
  field is dynamic and will not be cached

* `upmost:bool = false`\
  when setting penalty only the heighest number will reside

* `boolean:bool = false`\
  this field is boolean, if value is higher then 0.5 node is enabled else node is disabled

**Methods**

* `clear()`\
  clears the field completly


* `set_value( pos:Vector2i, value:float )`\
  sets penalty value on pos


* `set_value_from_world( world_pos:Vector3, value:float, clamp:bool=true )`\
  sets penalty value on world pos


* `add_value( pos:Vector2i, value:float )`\
  adds penalty value on pos


* `add_value_from_world( world_pos:Vector3, value:float, clamp:bool=true )`\
  adds penalty value on world pos


* `get_value( pos:Vector2i )`\
  gets penalty value on pos


* `fade( f:float )`\
  fades every value in the field, multiplys the value by f


* `blur_fade( f:float )`\
  blurs the neighbouring fields and\
  fades every value in the field, multiplys the value by f


### VFNConnection
Connection between fields

**Properties**
* `node_b:VFNNode`\
  the other node

* `effort:float = 0`\
  effort to walk this connection (mostly the distance)

* `steepness:float = 0`\
  the connections steepness

* `disabled:bool = false`\
  connections is disabled or not

