# Godot-4-VectorFieldNavigation

**This project is currently in an early stage. Please report any issues you encounter! Comments and suggestions also appreciated !**

<img style="width:33%;float:left;margin-right: 2em; vertical-align:top" src="https://github.com/D2klaas/Godot-4-VectorFieldNavigation/blob/main/addons/VectorFieldNavigation/vfn_icon.svg?raw=true"/>

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

[Documentation](/addons/VectorFieldNavigation/docs/DOCUMENTATION.md)

## Improving AI movement with modfields

The modfields have great potential to improve the ais behaviour.\
Let's assume youhave a game where countless hordes of zombies attacking. You, a solider, have to defend your fortifikation.

Usually a pathfinding algorythm provides allways the path with the least effort ... usually the shortes path from a to b.

![one](/addons/VectorFieldNavigation/docs/ex_spreading_forces_1.jpg)

in this example this leads directly into the kill zone ... the narrow obstacles also line them up, ready to get slaughterd.

![one](/addons/VectorFieldNavigation/docs/ex_spreading_forces_2.jpg)

If you use a dynamic modfield, lets name it "occupy_field" and constantly add a small mount of effort to it for each zombies location (pink) 
you are increasing the effort to pathes allready favored by some zombies. This diverts other zombies to avoid the heavly 
used path of the others, leading to much more divers attack pattern.\

![one](/addons/VectorFieldNavigation/docs/ex_spreading_forces_3.jpg)

To unblock the favorised pathes you can call fade() on the modfield to slowly diminish the increased effort, giving way for another 
attack on this line.

This technic can also be used for other purposes. Maybe you have placed some turrets on tactical locations, gunning down the zombies from there
spawnpoint to the fortification. Add a dynamic modfield "killzone_field", whenever a zombie gets killed mark the place with a penalty. After
enough casulties the zombies will avoid this area and try to find a way around. If there is no other way, well, then they will walk on despite the danger.

Also open fields could penaliest over soft or hardcover fields. Making this dependent on range and orientation to the player, enemies will get pretty 
clever in there movement, making them activly avoid getting gunned down.

Modfields bring a wide range of easy to use possibilities to pathfinding and ai. The examples above could be refined to bring even more complex
ai behaviour into play.
