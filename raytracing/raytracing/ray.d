module raytracing.ray;

import raytracing.vector;

struct Ray
{
	Vector3!double e; // the starting point
	Vector3!double d; // the direction
}