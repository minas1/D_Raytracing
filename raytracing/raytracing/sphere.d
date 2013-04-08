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
	Vector3!double center;
	double radius;
	
	this()
	{
	}
	
	this(ref Vector3!double _center, double _radius)
	{
		center = _center;
		radius = _radius;
	}
	
	this(Vector3!double _center, double _radius)
	{
		center = _center;
		radius = _radius;
	}
	
	this(double cX, double cY, double cZ, double _radius)
	{
		center.x = cX;
		center.y = cY;
		center.z = cZ;
		
		radius = _radius;
	}
	
	override bool hit(const ref Ray r, double p0, double p1, ref HitInfo hitInfo)
	{
		Vector3!double eMinusC = r.e - center;
		double dot_d_eMinusC = dot(r.d, eMinusC);
		
		auto discriminant = dot_d_eMinusC * dot_d_eMinusC - dot(r.d, r.d) * (dot(eMinusC, eMinusC) - radius * radius);
		if( discriminant >= 0 )
		{
			//double t1 = (dot(-d, e-c) + sqrt(discriminant)) / dot(d, d);
			double t2 = (dot(-r.d, eMinusC) - sqrt(discriminant)) / dot(r.d, r.d);
			
			// TODO: don't forget to change this if needed
			if( t2 < p0 || t2 > p1 )
				return false;
			
			hitInfo.t = t2;
			hitInfo.hitPoint = r.e + r.d * t2;
			hitInfo.ray = r.d;
			hitInfo.surfaceNormal = (hitInfo.hitPoint - center) * 2;
			hitInfo.hitSurface = this;
		}
		
		return discriminant >= 0;
	}
	
	override Box boundingBox() const
	{
		auto min = Vector3!double(center.x - radius, center.y - radius, center.z - radius);
		auto max = Vector3!double(center.x + radius, center.y + radius, center.z + radius);
		
		Box b = {min, max};
		
		return b;
	}
	
	override Vector3!float shade(const ref HitInfo hitInfo, ref Scene scene) const
	{
		return material.shade(hitInfo, scene);
	}
	
	/// returns true when this Sphere intersects with the Sphere s
	bool intersects(const ref Sphere s)
	{
		double distance = sqrt(	(center.x - s.center.x) * (center.x - s.center.x) +
								(center.y - s.center.y) * (center.y - s.center.y) +
								(center.z - s.center.z) * (center.z - s.center.z));
		
		return distance <= radius + s.radius;
	}
}
