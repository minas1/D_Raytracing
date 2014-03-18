module raytracing.raytracer;

import raytracing.vector;
import raytracing.ray;
import raytracing.sphere;
import raytracing.triangle;
import raytracing.scene;
import raytracing.surface;
import raytracing.material;
import raytracing.light;
import raytracing.meshloader;
import raytracing.box;
import raytracing.bvh;
import raytracing.math;
import derelict.sdl.sdl;

import std.parallelism;
import std.range;
import std.math;
import std.random;

class Raytracer
{
	/** Performs raytracing. This is a blocking call
	 * Params:
	 * 	scene = Our scene
	 * 	cameraPos = 3D position of the camera in the 3D world
	 * 	screen = The SDL_Surface we are writing in
	 * 	aaSamples = Number of anti-aliasing samples. Use 1 for no anti-aliasing
	 */
	void run(ref Scene scene, const ref Vector3!double cameraPos, SDL_Surface* screen, int aaSamples)
	{
		const SCREEN_WIDTH = screen.w;
		const SCREEN_HEIGHT = screen.h;
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
				
				writePixel(screen, x, SCREEN_HEIGHT - 1 - y, cast(ubyte)(pixelColor.x * 255), cast(ubyte)(pixelColor.y * 255), cast(ubyte)(pixelColor.z * 255));	
			}
		}
	}

	/// writes pixel [r, g, b] at position [x,y] of the given SDL_Surface
	private void writePixel(SDL_Surface *s, int x, int y, ubyte r, ubyte g, ubyte b)
	{
		if( SDL_MUSTLOCK(s) ) SDL_LockSurface(s);
		
		Uint32 color = SDL_MapRGB(s.format, r, g, b);
		ubyte* pData = cast(ubyte*)s.pixels + y * s.pitch + x * s.format.BytesPerPixel;
		
		std.c.string.memcpy(pData, &color, s.format.BytesPerPixel);
		
		if( SDL_MUSTLOCK(s) ) SDL_UnlockSurface(s);
	}
}

