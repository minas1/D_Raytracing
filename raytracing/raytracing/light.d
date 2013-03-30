module raytracing.light;

import raytracing.vector;

struct Light
{
	Vector3!double position;	// position of the light
	Vector3!float I;			// color of the light
	
	Vector3!double u, v, w; 	// vectors that define a sphere of the light.
								// u: x axis, v: y axis, w: z axis
}