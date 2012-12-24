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
import raytracing.triangle;
import raytracing.scene;
import raytracing.surface;
import raytracing.material;
import raytracing.light;
import raytracing.math;

import std.c.stdlib;
import std.math;
import std.parallelism;
import std.random;

immutable SCREEN_WIDTH = 800;
immutable SCREEN_HEIGHT = 600;
immutable ASPECT_RATIO = SCREEN_WIDTH / cast(float)SCREEN_HEIGHT;

import derelict.sdl.sdl;

void main()
{
	init(); // initialize SDL, set window caption etc.
	
	SDL_Surface* screen = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, 32, SDL_HWSURFACE);
	SDL_Event event;
	
	srand(cast(uint)Clock.currTime.toUnixTime);
	
	// create the pixels array
	auto pixels = new Vector3[SCREEN_HEIGHT][SCREEN_WIDTH];
	Vector3 cameraPos = Vector3(0, 0, -1);
	Vector3 cameraDirection = Vector3(0, 0, 1);
	Vector3 upVector = Vector3(0, 1, 0);
	
	// create the scene
	Scene scene;
	makeScene2(scene);
	
	writeln("Rendering...");
	StopWatch watch;
	watch.start();
	
	for(int y = 0; y < SCREEN_HEIGHT; ++y)
	{
		for(int x = 0; x < SCREEN_WIDTH; ++x)
		{
			//x = cast(int)(SCREEN_WIDTH * 0.75f);
			//y = cast(int)(SCREEN_HEIGHT * 0.75f) + 1;
			
			Vector3 p = Vector3(ASPECT_RATIO * (x - SCREEN_WIDTH * 0.5f) / (SCREEN_WIDTH * 0.5f), (y - SCREEN_HEIGHT * 0.5f) / (SCREEN_HEIGHT * 0.5f), 0);
			Ray r = {cameraPos, p - cameraPos};
			
			HitInfo hitInfo;
			
			bool hit = scene.trace(r, hitInfo, 0.1f);
			
			if( hit )
			{
				Vector3 color = hitInfo.hitSurface.shade(hitInfo, scene);
				if( color.x > 1.0f ) color.x = 1.0f;
				if( color.y > 1.0f ) color.y = 1.0f;
				if( color.z > 1.0f ) color.z = 1.0f;
				
				//pixels[x][y] = color;
				writePixel(screen, x, SCREEN_HEIGHT - 1 - y, cast(ubyte)(color.x * 255), cast(ubyte)(color.y * 255), cast(ubyte)(color.z * 255));	
			}
			
			//x = y = 1000;
		}
		
		//SDL_Flip(screen);
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


void init()
{
	DerelictSDL.disableAutoUnload(); // disable auto-unload because it causes seg. faults!
	DerelictSDL.load();
	
	if( SDL_Init(SDL_INIT_EVERYTHING) == -1 )
	{
		writeln("Error! Could not initialize SDL.");
	}
	atexit(SDL_Quit);
	
	SDL_WM_SetCaption("Raytracing in D", null);
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
		Vector3 finalColor = Vector3(0.0f, 0.0f, 0.0f); // the final color
		
		// normalize the surface normal
		hitInfo.surfaceNormal.normalize();
		
		hitInfo.ray = -hitInfo.ray;
		hitInfo.ray.normalize();
		
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

					// specular shading
					Vector3 H = (lightVector + hitInfo.ray) * 0.5f; // find the half vector, H
					H.normalize();
					
					float specularDotProduct = dot(hitInfo.surfaceNormal, H);
					
					if( specularDotProduct > 0.0f )
						finalColor = finalColor + light.I * std.math.pow(specularDotProduct, 100.0f);
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

// a surface with a diffuse component that acts as a mirror as well
class Mirror : Material
{
	Vector3 color;
	float mirrorPercentage; // percentage of the final color that comes from reflected light
	
	this(ubyte r, ubyte g, ubyte b, float _mirrorPercentage)
	{
		color.x = r / 255.0f;
		color.y = g / 255.0f;
		color.z = b / 255.0f;
		
		mirrorPercentage = _mirrorPercentage;
	}
	
	Vector3 shade(HitInfo hitInfo, ref Scene scene) const
	{
		Vector3 finalColor = Vector3(0.0f, 0.0f, 0.0f); // the final color
		Vector3 normalColor = Vector3(0, 0, 0), reflectedColor = Vector3(0, 0, 0);
		
		hitInfo.surfaceNormal.normalize();
		hitInfo.ray.normalize();
		
		foreach(light; scene.lights)
		{
			Vector3 lightVector = light.position - hitInfo.hitPoint; // vector from the hit point to the light
			lightVector.normalize();
			
			HitInfo hitInfo2;
			Ray ray = {hitInfo.hitPoint, hitInfo.ray - hitInfo.surfaceNormal * 2 * dot(hitInfo.ray, hitInfo.surfaceNormal)};
			ray.d.normalize();
			
			// reflected color
			if( scene.trace(ray, hitInfo2, 0.1f) )
			{
				reflectedColor = reflectedColor + hitInfo2.hitSurface.shade(hitInfo2, scene);
			}
			
			// "normal" color (diffuse shading)
			if( hitInfo.surfaceNormal.dot(lightVector) > 0 )
				normalColor = normalColor + light.I * color * hitInfo.surfaceNormal.dot(lightVector);
		}
		
		//return finalColor;
		return reflectedColor * mirrorPercentage + normalColor * (1 - mirrorPercentage);
	}
}

void makeScene1(ref Scene scene)
{
	Triangle triangle = new Triangle(
	-1, 0, 8,
	0, 1, 8,
	1, 0, 8
	);
	triangle.material = new SimpleColor(255, 255, 255);
	scene.objects.insert(triangle);
	
	// create a sphere
	Vector3 center = Vector3(-2, 0, 3);
	Sphere s = new Sphere(center, 1);
	s.material = new Mirror(154, 205, 50, 0.5f);
	
	// and another one
	center.x = 4.5f;
	center.y = 2.5f;
	center.z = 10;
	Sphere s3 = new Sphere(center, 1.0f);
	s3.material = new SimpleColor(65, 145, 201);
	
	// and another one
	center.x = 0;
	center.y = 10;
	center.z = 50;
	Sphere s2 = new Sphere(center, 20);
	s2.material = new SimpleColor(205, 155, 155);
	
	immutable SPHERES_AROUND = 50;
	/*for(int i = 0; i < SPHERES_AROUND; ++i)
	{
		center.x = s3.center.x + s3.radius * 2.0f * sin(i * 360.0f/SPHERES_AROUND * PI / 180.0f);
		center.y = s3.center.y + sin((45.0f + i * 360.0f/SPHERES_AROUND) * PI / 180.0f);
		center.z = s3.center.z + s3.radius * 2.0f * cos(i * 360.0f/SPHERES_AROUND* PI / 180.0f);
		
		Sphere s5 = new Sphere(center, 0.05f);
		s5.material = new SimpleColor(cast(ubyte)uniform(0, 255), cast(ubyte)uniform(0, 255), cast(ubyte)uniform(0, 255));
		scene.objects.insert(s5);
		
		
		center.x = s.center.x + s.radius * 1.5f * sin(i * 360.0f/SPHERES_AROUND * PI / 180.0f);
		center.y = s.center.y + cos((30.0f + i * 360.0f/SPHERES_AROUND) * PI / 180.0f);
		center.z = s.center.z + s.radius * 1.5f * cos(i * 360.0f/SPHERES_AROUND* PI / 180.0f);
	
		Sphere s6 = new Sphere(center, 0.05f);
		s6.material = new SimpleColor(cast(ubyte)uniform(0, 255), cast(ubyte)uniform(0, 255), cast(ubyte)uniform(0, 255));
		scene.objects.insert(s6);
	}*/
	
	// mirror
	center.x = 0;
	center.y = -100;
	center.z = 50;
	Sphere s4 = new Sphere(center, 80);
	s4.material = new Mirror(255, 255, 255, 0.8f);
	
	scene.objects.insert(s); // add the sphere into the scene
	scene.objects.insert(s2);
	scene.objects.insert(s3);
	scene.objects.insert(s4);
	
	// add lights
	Light l = new Light();
	l.position = Vector3(-5, 0, 0);
	l.I = Vector3(173/255.0f, 234/255.0f, 234/255.0f);
	scene.lights.insert(l);
	
	l = new Light();
	l.position = Vector3(7, 0, 0);
	l.I = Vector3(153/255.0f, 204/255.0f, 50/255.0f);
	scene.lights.insert(l);
	
}

void makeScene2(ref Scene scene)
{
	Triangle triangle = new Triangle(
	-1, -2, 5,
	0, 4, 5,
	7, 4, 5
	);
	triangle.material = new SimpleColor(255, 255, 255);
	scene.objects.insert(triangle);
	
	Sphere sphere = new Sphere();
	sphere.center.x = 0;
	sphere.center.y = 0;
	sphere.center.z = 4;
	sphere.radius = 1;
	sphere.material = new SimpleColor(255, 0, 0);
	scene.objects.insert(sphere);
	
	// right light
	Light l = new Light();
	l.position = Vector3(7, 0, 0);
	l.I = Vector3(153/255.0f, 204/255.0f, 50/255.0f);
	scene.lights.insert(l);
	
	// left light
	l = new Light();
	l.position = Vector3(-5, 0, 0);
	l.I = Vector3(173/255.0f, 234/255.0f, 234/255.0f);
	scene.lights.insert(l);
	
	
}