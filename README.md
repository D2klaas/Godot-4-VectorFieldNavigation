# Godot-4-VectorFieldNavigation

**This project is currently in an early stage. Please report any issues you encounter! Comments and suggestions also appreciated !**

<img style="width:33%;float:left" src="https://github.com/D2klaas/Godot-4-VectorFieldNavigation/blob/main/addons/VectorFieldNavigation/vfn_icon.svg?raw=true"/>
This addon add's another pathfinding method besides astar and navmesh-navigation to Godot 4.

Vector field navigation is espacialy usefull for large hordes or particle pathfinding.

When you have many entities that should navigate to one (or many) targets you can either 
calculate a path for every entity or group those entities and share one path for all.
Calculating a path for hundreds of entities can hit your performance substantially. Most of the time
all calculated paths merge into one optimal path. When all entities march this path and 
tick of their navigation points they often push each other away from those points. This leads to 
ugly movements at choke points. Sure this can be optimized but this comes at an additional
cost.

Vectorfield navigation (VFN) calculates a navigation solution for all cells (nodes) of a grid based
map. Therefor i doesn't matter where the entity is positioned, there is allways a path to a target and
therefor the entity dont have to walk predefined waypoints.

![alt text](https://github.com/D2klaas/Godot-4-VectorFieldNavigation/blob/main/addons/VectorFieldNavigation/examples/screenshot.jpg?raw=true)

This VFN addon implements a planar(2D/3D) solution wich can be used in 3D space. Currently it does not 
support underpaths, bridges or alike. This may be change in future realases, but a real 3D node based 
solution is more complex and will not be as performant as a "2D" solution. The performance is quit good,
a 128 x 128 grid with medium complexity will compute in around 130ms on a AMD Ryzen 5. Even on low end
devices its about 350ms. This means you can constantly track a target and receive at least 2 updates per second.
One of the cool features of this algorythm is that the number of targets does not hit the performance.

## Features:
* multipy solutions with different modifiers for a single map
* threaded calculation for stutter free usage
* map preperation tools (e.g. use heightmaps)
* reasonable fast (as gdscript can)
* connection-cache (+10% performance)
* flexible modifier layers for static or dynamic movement penalties
* serialisation for easy storage of pre-processed maps

## Install
Download files and add them to your addons folder in your godot project.\
Enable the plugin in project-settings.

## Usage
A short overview

### Map
Create a VFNMap-node in your scene-tree
You can use the build-in heightmap or initialize the map via scripting.
(Have look in the example script)

**!! DO NOT MODIFY THE MAP WHILE CALCULATING A SOLUTION !!** this can result in chrashes

### ModFields
ModFields modifing the effort to reach a node. Its mostly a penalty for a node like rough terrain, rubble, dangerous (fire, acid, gunfire), blocked etc.
ModFields can be static or dynamic. Static ModFields can be cached but dynamic one's not.
ModFields can be numeric or boolean. Numerics will be added to the effort while booleans will block the access completly.

**modifying the modfield while calcualting a solution can result in undesired results**

## Field
The VFN-field stores the target-nodes and calculates the field solution and provides methodes to read the movement vector. Each map can have many fields. 
Each fields has a set of factors to modify the weighting of the calculation (different entities may have different movement penalties).

## DOCS

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


* `get_value( pos:Vector2i )`\
  gets penalty value on pos


* `fade( f:float )`\
  fades every value in the field, multiplys the value by f


* `blur_fade( f:float )`\
  **not implemented yet**
  fades every value in the field, multiplys the value by f\
  blurs the neighbouring fields


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

