module raytracing.scene;

import std.container;

import raytracing.ray;
import raytracing.surfaces.surface;
import raytracing.light;
import raytracing.box;
import raytracing.surfaces.bvh;
import raytracing.vector;

/// Represents a scene which contains Object and Lights
struct Scene
{
	Array!Surface objects;			/// objects in the scene
	Array!Light lights;				/// lights in the scene

	Vector3!float defaultColor;		/// color added to a pixel when there was not ray hit

	private BVHNode root;			// root node of the BVH tree
	
	@disable this(); // disable the default constructor because space needs to be reserved for objects and lights
	
	this(size_t objectReserveSpace = 20, size_t lightReserveSpace = 3)
	{
		objects.reserve(objectReserveSpace);
		lights.reserve(lightReserveSpace);

		defaultColor = Vector3!float(0.5f, 0.5f, 0.5f);
	}

	/** Traces a ray
	 * Returns: True if the ray hit an object, false if it didn't hit anything
	 * Params:
	 * 	ray = The ray to trace
	 * 	hitInfo = Information about the (possible) hit
	 * 	t0 = Minimum distance to accept hits. Should be a small value. Default is 0.01
	 * 	t1 = Maximum distance to accept hits. Default is 1_000_000
	 * 
	 */
	bool trace(const ref Ray ray, ref HitInfo hitInfo, double t0 = 0.01, double t1 = 1_000_000)
	{
		HitInfo	closestHitInfo;	// hitInfo of the closest object
		closestHitInfo.t = double.max;

		root.hit(ray, t0, t1, closestHitInfo);
		//traceAll(ray, hitInfo, t0, closestHitInfo); // uncomment this line to run without using the BVH tree structure
		
		hitInfo = closestHitInfo;
		
		return closestHitInfo.hitSurface !is null;
	}
	
	/// trace a ray with all objects
	private void traceAll(const ref Ray ray, ref HitInfo hitInfo, double t0, ref HitInfo closestHitInfo)
	{
		for(int i = 0; i < objects.length; ++i)
		{
			// TODO: change the 1_000_000 to something else, preferably not hardcoded
			if( objects[i].hit(ray, t0, 1_000_000, hitInfo) && hitInfo.t < closestHitInfo.t && hitInfo.t > t0) // hit?
			{
				closestHitInfo = hitInfo;
			}
		}
	}

	/// Creates the BVH tree for this scene
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
		writeln("BVH tree created in ", watch.peek().nsecs / 1_000_000.0, " ms");
	}
}