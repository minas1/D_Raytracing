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
	
	this(float cX, float cY, float cZ, float _radius)
	{
		center.x = cX;
		center.y = cY;
		center.z = cZ;
		
		radius = _radius;
	}
	
	override bool hit(const ref Ray r, float p0, float p1, ref HitInfo hitInfo)
	{
		Vector3 d = r.d, e = r.e, c = center;
		Vector3 eMinusC = e-c;
		
		float discriminant = dot(d, eMinusC) * dot(d, eMinusC) - dot(d, d) * (dot(eMinusC, eMinusC) - radius * radius);
		if( discriminant >= 0 )
		{
			const Vector3 minusD = -d;
			//float t1 = (dot(-d, e-c) + sqrt(discriminant)) / dot(d, d);
			float t2 = (dot(minusD, eMinusC) - sqrt(discriminant)) / dot(d, d);
			
			// TODO: don't forget to change this if needed
			if( t2 < p0 || t2 > p1 )
				return false;
			
			hitInfo.t = t2;
			hitInfo.hitPoint = e + d * t2;
			hitInfo.ray = d;
			hitInfo.surfaceNormal = (hitInfo.hitPoint - c) * 2;
			hitInfo.hitSurface = this;
		}
		
		return discriminant >= 0; // TODO: implement
	}
	
	override Box boundingBox() const
	{
		Vector3 min = Vector3(center.x - radius, center.y - radius, center.z - radius);
		Vector3 max = Vector3(center.x + radius, center.y + radius, center.z + radius);
		
		Box b = {min, max};
		
		return b;
	}
	
	override Vector3 shade(const ref HitInfo hitInfo, ref Scene scene) const
	{
		return material.shade(hitInfo, scene);
	}
	
	/// returns true when this Sphere intersects with the Sphere s
	bool intersects(const ref Sphere s)
	{
		float distance = sqrt(	(center.x - s.center.x) * (center.x - s.center.x) +
								(center.y - s.center.y) * (center.y - s.center.y) +
								(center.z - s.center.z) * (center.z - s.center.z));
		
		return distance <= radius + s.radius;
	}
}
