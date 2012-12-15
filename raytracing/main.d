/*
 * So you end up with a nested for loop like:
for (var x = 0; x < 1024; ++x)
{
	for (var z = 0; z < 768; ++z)
	{
		near plane point in camera space:
		((x - 1024 / 2) / (1024 / 2), 0, (z - 768 / 2) / (768 / 2)) 
			
		then subtract that by your focus point like (0, -1, 0) and normalize and then rotate it by camera matrix.
 * You can also translate it depending on what you want the near plane rotate around } }
 */

import std.stdio;
import std.datetime;

import raytracing.vector;
import raytracing.ray;
import raytracing.sphere;
import raytracing.scene;
import raytracing.surface;
import raytracing.material;
import raytracing.light;

import std.c.stdlib;

immutable SCREEN_WIDTH = 800;
immutable SCREEN_HEIGHT = 600;
immutable ASPECT_RATIO = SCREEN_WIDTH / cast(float)SCREEN_HEIGHT;

import derelict.sdl.sdl;

void main()
{
	DerelictSDL.disableAutoUnload(); // disable auto-unload because it causes seg. faults!
	DerelictSDL.load();
	
	if( SDL_Init(SDL_INIT_EVERYTHING) == -1 )
	{
		writeln("Error! Could not initialize SDL.");
	}
	atexit(SDL_Quit);
	
	SDL_WM_SetCaption("Raytracing in D", null);
	
	SDL_Surface* screen = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, 32, SDL_HWSURFACE);
	SDL_Event event;
	
	srand(cast(uint)Clock.currTime.toUnixTime);
	
	// create the pixels array
	auto pixels = new Vector3[SCREEN_WIDTH][SCREEN_HEIGHT];
	Vector3 cameraPos = {0, 0, -1};
	Vector3 cameraDirection = {0, 0, 1};
	Vector3 upVector = {0, 1, 0};
	
	// create the scene
	Scene scene;
	
	// create a sphere
	Vector3 center = {-2, 0, 5};
	Sphere s = new Sphere(center, 1);
	s.material = new SimpleColor(154, 205, 50);
	
	// and another one
	center.x = 4;
	center.y = -1;
	center.z = 10;
	Sphere s3 = new Sphere(center, 1.0f);
	s3.material = new SimpleColor(65, 145, 201);
	
	// and another one
	center.x = 0;
	center.y = 10;
	center.z = 50;
	Sphere s2 = new Sphere(center, 20);
	s2.material = new SimpleColor(205, 155, 155);
	
	scene.objects.insert(s); // add the sphere into the scene
	scene.objects.insert(s2);
	scene.objects.insert(s3);
	
	// add lights
	Light l = new Light();
	l.position = Vector3(-5, 0, 0);
	l.I = Vector3(173/255.0f, 234/255.0f, 234/255.0f); // 230;232;250
	scene.lights.insert(l);
	
	l = new Light();
	l.position = Vector3(3, 4, 0); // TODO: gives wrong colors
	l.I = Vector3(207/255.0f, 181/255.0f, 57/255.0f);
	scene.lights.insert(l);
	
	StopWatch watch;
	watch.start();
	
	for(int x = 0; x < SCREEN_WIDTH; ++x)
	{
		for(int y = 0; y < SCREEN_HEIGHT; ++y)
		{
			//x = SCREEN_WIDTH / 2; y = SCREEN_HEIGHT / 2;
			
			Vector3 p = {ASPECT_RATIO * (x - SCREEN_WIDTH * 0.5f) / (SCREEN_WIDTH * 0.5f), (y - SCREEN_HEIGHT * 0.5f) / (SCREEN_HEIGHT * 0.5f), 0};
			Ray r = {cameraPos, p - cameraPos};
			
			HitInfo hitInfo;
			bool hit = scene.trace(r, hitInfo, 0.1f);
			
			if( hit )
			{
				Vector3 color = hitInfo.hitSurface.shade(hitInfo, scene);
				if( color.x > 1.0f ) color.x = 1.0f;
				if( color.y > 1.0f ) color.y = 1.0f;
				if( color.z > 1.0f ) color.z = 1.0f;
				
				writePixel(screen, x, SCREEN_HEIGHT - 1 - y, cast(ubyte)(color.x * 255), cast(ubyte)(color.y * 255), cast(ubyte)(color.z * 255));	
			}
			
			//x = y = 1000;
		}
	}
	
	watch.stop();
	writeln(watch.peek().nsecs / 1_000_000.0, " ms");
	
	SDL_Flip(screen); // update the screen

	bool quit = false;
	while( !quit )
	{
		SDL_WaitEvent(&event); // wait for something to happen
		
		if( event.type == SDL_QUIT )
			quit = true;
		if( event.key.keysym.sym == SDLK_ESCAPE )
			quit = true;
	}
}

/// writes pixel [r, g, b] at position [x,y] of the given SDL_Surface
void writePixel(SDL_Surface *s, int x, int y, ubyte r, ubyte g, ubyte b)
{
	if( SDL_MUSTLOCK(s) ) SDL_LockSurface(s);
	
	Uint32 color = SDL_MapRGB(s.format, r, g, b);
	ubyte* pData = cast(ubyte*)s.pixels + y * s.pitch + x * s.format.BytesPerPixel;
	
	std.c.string.memcpy(pData, &color, s.format.BytesPerPixel);
	
	if( SDL_MUSTLOCK(s) ) SDL_UnlockSurface(s);
}

class SimpleColor : Material
{
	private Vector3 color;
	
	this(ubyte r, ubyte g, ubyte b)
	{
		color.x = r / 255.0f;
		color.y = g / 255.0f;
		color.z = b / 255.0f;
	}
	
	Vector3 shade(HitInfo hitInfo, ref Scene scene) const
	{
		Vector3 finalColor = {0.0f, 0.0f, 0.0f}; // the final color
		
		hitInfo.surfaceNormal.normalize();
		
		foreach(light; scene.lights)
		{
			Vector3 lightVector = light.position - hitInfo.hitPoint; // vector from the hit point to the light
		
			lightVector.normalize();
			
			HitInfo hitInfo2;
			Ray ray = {hitInfo.hitPoint, light.position - hitInfo.hitPoint};
			ray.d.normalize();
			if( !scene.trace(ray, hitInfo2, 0.1f) )
			{
				// diffuse shading
				if( hitInfo.surfaceNormal.dot(lightVector) > 0 )
				{
					finalColor = finalColor + light.I * color * hitInfo.surfaceNormal.dot(lightVector);
							
					hitInfo.ray = -hitInfo.ray;
					hitInfo.ray.normalize();
					
					// specular shading
					Vector3 H = (lightVector + hitInfo.ray) * 0.5f; // find the half vector, H
					
					H.normalize();
					
					float specularDotProduct = dot(hitInfo.surfaceNormal, H);
					
					if( specularDotProduct > 0.0f )
						finalColor = finalColor + light.I * std.math.pow(specularDotProduct, 75.0f);
				}
			}
			else
			{
				// no color is added, shadow is shown
			}
		}
		
		return finalColor;
	}
}