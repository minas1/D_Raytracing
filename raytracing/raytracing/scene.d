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
	
	// TODO: complete this function
	bool trace(Ray ray, ref HitInfo hitInfo, float t0)
	{
		/*HitInfo hitInfo,
				closestHitInfo;	// hitInfo of the closest object
		Surface closestObject;	// the object that's closest
		float t = float.max;	// the minimum t
		
		foreach(obj; scene.objects)
		{
			if( obj.hit(r, 0.1f, 1000, hitInfo) && hitInfo.t < t ) // hit?
			{
				t = hitInfo.t;
				closestObject = obj;
				closestHitInfo = hitInfo;
			}
		}*/
		return false;
	}
}