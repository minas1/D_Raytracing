module raytracing.ray;

import raytracing.vector;

struct Ray
{
	Vector3 e; // the starting point
	Vector3 d; // the ending point
}

/// returns the direction of this ray
Vector3 direction(const ref Ray r)
{
	return r.d - r.e;
}