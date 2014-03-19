module raytracing.material;

import raytracing.vector;
import raytracing.surfaces.surface;
import raytracing.scene;

abstract interface Material
{
	/// returns the color
	Vector3!float shade(const ref HitInfo hitInfo, ref Scene scene) const;
}