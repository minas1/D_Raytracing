module raytracing.vector;

import std.math;

struct Vector3(T)
{
	T x, y, z;
	
	this(T _x, T _y, T _z) @safe pure nothrow
	{
		x = _x;
		y = _y;
		z = _z;
	}
	
	// negate operator
	Vector3 opUnary(string s)() const @safe pure nothrow if( s == "-" )
	{
		Vector3 temp = this;
		
		temp.x = -temp.x;
		temp.y = -temp.y;
		temp.z = -temp.z;
		
		return temp;
	}
	
	// + operator for completeness
	Vector3 opUnary(string s)() const @safe pure nothrow if( s == "+" ) 
	{
		return this;
	}
	
	// binary operators
	Vector3 opBinary(string op) (T val) const @safe pure nothrow
	{
		static if( op == "+" )
		{
			Vector3 temp = this;
			temp.x += val;
			temp.y += val;
			temp.z += val;
		}
		else static if( op == "-" )
		{
			Vector3 temp = this;
			temp.x -= val;
			temp.y -= val;
			temp.z -= val;
		}
		else static if( op == "*" )
		{
			Vector3 temp = this;
			temp.x *= val;
			temp.y *= val;
			temp.z *= val;
		}
		else static if( op == "/" )
		{
			Vector3 temp = this;
			temp.x /= val;
			temp.y /= val;
			temp.z /= val;
		}
		
		return temp;
	}
	
	Vector3 opBinary(string op) (Vector3 v) const @safe pure nothrow
	{
		static if( op == "+" )
		{
			Vector3 temp = this;
			temp.x += v.x;
			temp.y += v.y;
			temp.z += v.z;
		}
		else static if( op == "-" )
		{
			Vector3 temp = this;
			temp.x -= v.x;
			temp.y -= v.y;
			temp.z -= v.z;
		}
		else static if( op == "*" )
		{
			Vector3 temp = this;
			temp.x *= v.x;
			temp.y *= v.y;
			temp.z *= v.z;
		}
		
		return temp;
	}
	
	Vector3 opBinary(string op) (ref Vector3 v) const @safe pure nothrow
	{
		static if( op == "+" )
		{
			Vector3 temp = this;
			temp.x += v.x;
			temp.y += v.y;
			temp.z += v.z;
		}
		else static if( op == "-" )
		{
			Vector3 temp = this;
			temp.x -= v.x;
			temp.y -= v.y;
			temp.z -= v.z;
		}
		else static if( op == "*" )
		{
			Vector3 temp = this;
			temp.x *= v.x;
			temp.y *= v.y;
			temp.z *= v.z;
		}
		
		return temp;
	}
	
	ref Vector3 opOpAssign(string op) (T val) @safe pure nothrow
	{
		static if( op == "+" )
		{
			x += val;
			y += val;
			z += val;
		}
		else static if( op == "-" )
		{
			x -= val;
			y -= val;
			z -= val;
		}
		else static if( op == "*" )
		{
			x *= val;
			y *= val;
			z *= val;
		}
		else static if( op == "/" )
		{
			x /= val;
			y /= val;
			z /= val;
		}
		else
			static assert(false, "unsupported operator " ~ op);
		
		return this;
	}
	
	ref Vector3 opOpAssign(string op) (Vector3 v) @safe pure nothrow
	{
		static if( op == "+" )
		{
			x += v.x;
			y += v.y;
			z += v.z;
		}
		else static if( op == "-" )
		{
			x -= v.x;
			y -= v.y;
			z -= v.z;
		}
		else static if( op == "*" )
		{
			x *= v.x;
			y *= v.y;
			z *= v.z;
		}
		else static if( op == "/" )
		{
			x /= v.x;
			y /= v.y;
			z /= v.z;
		}
		else
			static assert(false, "unsupported operator " ~ op);
		
		return this;
	}
}

/// dot product of two Vector3 vectors
auto dot(T) (Vector3!T u, Vector3!T v) @safe pure nothrow
{
	return u.x * v.x + u.y * v.y + u.z * v.z;
}

/// dot product of two Vector3 vectors
auto dot(T) (ref Vector3!T u, ref Vector3!T v) @safe pure nothrow
{
	return u.x * v.x + u.y * v.y + u.z * v.z;
}

/// cross product
Vector3!T cross(T) (Vector3!T a, Vector3!T b) @safe pure nothrow
{
	Vector3!T w = void;
	
	w.x = a.y * b.z - a.z * b.y;
	w.y = a.z * b.x - a.x * b.z;
	w.z = a.x * b.y - a.y * b.x;
	
	return w;
}

/// cross product
Vector3!T cross(T) (ref Vector3!T a, ref Vector3!T b) @safe pure nothrow
{
	Vector3!T w = void;
	
	w.x = a.y * b.z - a.z * b.y;
	w.y = a.z * b.x - a.x * b.z;
	w.z = a.x * b.y - a.y * b.x;
	
	return w;
}

/// returns the length of this vector
auto length(T) (Vector3!T v) @safe pure nothrow
{
	return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

/// returns the length of this vector
auto length(T) (ref Vector3!T v) @safe pure nothrow
{
	return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

/// normalizes the vector
void normalize(T) (ref Vector3!T v) @safe pure nothrow
{
	T lenR = cast(T)1.0 / length(v); // length reversed
	
	v.x *= lenR;
	v.y *= lenR;
	v.z *= lenR;
}