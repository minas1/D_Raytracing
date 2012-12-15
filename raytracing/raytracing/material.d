module raytracing.material;

import raytracing.vector;
import raytracing.surface;
import raytracing.scene;

abstract interface Material
{
	/// returns the color
	Vector3 shade(HitInfo hitInfo, ref Scene scene) const;
}