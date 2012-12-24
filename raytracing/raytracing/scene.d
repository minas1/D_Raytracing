module raytracing.scene;

import std.container;

import raytracing.ray;
import raytracing.surface;
import raytracing.light;

struct Scene
{
	Array!Surface objects;	// objects in the scene
	Array!Light lights;		// lights in the scene
	
	this(size_t objectReserveSpace = 10, size_t lightReserveSpace = 3)
	{
		objects.reserve(objectReserveSpace);
		lights.reserve(lightReserveSpace);
	}
	
	bool trace(const ref Ray ray, ref HitInfo hitInfo, float t0)
	{
		HitInfo	closestHitInfo;	// hitInfo of the closest object
		float t = float.max;	// the minimum t
		
		foreach(obj; objects)
		{
			if( obj.hit(ray, t0, 1000, hitInfo) && hitInfo.t < t && hitInfo.t > t0) // hit?
			{
				t = hitInfo.t;
				closestHitInfo = hitInfo;
			}
		}
		
		hitInfo = closestHitInfo;
		
		return closestHitInfo.hitSurface !is null;
	}
}