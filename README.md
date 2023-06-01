# Godot-4-VectorFieldNavigation

This addon add's another pathfinding system besides astar and navmesh-navigation.

Vector field navigation is espacialy usefull for large hordes or particle pathfinding.

When you have many entities that should navigate to one (or many) targets you can either 
calculate a path for every entity or group those entities and share one path for all.
Calculating a path for hundreds of entities can hit your performance substantially. Most of the time
all calculated paths merge into one optimal path. When all entities march this path and 
tick of their navigation points they often push each other away from those points. This leads to 
ugly movements at choke points. Sure this can be optimized but this comes at an additional
cost.

Vectorfield navigation (VFN) calculates a navigation solution for all cells (nodes) of a grid based
map.

This VFN addon implements a planar(2D/3D) solution wich can be used in 3D space. Currently it does not 
support underpaths, bridges or alike. This may be change in future realases, but a real 3D node based 
solution is more complex and will not be as performant as a "2D" solution.

## Features:
* multipy solutions with different modifiers for a single map
* threaded calculation for stutter free usage
* map preperation tools (e.g. use heightmaps)
* fast (as gdscript can)
* connection-cache (+10% performance)
* flexible modifier layers for static or dynamic movement penalties

## Install
Download files and add them to your addons folder in your godot project.\
Enable the plugin in project-settings.

## Usage
### map
Create a VFNMap-node in your scene-tree
You can use the buildin heightmap or initialize the map via scripting.
(Have look in the example script)

**!! DO NOT MODIFY THE MAP WHILE CALCULATING A SOLUTION !!** this can result in chrashes

### ModFields
ModFields modifing the effort to reach a node. Its mostly a penalty for a node like rough terrain, rubble, dangerous (fire, acid, gunfire), blocked etc.
ModFields can be static or dynamic. Static ModFields can be cached but dynamic one's not.
ModFields can be numeric or boolean. Numerics will be added to the effort while booleans will block the access completly.

** modifying the modfield while calcualting a solution can result in undesired results **

## Field
The VFN-field stores the target-nodes and calculates the field solution and provides methodes to read the movement vector. Each map can have many fields. 
Each fields has a set of factors to modify the weighting of the calculation (different entities may have different movement penalties).




