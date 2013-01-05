module raytracing.triangle;

import raytracing.vector;
import raytracing.surface;
import raytracing.scene;
import raytracing.box;
import raytracing.ray;
import raytracing.material;

import std.algorithm;
import std.math;

/**
 * Represents a Triangle.
 * Note: The vertices must be clock-wise (RIGHT handed coordinate system)
 */
class Triangle : Surface
{
	Material material;
	Vector3 a, b, c;
	
	this()
	{
	}
	
	this(const ref Vector3 _a, const ref Vector3 _b, const ref Vector3 _c)
	{
		a = _a;
		b = _b;
		c = _c;
	}
	
	this(float aX, float aY, float aZ, float bX, float bY, float bZ, float cX, float cY, float cZ)
	{
		a.x = aX;
		a.y = aY;
		a.z = aZ;
		
		b.x = bX;
		b.y = bY;
		b.z = bZ;
		
		c.x = cX;
		c.y = cY;
		c.z = cZ;
	}
	
	bool hit(const ref Ray r, float p0, float p1, ref HitInfo hitInfo)
	{
		// (e + td - a) . n = 0
		// ... t(d.n) + e.n - a.n = 0
		// we need to solve as t to find the solution
		// t = (dot(a, n) - dot(e, n)) / dot(d, n);
		// and because dot product is distributive,
		// we can write t = dot(a-e,n) / dot(d,n)

		Vector3 temp0 = b-a, temp1 = c-a;
		Vector3 n = cross(temp0, temp1); // calculate the normal of the plane that the triangle is on
		n.normalize();
		
		// TODO: r.d may have to be normalized?
		
		// if the normal and the ray are parallel, there's no intersection
		float dDotN = dot(r.d, n);
		
		// TODO: this might be causing accuracy problems. I should check it out
		if( dDotN == 0 )
			return false;
		
		// find the intersection point P with the plane
		const Vector3 aMinusR = a-r.e;
		float t = dot(aMinusR, n) / dDotN;
		Vector3 p = r.e + r.d * t;
		
		// now we need to test if the point is inside the triangle
		
		// 1) test if its in the negative subspace of vector ab
		Vector3 ab = b-a;
		Vector3 ap = p-a;
		Vector3 c1 = cross(ab, ap);
		c1.normalize();
		
		Vector3 ac = c-a;
		Vector3 c2 = cross(ab, ac);
		c2.normalize();
		
		immutable E = 0.01f;
		
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z-c2.z) > E )
			return false;
		
		// 2) test if its in the negative subspace of vector bc
		Vector3 bc = c-b;
		Vector3 bp = p-b;
		c1 = cross(bc, bp);
		c1.normalize();
		
		Vector3 ba = b-a;
		c2 = cross(ba, bc);
		c2.normalize();
		
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z-c2.z) > E)
			return false;	
		
		// 3) test if its in the negative subspace of vector ca
		Vector3 ca = a-c;
		Vector3 cp = p-c;
		c1 = cross(ca, cp);
		c1.normalize();
		
		Vector3 cb = b-c;
		c2 = cross(ca, cb);
		c2.normalize();
		
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z - c2.z) > E )
			return false;
		
		hitInfo.t = t;
		hitInfo.hitPoint = p;
		hitInfo.surfaceNormal = n;
		hitInfo.hitSurface = this;
		
		return true;
	}
	
	Box boundingBox() const
	{
		Box box = void;
		
		box.min = Vector3(min(a.x, b.x, c.x), min(a.y, b.y, c.y), min(a.z, b.z, c.z));
		box.max = Vector3(max(a.x, b.x, c.x), max(a.y, b.y, c.y), max(a.z, b.z, c.z));
		
		return box;
	}
	
	Vector3 shade(const ref HitInfo hitInfo, ref Scene scene) const
	{
		return material.shade(hitInfo, scene);
	}
}