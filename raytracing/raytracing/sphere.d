module raytracing.sphere;

import std.stdio;
import std.math;

import raytracing.surface;
import raytracing.ray;
import raytracing.box;
import raytracing.vector;
import raytracing.material;
import raytracing.scene;

class Sphere : Surface
{
	Material material;
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
	
	bool hit(const Ray r, float p0, float p1, ref HitInfo hitInfo) const
	{
		Vector3 d = r.d, e = r.e, c = center;
		
		float discriminant = dot(d, e-c) * dot(d, e-c) - dot(d, d) * (dot(e-c, e-c) - radius * radius);
		if( discriminant >= 0 )
		{
			//float t1 = (dot(-d, e-c) + sqrt(discriminant)) / dot(d, d);
			float t2 = (dot(-d, e-c) - sqrt(discriminant)) / dot(d, d);
			
			// TODO: don't forget to change this if needed
			if( t2 < p0 || t2 > p1 )
				return false;
			
			hitInfo.t = t2;
			hitInfo.hitPoint = e + d * t2;
			hitInfo.ray = d;
			hitInfo.surfaceNormal = (hitInfo.hitPoint - c) * 2;
		}
		
		return discriminant >= 0; // TODO: implement
	}
	
	Box boundingBox() const
	{
		Vector3 min = {center.x - radius * 0.5f, center.y - radius * 0.5f, center.z - radius * 0.5f};
		Vector3 max = {center.x + radius * 0.5f, center.y + radius * 0.5f, center.z + radius * 0.5f};
		
		Box b = {min, max};
		
		return b;
	}
	
	Vector3 shade(HitInfo hitInfo, ref Scene scene) const
	{
		return material.shade(hitInfo, scene);
	}
}