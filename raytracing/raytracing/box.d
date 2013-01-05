module raytracing.box;

import raytracing.vector;
import raytracing.ray;
import raytracing.surface;

import std.stdio;

struct Box
{
	Vector3 min, max;

	bool isPointInside(const ref Vector3 v) const
	{
		return v.x >= min.x && v.y >= min.y && v.z >= min.z
			&& v.x <= max.x && v.y <= max.y && v.z <= max.z;
	}
	
	bool isPointInside(float x, float y, float z) const
	{
		return x >= min.x && y >= min.y && z >= min.z
			&& x <= max.x && y <= max.y && z <= max.z;
	}
	
	bool intersects(const ref Ray r) const
	{
		Vector3 n = void,						// normal
				v = void, u = void;				// vectors
		
		float t = void;
		
		// plane 0 (front)
		v = Vector3(max.x, min.y, min.z) - min;
		u = Vector3(min.x, max.y, min.z) - min;
		n = cross(v, u);
		n.normalize();
		t = dot(r.d, n);
		
		/++writeln("t0 = ", t);
		if( t > 0 )
			writeln("plane 0 intersected");
		else
			writeln("plane 0 not intersected");++/
		
		Vector3 temp = min - r.e;
		Vector3 p = r.e + r.d * dot(temp, n) / t;
		//writeln("p0 = ", p);
		if( p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y && p.z >= min.z && p.z <= max.z )
		{
			//writeln("YES 0\n");
			return true;
		}
		/++else
			writeln("NO 0\n");++/
		
		
		// plane 1 (right)
		v = Vector3(max.x, max.y, min.z) - Vector3(max.x, min.y, min.z);
		u = Vector3(max.x, min.y, max.z) - Vector3(max.x, min.y, min.z);
		n = cross(v, u);
		n.normalize();
		
		t = dot(r.d, n);
		/++writeln("t1 = ", t);
		
		if( t > 0 )
			writeln("plane 1 intersected");
		else
			writeln("plane 1 not intersected");++/
		
		temp = Vector3(max.x, min.y, min.z) - r.e;
		p = r.e + r.d * dot(temp, n) / t;
		//writeln("p1 = ", p);
		if( p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y && p.z >= min.z && p.z <= max.z )
		{
			//writeln("YES 1\n");
			return true;
		}
		/++else
			writeln("NO 1\n");++/
		
		// plane 2 (left)
		v = Vector3(min.x, min.y, max.z) - Vector3(min.x, min.y, min.z);
		u = Vector3(min.x, max.y, min.z) - Vector3(min.x, min.y, min.z);
		n = cross(v, u);
		n.normalize();
		
		t = dot(r.d, n);
		/++writeln("t2 = ", t);
		
		if( t > 0 )
			writeln("plane 2 intersected");
		else
			writeln("plane 2 not intersected");++/
		
		temp = Vector3(min.x, min.y, min.z) - r.e;
		p = r.e + r.d * dot(temp, n) / t;
		//writeln("p2 = ", p);
		if( p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y && p.z >= min.z && p.z <= max.z )
		{
			//writeln("YES 2\n");
			return true;
		}
		/++else
			writeln("NO 2\n");++/
		
		// plane 3 (back)
		v = Vector3(max.x, min.y, max.z) - Vector3(min.x, min.y, max.z);
		u = Vector3(min.x, max.y, max.z) - Vector3(min.x, min.y, max.z);
		n = cross(v, u);
		n.normalize();
		
		t = dot(r.d, n);
		/++writeln("t3 = ", t);
		
		if( t > 0 )
			writeln("plane 3 intersected");
		else
			writeln("plane 3 not intersected");++/
		
		temp = Vector3(min.x, min.y, max.z) - r.e;
		p = r.e + r.d * dot(temp, n) / t;
		//writeln("p3 = ", p);
		if( p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y && p.z >= min.z && p.z <= max.z )
		{
			//writeln("YES 3\n");
			return true;
		}
		/++else
			writeln("NO 3\n");++/
		
		// plane 4 (top)
		v = Vector3(min.x, max.y, max.z) - Vector3(min.x, max.y, min.z);
		u = Vector3(max.x, max.y, min.z) - Vector3(min.x, max.y, min.z);
		n = cross(v, u);
		n.normalize();
		
		t = dot(r.d, n);
		/++writeln("t4 = ", t);
		
		if( t > 0 )
			writeln("plane 4 intersected");
		else
			writeln("plane 4 not intersected");++/
		
		temp = Vector3(min.x, max.y, min.z) - r.e;
		p = r.e + r.d * dot(temp, n) / t;
		//writeln("p4 = ", p);
		if( p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y && p.z >= min.z && p.z <= max.z )
		{
			//writeln("YES 4\n");
			return true;
		}
		else
			/++writeln("NO 4\n");++/
		
		// plane 5 (bottom)
		v = Vector3(max.x, min.y, min.z) - Vector3(min.x, min.y, min.z);
		u = Vector3(min.x, min.y, max.z) - Vector3(min.x, min.y, min.z);
		n = cross(v, u);
		n.normalize();
		
		t = dot(r.d, n);
		/++writeln("t5 = ", t);
		
		if( t > 0 )
			writeln("plane 5 intersected");
		else
			writeln("plane 5 not intersected");++/
		
		temp = Vector3(min.x, min.y, min.z) - r.e;
		p = r.e + r.d * dot(temp, n) / t;
		//writeln("p5 = ", p);
		if( p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y && p.z >= min.z && p.z <= max.z )
		{
			//writeln("YES 5\n");
			return true;
		}
		/++else
			writeln("NO 5\n");++/
		
		return false;
	}
}