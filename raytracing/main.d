/*
 * TODO:
 * 
 * 1) Make BVH.hit() non-recursive
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
import raytracing.meshloader;
import raytracing.box;
import raytracing.bvh;

import std.c.stdlib;
import std.math;
import std.parallelism;
import std.random;
import core.sync.semaphore;
import std.algorithm;

import derelict.sdl.sdl;

immutable SCREEN_WIDTH = 800;
immutable SCREEN_HEIGHT = 600;
immutable ASPECT_RATIO = SCREEN_WIDTH / cast(float)SCREEN_HEIGHT;

/++void printBVH(Surface root, int i = 0, string str = "")
{
	if( root is null )
		return;
	
	writeln("------PRINT()------");
	
	//if( cast(Triangle)root ) writeln("This is a triangle.");
	//else if( cast(Sphere)root ) writeln("This is a sphere.");
	
	//writeln(root.boundingBox());
	writeln("address = ", cast(void*)root);
	writeln("------~~~~~~~------\n");
	
	if( (cast(BVHNode)root) !is null )
	{
		printBVH((cast(BVHNode)(root)).left, i+1, "left");
		printBVH((cast(BVHNode)(root)).right, i+1, "right");
	}
}++/


void main()
{
	core.memory.GC.disable();
	
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
	Scene scene = Scene(20, 3);
	makeScene2(scene);
	
	scene.preCalc();
	
	writeln("The scene has ", scene.objects.length, " triangles.");
	writeln("Rendering...");
	StopWatch watch;
	watch.start();
	
	int[] ys = new int[SCREEN_HEIGHT];
	for(int i = 0; i < ys.length; ++i)
		ys[i] = i;
	
	Semaphore sema = new Semaphore(1);
	
	foreach(y; parallel(ys))
	//for(int y = 0; y < SCREEN_HEIGHT; ++y)
	{
		for(int x = 0; x < SCREEN_WIDTH; ++x)
		{
			Vector3 p = Vector3(ASPECT_RATIO * (x - SCREEN_WIDTH * 0.5f) / (SCREEN_WIDTH * 0.5f), (y - SCREEN_HEIGHT * 0.5f) / (SCREEN_HEIGHT * 0.5f), 0);
			Ray r = {cameraPos, p - cameraPos};
			
			HitInfo hitInfo = void;
			bool hit = scene.trace(r, hitInfo, 0.1f);
			
			if( hit )
			{
				Vector3 color = hitInfo.hitSurface.shade(hitInfo, scene);
				
				if( color.x > 1.0f ) color.x = 1.0f;
				if( color.y > 1.0f ) color.y = 1.0f;
				if( color.z > 1.0f ) color.z = 1.0f;
				
				sema.wait();
				writePixel(screen, x, SCREEN_HEIGHT - 1 - y, cast(ubyte)(color.x * 255), cast(ubyte)(color.y * 255), cast(ubyte)(color.z * 255));	
				sema.notify();
			}
			else
			{
				sema.wait();
				writePixel(screen, x, SCREEN_HEIGHT - 1 - y, cast(ubyte)(0.5f * 255), cast(ubyte)(0.5f * 255), cast(ubyte)(0.5f * 255));	
				sema.notify();
			}
		}
		//sema.wait();
		//SDL_Flip(screen);
		//sema.notify();
	}
	
	watch.stop();
	writeln(watch.peek().nsecs / 1_000_000_100.0, " s");
	
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
	Vector3 ka;	// ambient component
	Vector3 kd;	// diffuse component
	Vector3 ks;	// specular component
	float specularComponent; // component that specifies the size of the specular highlight 
	
	this(Vector3 _ka, Vector3 _kd, Vector3 _ks, float _specularComponent)
	{
		ka = _ka;
		kd = _kd;
		ks = _ks;
		
		specularComponent = _specularComponent;
	}
	
	Vector3 shade(const ref HitInfo _hitInfo, ref Scene scene) const
	{
		Vector3 finalColor = ka; // the final color
		
		Vector3 n = _hitInfo.surfaceNormal;
		normalize(n);
		
		Vector3 hitRay = -_hitInfo.ray;
		normalize(hitRay);
		
		Vector3 hitPoint = _hitInfo.hitPoint;
		
		// normalize the surface normal
		/++hitInfo.surfaceNormal.normalize();
		
		hitInfo.ray = -hitInfo.ray;
		hitInfo.ray.normalize();++/
		
		for(int i = 0; i < scene.lights.length; ++i)
		{
			Light light = scene.lights[i];
			
			Vector3 lightVector = light.position - hitPoint; // vector from the hit point to the light
		
			normalize(lightVector);
			
			HitInfo hitInfo2;
			Ray ray = {hitPoint, light.position - hitPoint};
			normalize(ray.d);
			
			//if( !scene.trace(ray, hitInfo2, 0.1f) )
			{
				// diffuse shading
				if( dot(n, lightVector) > 0 )
				{
					finalColor = finalColor + light.I * kd * dot(n, lightVector);

					// specular shading
					Vector3 H = (lightVector + hitRay) * 0.5f; // find the half vector, H
					normalize(H);
					
					float specularDotProduct = dot(n, H);
					
					if( specularDotProduct > 0.0f )
						finalColor = finalColor + light.I * ks * std.math.pow(specularDotProduct, specularComponent);
				}
			}
			/++else
			{
				// no color is added, shadow is shown
			}++/
		}
		
		return finalColor;
	}
}

/// a surface with a diffuse component that acts as a mirror as well
/++class Mirror : Material
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
	
	Vector3 shade(const ref HitInfo hitInfo, ref Scene scene) const
	{
		Vector3 finalColor = Vector3(0.0f, 0.0f, 0.0f); // the final color
		Vector3 normalColor = Vector3(0, 0, 0), reflectedColor = Vector3(0, 0, 0);
		
		hitInfo.surfaceNormal.normalize();
		hitInfo.ray.normalize();
		
		//foreach(light; scene.lights)
		for(int i = 0; i < scene.lights.length; ++i)
		{	
			Light light = scene.lights[i];
			
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
		
		return reflectedColor * mirrorPercentage + normalColor * (1 - mirrorPercentage);
	}
}++/

void makeScene2(ref Scene scene)
{	
	// floor
	Triangle floor = new Triangle(
								200, -10, 200,
								0, -10, -10,
								-200, -10, 200
								);
	
	floor.material = new SimpleColor(Vector3(0, 0, 0), Vector3(1, 1, 1), Vector3(0, 0, 0), 10);
	scene.objects.insert(floor);
	//floor.name = "floor";
	
	Mesh mesh = loadMesh("../Models/torus.obj");
	Material meshMat = new SimpleColor(Vector3(0, 0, 0), Vector3(0.0f, 1.0f, 1.0f), Vector3(1, 1, 1), 100);
	foreach(t; mesh.triangles)
	{
		t.material = meshMat;
		
		t.a.y += 10;
		t.b.y += 10;
		t.c.y += 10;
		
		t.a.z += 95;
		t.b.z += 95;
		t.c.z += 95;
		
		scene.objects.insert(t);
	}
	
	float angle = 0;
	Sphere s;
	for(int i = 0; i < 200; ++i)
	{
		Vector3 center = Vector3(-120 + i * 5, 10 + 10 * sin(angle * PI / 180), 10 + i * 3);
		s = new Sphere(center, 2);
		s.material = new SimpleColor(Vector3(0, 0, 0), Vector3(1-i/200.0f, 1, 0.5f), Vector3(1, 1, 1), uniform(10.0f, 100));
		scene.objects.insert(s);
		
		if( i < 50 )
		{
			angle += 6.0f;
		}
		else
		{
			angle += 8.0f;
			s.center.x -= 8 * (i-50);
		}
		//s.name = "INVISIBLE";
		
		//break;
	}
	
	for(int i = 0; i < 10; ++i)
	{
		for(int j = 0; j < 10; ++j)
		{
			for(int k = 0; k < 10; ++k)
			{
				Vector3 center = Vector3(i, j, k);
				Sphere sss = new Sphere(center, 0.1f);
				sss.material = new SimpleColor(Vector3(0, 0, 0), Vector3(1, 1, 1), Vector3(0, 0, 0), 0);
				scene.objects.insert(sss);
			}
		}
	}
	
	Vector3 center = Vector3(0, 10, 95);
	Sphere s2 = new Sphere(center, 10);
	s2.material = new SimpleColor(Vector3(0, 0, 0), Vector3(173/255.0f, 234/255.0f, 234/255.0f), Vector3(1, 1, 1), 100);
	scene.objects.insert(s2);
	//s2.name = "visible";
	
	// top light
	Light l;
	
	l.position = Vector3(0, 100, 200);
	l.I = Vector3(173/255.0f, 234/255.0f, 234/255.0f);
	scene.lights.insert(l);
	
	// left light
	l.position = Vector3(-30, 0, 0);
	l.I = Vector3(1, 1, 1);
	scene.lights.insert(l);
}