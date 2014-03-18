module raytracing.materials.SimpleColor;

import raytracing.vector;
import raytracing.material;
import raytracing.surface;
import raytracing.scene;
import raytracing.light;
import raytracing.ray;

import std.random;

class SimpleColor : Material
{
	Vector3!float ka;	// ambient component
	Vector3!float kd;	// diffuse component
	Vector3!float ks;	// specular component
	float specularComponent; // component that specifies the size of the specular highlight 
	
	this(Vector3!float _ka, Vector3!float _kd, Vector3!float _ks, float _specularComponent)
	{
		ka = _ka;
		kd = _kd;
		ks = _ks;
		
		specularComponent = _specularComponent;
	}
	
	Vector3!float shade(const ref HitInfo _hitInfo, ref Scene scene) const
	{
		import std.math;
		
		Vector3!float finalColor = ka; // the final color
		
		Vector3!double n = _hitInfo.surfaceNormal;
		normalize(n);
		
		Vector3!double hitRay = -_hitInfo.ray;
		normalize(hitRay);
		
		for(int i = 0; i < scene.lights.length; ++i)
		{
			Light light = scene.lights[i];
			
			Vector3!double lightVector = scene.lights[i].position - _hitInfo.hitPoint; // vector from the hit point to the light
			
			normalize(lightVector);
			
			HitInfo hitInfo2 = void;
			
			// calculate shadow ray by taking shadow samples
			// take shadow ray samples
			const int SHADOW_SAMPLES = cast(int)(light.u.length() * light.v.length() * light.w.length());
			
			auto tempColor = Vector3!float(0, 0, 0);
			
			const nDotLightVec = dot(n, lightVector);
			
			if( nDotLightVec > 0 )
			{
				// precalculate some things
				Vector3!double H = (lightVector + hitRay) * 0.5; // find the half vector, H
				H.normalize();
				
				double specularDotProduct = dot(n, H);
				
				auto addedDiffuseColor = light.I * kd * nDotLightVec;
				auto addedSpecularColor = light.I * ks * pow(specularDotProduct, specularComponent);
				
				foreach(j; 0..SHADOW_SAMPLES)
				{
					auto randomPoint = light.position + light.u * uniform(-1.0, 1.0) + light.v * uniform(-1.0, 1.0) + light.w * uniform(-1.0, 1.0);
					
					Ray ray = {_hitInfo.hitPoint, randomPoint - _hitInfo.hitPoint};
					normalize(ray.d);
					
					if( !scene.trace(ray, hitInfo2, 0.01) )
					{
						// no need to check if n dot l is > 0, because we already know it is
						tempColor += addedDiffuseColor;
						
						if( specularDotProduct > 0.0 )
							tempColor += addedSpecularColor;
					}
				}
			}
			
			finalColor += tempColor / SHADOW_SAMPLES;
		}
		
		return finalColor;
	}
}