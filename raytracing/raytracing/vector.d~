module raytracing.vector;

import std.math;

struct Vector2
{
	float x, y;
	
	this(float _x, float _y)
	{
		x = _y;
		y = _y;
	}
	
	// negate operator
	Vector2 opUnary(string s)() if( s == "-" )
	{
		Vector2 temp = this;
		
		temp.x = -temp.x;
		temp.y = -temp.y;
		
		return temp;
	}
	
	// + operator for completeness
	Vector2 opUnary(string s)() if( s == "+" )
	{
		return this;
	}
	
	// binary operators
	Vector2 opBinary(string op) (float val)
	{
		static if( op == "+" )
		{
			Vector2 temp = this;
			temp.x += val;
			temp.y += val;
		}
		else static if( op == "-" )
		{
			Vector2 temp = this;
			temp.x -= val;
			temp.y -= val;
		}
		else static if( op == "*" )
		{
			Vector2 temp = this;
			temp.x *= val;
			temp.y *= val;
		}
		else static if( op == "/" )
		{
			Vector2 temp = this;
			temp.x /= val;
			temp.y /= val;
		}
		
		return temp;
	}
	
	Vector2 opBinary(string op) (const ref Vector2 v) const
	{
		static if( op == "+" )
		{
			Vector2 temp = this;
			temp.x += v.x;
			temp.y += v.y;
		}
		static if( op == "-" )
		{
			Vector2 temp = this;
			temp.x -= v.x;
			temp.y -= v.y;
		}
		
		return temp;
	}
}

struct Vector3
{
	float x, y, z;
	
	this(float _x, float _y, float _z)
	{
		x = _x;
		y = _y;
		z = _z;
	}
	
	// negate operator
	Vector3 opUnary(string s)() const if( s == "-" )
	{
		Vector3 temp = this;
		
		temp.x = -temp.x;
		temp.y = -temp.y;
		temp.z = -temp.z;
		
		return temp;
	}
	
	// + operator for completeness
	Vector3 opUnary(string s)() const if( s == "+" )
	{
		return this;
	}
	
	// binary operators
	Vector3 opBinary(string op) (float val) const
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
	
	Vector3 opBinary(string op) (Vector3 v) const
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
}
	
struct Vector4
{
	float x, y, z, w;
	
	this(float _x, float _y, float _z, float _w)
	{
		x = _x;
		y = _y;
		z = _z;
		w = _w;
	}
	
	// negate operator
	Vector4 opUnary(string s)() if( s == "-" )
	{
		Vector4 temp = this;
		
		temp.x = -temp.x;
		temp.y = -temp.y;
		temp.z = -temp.z;
		temp.w = -temp.w;
		
		return temp;
	}
	
	// + operator for completeness
	Vector4 opUnary(string s)() if( s == "+" )
	{
		return this;
	}
	
	// binary operators
	Vector4 opBinary(string op) (float val)
	{
		static if( op == "+" )
		{
			Vector4 temp = this;
			temp.x += val;
			temp.y += val;
			temp.z += val;
			temp.w += val;
		}
		else static if( op == "-" )
		{
			Vector4 temp = this;
			temp.x -= val;
			temp.y -= val;
			temp.z -= val;
			temp.w -= val;
		}
		else static if( op == "*" )
		{
			Vector4 temp = this;
			temp.x *= val;
			temp.y *= val;
			temp.z *= val;
			temp.w *= val;
		}
		else static if( op == "/" )
		{
			Vector4 temp = this;
			temp.x /= val;
			temp.y /= val;
			temp.z /= val;
			temp.w /= val;
		}
		
		return temp;
	}
	
	Vector4 opBinary(string op) (const ref Vector4 v) const
	{
		static if( op == "+" )
		{
			Vector4 temp = this;
			temp.x += v.x;
			temp.y += v.y;
			temp.z += v.z;
			temp.w += v.w;
		}
		static if( op == "-" )
		{
			Vector4 temp = this;
			temp.x -= v.x;
			temp.y -= v.y;
			temp.z -= v.z;
			temp.w -= v.w;
		}
		
		return temp;
	}
}

/// dot product of two Vector2 vectors
@safe pure float dot(const ref Vector2 u, const ref Vector2 v)
{
	return u.x * v.x + u.y * v.y;
}

/// dot product of two Vector3 vectors
@safe pure float dot(const ref Vector3 u, const ref Vector3 v)
{
	return u.x * v.x + u.y * v.y + u.z * v.z;
}

/// dot product of two Vector4 vectors
@safe pure float dot(const ref Vector4 u, const ref Vector4 v)
{
	return u.x * v.x + u.y * v.y + u.z * v.z + u.w * v.w;
}

/// cross product
@safe pure Vector3 cross(const ref Vector3 a, const ref Vector3 b)
{
	Vector3 w = void;
	
	w.x = a.y * b.z - a.z * b.y;
	w.y = a.z * b.x - a.x * b.z;
	w.z = a.x * b.y - a.y * b.x;
	
	return w;
}

/// returns the length of this vector
@safe pure float length(const ref Vector2 v)
{
	return sqrt(v.x * v.x + v.y * v.y);
}

/// returns the length of this vector
@safe pure float length(const ref Vector3 v)
{
	return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

/// returns the length of this vector
@safe pure float length(const ref Vector4 v)
{
	return sqrt(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w);
}

/// normalizes the vector
@safe pure void normalize(ref Vector2 v)
{
	float lenR = 1.0f / length(v); // length reversed
	
	v.x *= lenR;
	v.y *= lenR;
}

/// normalizes the vector
@safe pure void normalize(ref Vector3 v)
{
	float lenR = 1.0f / length(v); // length reversed
	
	v.x *= lenR;
	v.y *= lenR;
	v.z *= lenR;
}

/// normalizes the vector
@safe pure void normalize(ref Vector4 v)
{
	float lenR = 1.0f / length(v); // length reversed
	
	v.x *= lenR;
	v.y *= lenR;
	v.z *= lenR;
	v.w *= lenR;
}