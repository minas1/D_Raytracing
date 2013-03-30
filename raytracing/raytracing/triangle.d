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
	Vector3!double a, b, c;
	
	this()
	{
	}
	
	this(Vector3!double _a, Vector3!double _b, Vector3!double _c)
	{
		a = _a;
		b = _b;
		c = _c;
	}
	
	this(ref Vector3!double _a, ref Vector3!double _b, ref Vector3!double _c)
	{
		a = _a;
		b = _b;
		c = _c;
	}
	
	this(double aX, double aY, double aZ, double bX, double bY, double bZ, double cX, double cY, double cZ)
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
	
	override bool hit(const ref Ray r, double p0, double p1, ref HitInfo hitInfo)
	{
		// (e + td - a) . n = 0
		// ... t(d.n) + e.n - a.n = 0
		// we need to solve as t to find the solution
		// t = (dot(a, n) - dot(e, n)) / dot(d, n);
		// and because dot product is distributive,
		// we can write t = dot(a-e,n) / dot(d,n)

		Vector3!double temp0 = b-a, temp1 = c-a;
		Vector3!double n = cross(temp0, temp1); // calculate the normal of the plane that the triangle is on
		n.normalize();
		
		// TODO: r.d may have to be normalized?
		
		// if the normal and the ray are parallel, there's no intersection
		auto dDotN = dot(r.d, n);
		
		// TODO: this might be causing accuracy problems. I should check it out
		if( dDotN == 0 )
			return false;
		
		// find the intersection point P with the plane
		auto aMinusR = a-r.e;
		auto t = dot(aMinusR, n) / dDotN;
		Vector3!double p = r.e + r.d * t;
		
		// if t is zero means that the r.e is on the triangle. We must return false here
		// because if we don't then rays that are tested for shadows will always hit their own surface!
		if( t < 0.000001 )
			return false;
		
		//import std.stdio;
		//writefln("t = %.25f", t);
		
		// now we need to test if the point is inside the triangle
		
		// 1) test if its in the negative subspace of vector ab
		auto ab = b-a;
		auto ap = p-a;
		auto c1 = cross(ab, ap);
		c1.normalize();
		
		auto ac = c-a;
		auto c2 = cross(ab, ac);
		c2.normalize();
		
		immutable E = 0.01;
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z-c2.z) > E )
			return false;
		
		// 2) test if its in the negative subspace of vector bc
		auto bc = c-b;
		auto bp = p-b;
		c1 = cross(bc, bp);
		c1.normalize();
		
		auto ba = b-a;
		c2 = cross(ba, bc);
		c2.normalize();
		
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z-c2.z) > E)
			return false;	
		
		// 3) test if its in the negative subspace of vector ca
		auto ca = a-c;
		auto cp = p-c;
		c1 = cross(ca, cp);
		c1.normalize();
		
		auto cb = b-c;
		c2 = cross(ca, cb);
		c2.normalize();
		
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z - c2.z) > E )
			return false;
		
		hitInfo.t = t;
		hitInfo.hitPoint = p;
		hitInfo.surfaceNormal = n;
		hitInfo.hitSurface = this;
		hitInfo.ray = r.d;
		
		//import std.stdio;
		//writeln("in triangle hit");
		
		return true;
	}
	
	override Box boundingBox() const
	{
		auto min = Vector3!double(min(a.x, b.x, c.x), min(a.y, b.y, c.y), min(a.z, b.z, c.z));
		auto max = Vector3!double(max(a.x, b.x, c.x), max(a.y, b.y, c.y), max(a.z, b.z, c.z));
		
		Box b = {min, max};
		return b;
	}
	
	override Vector3!float shade(const ref HitInfo hitInfo, ref Scene scene) const
	{
		//import std.stdio;
		//writeln("in Triangle.shade()");
		//writeln("surface normal = ", hitInfo.surfaceNormal);
		
		return material.shade(hitInfo, scene);
	}
}
