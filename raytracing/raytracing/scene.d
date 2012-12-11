module raytracing.scene;

import std.container;

import raytracing.surface;

struct Scene
{	
	private Array!Surface objects;
	
	this(size_t reserveSpace = 10)
	{
		objects.reserve(reserveSpace);
	}
	
	/// adds a surface into the scene
	void add(Surface s)
	{
		objects.insert(s);
	}
}