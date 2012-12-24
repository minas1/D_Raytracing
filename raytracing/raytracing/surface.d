module raytracing.surface;

import raytracing.ray;
import raytracing.box;
import raytracing.vector;
import raytracing.scene;

abstract interface Surface
{
	bool hit(const ref Ray r, float t0, float t1, ref HitInfo hitInfo);
	
	/// returns the bounding box of this surface
	Box boundingBox() const;
	
	Vector3 shade(HitInfo hitInfo, ref Scene scene) const;
}

struct HitInfo
{
	float t;
	Vector3 hitPoint; // the point where the hit happened
	Vector3 surfaceNormal;
	Vector3 ray; // the ray the came from the camera
	
	Surface hitSurface; // the surface the ray hit
}