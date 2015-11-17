Raytracing in D
========

A (very) simple raytracer written in the D programming language.

Features
----
   - Smooth shadows
   - Anti-aliasing
   
Prerequisites
----
   - [DMD D compiler]

How to run
----
* Open a terminal in the ```source``` directory.
* Execute ```rdmd main.d```

After about 25" the image below will appear.

![Alt text](/screenshots/raytracing.png?raw=true "Example plot")

Internals
----
The raytracer builds a [Bounding Volume Hierarchy] from the objects in the scene. This helps a lot since when testing for ray interesctions, not all objects have to checked. The BVH Tree is data structure is defined and created in [BVH.d].

License
----

MIT

 [DMD D compiler]:http://dlang.org/download.html
[Bounding Volume Hierarchy]:http://en.wikipedia.org/wiki/Bounding_volume_hierarchy
[BVH.d]:https://github.com/minas1/D_Raytracing/blob/master/raytracing/raytracing/surfaces/bvh.d
