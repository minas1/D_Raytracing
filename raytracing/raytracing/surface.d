module raytracing.surface;

import raytracing.ray;
import raytracing.box;
import raytracing.vector;
import raytracing.scene;

abstract class Surface
{
	abstract bool hit(const ref Ray r, float t0, float t1, ref HitInfo hitInfo);
	
	/// returns the bounding box of this surface
	abstract Box boundingBox() const;
	
	abstract Vector3 shade(const ref HitInfo hitInfo, ref Scene scene) const;
}

struct HitInfo
{
	float t;
	Vector3 hitPoint; // the point where the hit happened
	Vector3 surfaceNormal;
	Vector3 ray; // the ray the came from the camera
	
	Surface hitSurface; // the surface the ray hit
}