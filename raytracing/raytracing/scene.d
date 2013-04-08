module raytracing.scene;

import std.container;

import raytracing.ray;
import raytracing.surface;
import raytracing.light;
import raytracing.box;
import raytracing.bvh;
import raytracing.vector;

struct Scene
{
	Array!Surface objects;			// objects in the scene
	Array!Light lights;				// lights in the scene
	
	private BVHNode root;			// root node of the BVH tree
	
	@disable this(); // disable the default constructor because space needs to be reserved for objects and lights
	
	this(size_t objectReserveSpace = 20, size_t lightReserveSpace = 3)
	{
		objects.reserve(objectReserveSpace);
		lights.reserve(lightReserveSpace);
	}
	
	bool trace(const ref Ray ray, ref HitInfo hitInfo, double t0)
	{
		HitInfo	closestHitInfo;	// hitInfo of the closest object
		closestHitInfo.t = double.max;

		root.hit(ray, t0, 1000, closestHitInfo);
		//traceAll(ray, hitInfo, t0, closestHitInfo); // uncomment this line to run without using the BVH tree structure
		
		hitInfo = closestHitInfo;
		
		return closestHitInfo.hitSurface !is null;
	}
	
	/// trace all rays with all objects
	private void traceAll(const ref Ray ray, ref HitInfo hitInfo, double t0, ref HitInfo closestHitInfo)
	{
		for(int i = 0; i < objects.length; ++i)
		{
			// TODO: change the 1000 to something else, preferably not hardcoded
			if( objects[i].hit(ray, t0, 1000, hitInfo) && hitInfo.t < closestHitInfo.t && hitInfo.t > t0) // hit?
			{
				closestHitInfo = hitInfo;
			}
		}
	}
	
	void preCalc()
	{
		import std.stdio, std.datetime;
		
		StopWatch watch;
		watch.start();
		
		auto surfaces = new Surface[objects.length];
		for(auto i = 0; i < objects.length; ++i)
			surfaces[i] = objects[i];
		
		root = createBVHTree(surfaces);
		
		watch.stop();
		writeln("The BVH tree has been successfully created in ", watch.peek().nsecs / 1_000_000.0, " ms");
	}
}