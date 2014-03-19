module raytracing.raytracer;

import raytracing.vector;
import raytracing.ray;
import raytracing.surfaces.sphere;
import raytracing.surfaces.triangle;
import raytracing.scene;
import raytracing.surfaces.surface;
import raytracing.material;
import raytracing.light;
import raytracing.box;
import raytracing.bvh;
import raytracing.math;

import std.parallelism;
import std.range;
import std.math;
import std.random;

class Raytracer
{
	public Vector3!(float)[][] pixels;
	private int width, height;

	this(int _width, int _height)
	{
		width = _width;
		height = _height;

		pixels = new Vector3!(float)[][](height, width);
	}

	/** Performs raytracing. This is a blocking call
	 * Params:
	 * 	scene = Our scene
	 * 	cameraPos = 3D position of the camera in the 3D world
	 * 	screen = The SDL_Surface we are writing in
	 * 	aaSamples = Number of anti-aliasing samples. Use 1 for no anti-aliasing
	 */
	void run(ref Scene scene, const ref Vector3!double cameraPos, int aaSamples)
	{
		const SCREEN_WIDTH = width;
		const SCREEN_HEIGHT = height;
		const ASPECT_RATIO = SCREEN_WIDTH / cast(float)SCREEN_HEIGHT;

		// calculate square root of antialiasing samples
		auto N = cast(int)sqrt(aaSamples + 0.0f);
		
		foreach(y; parallel(iota(0, SCREEN_HEIGHT)))
		{
			foreach(x; 0..SCREEN_WIDTH)
			{
				auto pixelColor = Vector3!float(0, 0, 0);
				
				foreach(k1; 0..N) // these two loops are for anti-aliasing
				{
					foreach(k2; 0..N)
					{
						auto random = uniform(0.0, 1.0);
						auto p = Vector3!double(ASPECT_RATIO * (x + (k1 + random) / N - SCREEN_WIDTH * 0.5) / (SCREEN_WIDTH * 0.5), (y + (k2 + random) / N - SCREEN_HEIGHT * 0.5) / (SCREEN_HEIGHT * 0.5), 0);
						
						Ray r = {cameraPos, p - cameraPos};
						
						HitInfo hitInfo = void;
						bool hit = scene.trace(r, hitInfo);
						
						if( hit )
						{	
							auto color = hitInfo.hitSurface.shade(hitInfo, scene);
							
							if( color.x > 1.0f ) color.x = 1.0f;
							if( color.y > 1.0f ) color.y = 1.0f;
							if( color.z > 1.0f ) color.z = 1.0f;
							
							pixelColor += color;
						}
						else // add background color if no hit
						{
							pixelColor += scene.defaultColor;
						}
					}
				}
				pixelColor /= N * N;


				pixels[y][x] = pixelColor;
			}
		}
	}
}

