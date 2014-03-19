Raytracing in D
========

A (very) simple raytracer written in the D programming language.

Features
----
   - Smooth shadows
   - Anti-aliasing
   - Parallel calculation using threads (if available)
   
Prerequisites
----
   - D compiler
   - Derelict2 (SDL bindings for D)

Internals
----
The raytracer builds a [Bounding Volume Hierarchy] from the objects in the scene. This helps a lot since when testing for ray interesctions, not all objects have to checked. The BVH Tree is data structure is defined and created in [BVH.d].

License
----

MIT


[Bounding Volume Hierarchy]:http://en.wikipedia.org/wiki/Bounding_volume_hierarchy
[BVH.d]:https://github.com/minas1/D_Raytracing/blob/master/raytracing/raytracing/surfaces/bvh.d
