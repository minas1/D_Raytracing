/*
 * TODO:
 * 
 * 1) !!! Make triangle.hit() faster
 * 2) Make BVH.hit() non-recursive.
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
import raytracing.meshloader;
import raytracing.box;
import raytracing.bvh;

import std.c.stdlib;
import std.math;
import std.parallelism;
import std.random;
import core.sync.semaphore;
import std.algorithm;
import std.range;

import derelict.sdl.sdl;

immutable SCREEN_WIDTH = 800;
immutable SCREEN_HEIGHT = 600;
immutable ASPECT_RATIO = SCREEN_WIDTH / cast(float)SCREEN_HEIGHT;

void printBVH(Surface root, int i = 0, string str = "")
{
	if( root is null )
		return;
	
	writeln("------PRINT()------");
	writeln("Name = ", root.name);
	writeln(root.boundingBox());
	writeln("------~~~~~~~------\n");
	
	if( (cast(BVHNode)root) !is null )
	{
		printBVH((cast(BVHNode)(root)).left, i+1, "left");
		printBVH((cast(BVHNode)(root)).right, i+1, "right");
	}
}


void main()
{
	init(); // initialize SDL, set window caption etc.
	
	SDL_Surface* screen = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, 32, SDL_HWSURFACE);
	SDL_Event event;
	
	srand(cast(uint)Clock.currTime.toUnixTime);
	
	// create the pixels array
	//auto pixels = new Vector3[SCREEN_HEIGHT][SCREEN_WIDTH];
	auto cameraPos = Vector3!double(0, 0, -1);
	auto cameraDirection = Vector3!double(0, 0, 1);
	auto upVector = Vector3!double(0, 1, 0);
	
	// create the scene
	Scene scene = Scene(20, 3);
	makeScene2(scene);
	
	scene.preCalc();
	
	writeln("The scene has ", scene.objects.length, " triangles.");
	writeln("Rendering...");
	
	//printBVH(scene.root);
	
	Semaphore sema = new Semaphore(1);
	
	StopWatch watch;
	watch.start();
	foreach(y; parallel(iota(0, SCREEN_HEIGHT)))
	{
		foreach(x; iota(0,SCREEN_WIDTH))
		{
			immutable N = 3; // antialiasing samples
			auto c = Vector3!float(0, 0, 0);
			
			foreach(k1; 0..N) // these two loops are for anti-aliasing
			{
				foreach(k2; 0..N)
				{
					auto random = uniform(0.0, 1.0);
					auto p = Vector3!double(ASPECT_RATIO * (x + (k1 + random) / N - SCREEN_WIDTH * 0.5) / (SCREEN_WIDTH * 0.5), (y + (k2 + random) / N - SCREEN_HEIGHT * 0.5) / (SCREEN_HEIGHT * 0.5), 0);
					
					Ray r = {cameraPos, p - cameraPos};
					
					HitInfo hitInfo = void;
					bool hit = scene.trace(r, hitInfo, 0.01);
					
					if( hit )
					{	
						auto color = hitInfo.hitSurface.shade(hitInfo, scene);
						
						if( color.x > 1.0f ) color.x = 1.0f;
						if( color.y > 1.0f ) color.y = 1.0f;
						if( color.z > 1.0f ) color.z = 1.0f;
					
						c.x += color.x;
						c.y += color.y;
						c.z += color.z;
					}
					else // add background color if no hit
					{
						c.x += 0.5f;
						c.y += 0.5f;
						c.z += 0.5f;
					}
				}
			}
			
			c = c / (N * N);
			sema.wait();
			writePixel(screen, x, SCREEN_HEIGHT - 1 - y, cast(ubyte)(c.x * 255), cast(ubyte)(c.y * 255), cast(ubyte)(c.z * 255));	
			sema.notify();
		}
		//sema.wait();
		//SDL_Flip(screen);
		//sema.notify();
	}
	
	watch.stop();
	writeln(watch.peek().nsecs / 1_000_000_000.0, " s");
	
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
		
		Vector3!double hitPoint = _hitInfo.hitPoint;
		
		for(int i = 0; i < scene.lights.length; ++i)
		{
			Light light = scene.lights[i];
			
			Vector3!double lightVector = light.position - hitPoint; // vector from the hit point to the light
		
			normalize(lightVector);
			
			HitInfo hitInfo2 = void;
			
			// calculate shadow ray by taking shadow samples
			// take shadow ray samples
			const int SHADOW_SAMPLES = cast(int)(light.u.length() * light.v.length() * light.w.length());
			
			auto tempColor = Vector3!float(0, 0, 0);
			
			
			double nDotLightVec = dot(n, lightVector);
			
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
				
					Ray ray = {hitPoint, randomPoint - hitPoint};
					normalize(ray.d);
					
					if( !scene.trace(ray, hitInfo2, 0.01) )
					{
						// no need to check if n dot l is > 0, because we already know it is
						
						tempColor.x += addedDiffuseColor.x;
						tempColor.y += addedDiffuseColor.y;
						tempColor.z += addedDiffuseColor.z;

						if( specularDotProduct > 0.0 )
						{
							tempColor.x += addedSpecularColor.x;
							tempColor.y += addedSpecularColor.y;
							tempColor.z += addedSpecularColor.z;
						}
					}
				}
			}
			finalColor.x += tempColor.x / SHADOW_SAMPLES;
			finalColor.y += tempColor.y / SHADOW_SAMPLES;
			finalColor.z += tempColor.z / SHADOW_SAMPLES;
		}
		
		return finalColor;
	}
}

/// a surface with a diffuse component that acts as a mirror as well
/*class Mirror : Material
{
	Vector3!float color;
	float mirrorPercentage; // percentage of the final color that comes from reflected light
	
	this(ubyte r, ubyte g, ubyte b, float _mirrorPercentage)
	{
		color.x = r / 255.0f;
		color.y = g / 255.0f;
		color.z = b / 255.0f;
		
		mirrorPercentage = _mirrorPercentage;
	}
	
	Vector3!float shade(const ref HitInfo _hitInfo, ref Scene scene) const
	{
		Vector3!float finalColor = Vector3!float(0.0f, 0.0f, 0.0f); // the final color
		Vector3!float normalColor = Vector3!float(0, 0, 0), reflectedColor = Vector3!float(0, 0, 0);
		
		HitInfo hitInfo = _hitInfo;
		
		hitInfo.surfaceNormal.normalize();
		hitInfo.ray.normalize();
		
		//foreach(light; scene.lights)
		for(int i = 0; i < scene.lights.length; ++i)
		{	
			Light light = scene.lights[i];
			
			Vector3!double lightVector = light.position - hitInfo.hitPoint; // vector from the hit point to the light
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
		
		return reflectedColor * mirrorPercentage + normalColor * (1 - mirrorPercentage);
	}
}*/

void makeScene2(ref Scene scene)
{	
	// floor
	Triangle floor = new Triangle(
								200,	-10,	160,
								0,		-10,	-50,
								-200,	-10,	160
								);
	
	floor.material = new SimpleColor(Vector3!float(0, 0, 0), Vector3!float(0.5f, 0.5f, 0.5f), Vector3!float(0, 0.2f, 0), 100);
	scene.objects.insert(floor);
	floor.name = "floor";
	
	/+for(int i = 0; i < 5; ++i)
	{
		Mesh mesh = loadMesh("../Models/dlang.obj");
		Material meshMat = new SimpleColor(Vector3!float(0, 0, 0), Vector3!float(1.0f, 0.0f, 0.0f), Vector3!float(1, 1, 1), 100);
		
		float randY = i * 10;//uniform(0, 5 + i * 15);
		float randX = (-1)^^i * i * 15; //uniform(-15 * i - 10, 15 * i + 10);
		
		foreach(t; mesh.triangles)
		{
			t.material = meshMat;
			
			t.a.x += randX;
			t.b.x += randX;
			t.c.x += randX;
			
			t.a.y += randY;
			t.b.y += randY;
			t.c.y += randY;
			
			t.a.z += 30 + i * 15;
			t.b.z += 30 + i * 15;
			t.c.z += 30 + i * 15;
			
			t.name = "Torus";
			scene.objects.insert(t);
		}
	}+/
	
	double angle = 0.0;
	Sphere s;
	for(int i = 0; i < 200; ++i)
	{
		auto center = Vector3!double(-120 + i * 5, 10 + 10 * sin(angle * PI / 180), 10 + i * 3 - 40);
		s = new Sphere(center, 2);
		s.material = new SimpleColor(Vector3!float(0, 0, 0), Vector3!float(1-i/200.0f, 1, 0.5f), Vector3!float(1, 1, 1), 100);
		scene.objects.insert(s);
		
		if( i < 50 )
		{
			angle += 6.0;
		}
		else
		{
			angle += 8.0;
			s.center.x -= 8 * (i-50);
		}
	}
	
	auto center = Vector3!double(0, 10, 55);
	Sphere s2 = new Sphere(center, 10);
	s2.material = new SimpleColor(Vector3!float(0, 0, 0), Vector3!float(173/255.0f, 234/255.0f, 234/255.0f), Vector3!float(1, 1, 1), 500);
	scene.objects.insert(s2);
	s2.name = "sphere";
	
	Light l = void;
	l.position = Vector3!double(-60, 180, -100);
	l.u = Vector3!double(3, 0, 0);
	l.v = Vector3!double(0, 3, 0);
	l.w = Vector3!double(0, 0, 3);
	l.I = Vector3!float(0.95f, 0.95f, 0.95f);
	scene.lights.insert(l);
}
