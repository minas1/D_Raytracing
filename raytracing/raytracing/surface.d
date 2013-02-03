module raytracing.surface;

import raytracing.ray;
import raytracing.box;
import raytracing.vector;
import raytracing.scene;

abstract class Surface
{
	string name = "";
	
	abstract bool hit(const ref Ray r, double t0, double t1, ref HitInfo hitInfo);
	
	/// returns the bounding box of this surface
	abstract Box boundingBox() const;
	
	abstract Vector3!float shade(const ref HitInfo hitInfo, ref Scene scene) const;
}

struct HitInfo
{
	double t;
	Vector3!double hitPoint; // the point where the hit happened
	Vector3!double surfaceNormal;
	Vector3!double ray; // the ray the came from the camera
	
	Surface hitSurface; // the surface the ray hit
}
