module raytracing.light;

import raytracing.vector;

struct Light
{
	Vector3 position;	// position of the light
	Vector3 I;			// color of the light
}