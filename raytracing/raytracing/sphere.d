module raytracing.sphere;

import raytracing.surface;
import raytracing.ray;
import raytracing.box;
import raytracing.vector;

class Sphere : Surface
{
	Vector3 center;
	float radius;
	
	this()
	{
	}
	
	this(const ref Vector3 _center, float _radius)
	{
		center = _center;
		radius = _radius;
	}
	
	bool hit(const ref Ray r, float t0, float t1, ref HitInfo hitInfo) const
	{
		return false; // TODO: implement
	}
	
	Box boundingBox() const
	{
		Vector3 min = {center.x - radius * 0.5f, center.y - radius * 0.5f, center.z - radius * 0.5f};
		Vector3 max = {center.x + radius * 0.5f, center.y + radius * 0.5f, center.z + radius * 0.5f};
		
		Box b = {min, max};
		
		return b;
	}
}