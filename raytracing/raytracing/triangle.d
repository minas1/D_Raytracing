module raytracing.triangle;

import raytracing.vector;
import raytracing.surface;
import raytracing.scene;
import raytracing.box;
import raytracing.ray;
import raytracing.material;

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
		//std.stdio.writeln("hit called()");
		
		// (e + td - a) . n = 0
		// ... t(d.n) + e.n - a.n = 0
		// we need to solve as t to find the solution
		// t = (dot(a, n) - dot(e, n)) / dot(d, n);
		// and because dot product is distributive,
		// we can write t = dot(a-e,n) / dot(d,n)
		
		Vector3 n = cross(b-a, c-a); // calculate the normal of the plane that the triangle is on
		n.normalize();
		
		// if the normal and the ray are parallel, there's no intersection
		float dDotN = dot(r.d, n);
		/*std.stdio.writeln("----------------");
		std.stdio.writeln("ray = (", r.e, ",", r.d, ")");
		std.stdio.writeln("dot(d, n) = ", dDotN);*/
		
		if( dDotN == 0 )
			return false;
		
		// find the intersection point P with the plane
		float t = dot(a-r.e, n) / dDotN;
		Vector3 p = r.e + r.d * t;
		
		//std.stdio.writeln("p = ", r.e + r.d * t);
		
		// now we need to test if the point is inside the triangle
		
		// 1) test if its in the negative subspace of vector ab
		Vector3 ab = b-a;
		Vector3 ap = p-a;
		Vector3 c1 = cross(ab, ap);
		c1.normalize();
		
		/*std.stdio.writeln("ab = ", ab);
		std.stdio.writeln("ap = ", p, " - ", a, " = ", ap);
		std.stdio.writeln("c1 = ", c1);*/
		
		Vector3 ac = c-a;
		Vector3 c2 = cross(ab, ac);
		c2.normalize();
		
		immutable E = 0.01f;
		
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z-c2.z) > E )
		{
			//std.stdio.writefln("Returning from test 1/3. %s == %s, %s == %s, %s == %s", c1.x, c2.x, c1.y, c2.y, c1.z, c2.z);
			return false;
		}
		
		// 2) test if its in the negative subspace of vector bc
		Vector3 bc = c-b;
		Vector3 bp = p-b;
		c1 = cross(bc, bp);
		c1.normalize();
		
		//std.stdio.writeln("bc = ", bc);
		//std.stdio.writeln("bp = ", p, " - ", b, " = ", bp);
		//std.stdio.writeln("c1 = ", c1);
		
		Vector3 ba = b-a;
		c2 = cross(ba, bc);
		c2.normalize();
		
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z-c2.z) > E)
		{
			//std.stdio.writefln("c1.z = %.20s", c1.z);
			//std.stdio.writefln("c2.z = %.20s", c2.z);
			//std.stdio.writefln("Returning from test 2/3. %s == %s, %s == %s, %s == %s", c1.x, c2.x, c1.y, c2.y, c1.z, c2.z);
			return false;	
		}
		
		// 3) test if its in the negative subspace of vector ca
		Vector3 ca = a-c;
		Vector3 cp = p-c;
		c1 = cross(ca, cp);
		c1.normalize();
		
		Vector3 cb = b-c;
		c2 = cross(ca, cb);
		c2.normalize();
		
		if( abs(c1.x - c2.x) > E || abs(c1.y - c2.y) > E || abs(c1.z - c2.z) > E )
		{
			//std.stdio.writefln("Returning from test 3/3. %s == %s, %s == %s, %s == %s", c1.x, c2.x, c1.y, c2.y, c1.z, c2.z);
			return false;
		}
		
		hitInfo.t = t;
		hitInfo.hitPoint = p;
		hitInfo.surfaceNormal = n;
		hitInfo.hitSurface = this;
		
		return true;
	}
	
	Box boundingBox() const
	{
		Box b;
		return b;
	}
	
	Vector3 shade(HitInfo hitInfo, ref Scene scene) const
	{
		return material.shade(hitInfo, scene);
	}
}