module raytracing.light;

import raytracing.vector;

struct Light
{
	Vector3!double position;	// position of the light
	Vector3!float I;			// color of the light
}