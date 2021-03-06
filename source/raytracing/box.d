module raytracing.box;

import raytracing.vector;
import raytracing.ray;

import std.stdio;
import std.algorithm;

/// An axis aligned bounding box
struct Box
{
	Vector3!double min, max;

	bool isPointInside(const ref Vector3!double v) const @safe pure nothrow
	{
		return v.x >= min.x && v.y >= min.y && v.z >= min.z
			&& v.x <= max.x && v.y <= max.y && v.z <= max.z;
	}
	
	bool isPointInside(double x, double y, double z) const @safe pure nothrow
	{
		return x >= min.x && y >= min.y && z >= min.z
			&& x <= max.x && y <= max.y && z <= max.z;
	}
	
	bool intersects(const ref Ray r) const @safe pure nothrow
	{
		auto a = Vector3!double(1/r.d.x, 1/r.d.y, 1/r.d.z);
		Vector3!double tMin = void, tMax = void;
		
		// x
		if( a.x >= 0.0 )
		{
			tMin.x = a.x * (min.x - r.e.x);
			tMax.x = a.x * (max.x - r.e.x);
		}
		else
		{
			tMin.x = a.x * (max.x - r.e.x);
			tMax.x = a.x * (min.x - r.e.x);
		}
		
		// y
		if( a.y >= 0.0 )
		{
			tMin.y = a.y * (min.y - r.e.y);
			tMax.y = a.y * (max.y - r.e.y);
		}
		else
		{
			tMin.y = a.y * (max.y - r.e.y);
			tMax.y = a.y * (min.y - r.e.y);
		}
		
		// z
		if( a.z >= 0.0 )
		{
			tMin.z = a.z * (min.z - r.e.z);
			tMax.z = a.z * (max.z - r.e.z);
		}
		else
		{
			tMin.z = a.z * (max.z - r.e.z);
			tMax.z = a.z * (min.z - r.e.z);
		}
		
		if( tMin.x > tMax.y || tMin.x > tMax.z || tMin.y > tMax.x || tMin.y > tMax.z || tMin.z > tMax.x || tMin.z > tMax.y)
			return false;
		
		return true;
	}
}

/// Combines two boxes and returns their combination
Box combine(const ref Box b1, const ref Box b2) @safe pure nothrow
{
	Box box = {
			Vector3!double(min(b1.min.x, b2.min.x), min(b1.min.y, b2.min.y), min(b1.min.z, b2.min.z)),
			Vector3!double(max(b1.max.x, b2.max.x), max(b1.max.y, b2.max.y), max(b1.max.z, b2.max.z))};
	
	return box;
}
