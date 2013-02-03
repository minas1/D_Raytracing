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
	Array!Surface objects;	// objects in the scene
	Array!Light lights;		// lights in the scene
	
	/*private*/ BVHNode root;			// root node of the BVH tree
	
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
		import std.stdio;
		writeln("In preCalc()");
		
		auto surfaces = new Surface[objects.length];
		for(auto i = 0; i < objects.length; ++i)
			surfaces[i] = objects[i];
		
		writeln("Finished allocating array for the surfaces.");
		root = createBVHTree(surfaces);
		
		writeln("The BVH tree has been successfully created.");
	}
}

private alias const ref Vector3!double vecD;
private alias const ref Vector3!float vecF;
void addAreaLight(ref Scene scene, vecD pos, vecF I, int numberOfLights = 9, double distanceBetweenLights = 0.1, Vector3!double v = Vector3!double(1, 0, 0), Vector3!double u = Vector3!double(0, 1, 0))
{
	import std.math, std.random;
	int lightsOnEachVec = cast(int)ceil(sqrt(cast(float)numberOfLights));
	
	v.normalize();
	u.normalize();
	
	Light l = void;
	l.I = Vector3!float(I.x / numberOfLights, I.y / numberOfLights, I.z / numberOfLights);
	
	double e1 = 0.0, e2 = void;
	for(int i = 0; i < lightsOnEachVec; ++i, e1 += distanceBetweenLights)
	{
		e2 = 0.0;
		for(int j = 0; j < lightsOnEachVec; ++j, e2 += distanceBetweenLights)
		{
			l.position = pos +
					v * (e1 + uniform(0.0, distanceBetweenLights)) +
					u * (e2 + uniform(0.0, distanceBetweenLights));
			
			scene.lights.insert(l);
		}
	}
}