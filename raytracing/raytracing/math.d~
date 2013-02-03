module raytracing.math;

import raytracing.vector;

float triangleArea(const ref Vector2 a, const ref Vector2 b, const ref Vector2 c)
{
	return std.math.abs(0.5f * (a.x * b.y + b.x * c.y + c.x * a.y - a.x * c.y - b.x * a.y - c.x * b.y));
}