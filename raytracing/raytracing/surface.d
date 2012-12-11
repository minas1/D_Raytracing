module raytracing.surface;

import raytracing.ray;
import raytracing.box;

abstract class Surface
{
	bool hit(const ref Ray r, float t0, float t1, ref HitInfo hitInfo) const;
	
	/// returns the bounding box of this surface
	Box boundingBox() const;
	
	// Add a "material" member?
}

struct HitInfo
{
}