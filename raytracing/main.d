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
import raytracing.math;
import raytracing.raytracer;

import raytracing.materials.SimpleColor; // material we will be using

import std.c.stdlib;
import std.math;
import std.parallelism;
import std.random;
import core.sync.mutex;
import std.algorithm;
import std.range;
import std.random;

import core.stdc.time;

import derelict.sdl.sdl;

immutable SCREEN_WIDTH = 800;
immutable SCREEN_HEIGHT = 600;
immutable ASPECT_RATIO = SCREEN_WIDTH / cast(float)SCREEN_HEIGHT;

immutable ANTIALIASING_SAMPLES = 9;

void main()
{
	init(); // initialize SDL, set window caption etc.
	
	SDL_Surface* screen = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, 32, SDL_HWSURFACE);

	auto cameraPos = Vector3!double(0, 0, -1);
	auto cameraDirection = Vector3!double(0, 0, 1);
	
	// create the scene
	auto scene = Scene(20, 3);
	makeScene2(scene);

	// do necessary scene pre-calculations (e.g creation of BVH Tree)
	scene.preCalc();
	
	writeln("The scene has ", scene.objects.length, " triangles.");

	StopWatch watch;
	watch.start();

	// do raytracing
	new Raytracer().run(scene, cameraPos, screen, ANTIALIASING_SAMPLES);
	
	watch.stop();
	writeln(watch.peek().nsecs / 1_000_000_000.0, " s");
	
	SDL_Flip(screen); // update the screen

	SDL_Event event;
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

void makeScene1(ref Scene scene)
{
	// a triangle used as floor
	Triangle floor = new Triangle(
								200,	-10,	160,
								0,		-10,	-50,
								-200,	-10,	160
								);
	
	floor.material = new SimpleColor(Vector3!float(0, 0, 0), Vector3!float(0.5f, 0.5f, 0.5f), Vector3!float(0, 0.2f, 0), 100);
	scene.objects.insert(floor);

	Light l = void;
	l.position = Vector3!double(-60, 180, -100);
	l.u = Vector3!double(3, 0, 0);
	l.v = Vector3!double(0, 3, 0);
	l.w = Vector3!double(0, 0, 3);
	l.I = Vector3!float(0.95f, 0.95f, 0.95f);
	scene.lights.insert(l);
}

void makeScene2(ref Scene scene)
{	


	Sphere planet = new Sphere(Vector3!double(-500, 0, 10000), 6000);
	planet.material = new SimpleColor(Vector3!float(0, 0, 0), Vector3!float(1.0f, 0.5f, 0.128f), Vector3!float(1, 1, 1), 10);
	scene.objects.insert(planet);

	
	double angle = 0.0;
	Sphere s;
	for(int i = 0; i < 200; ++i)
	{
		auto center = Vector3!double(-120 + i * 5, 10 + 10 * sin(angle * PI / 180), 10 + i * 3 - 40);
		s = new Sphere(center, 2);
		s.material = new SimpleColor(Vector3!float(0, 0, 0), Vector3!float(1-i/200.0f, 1, 0.5f), Vector3!float(0, 0, 0), 100);
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
	s2.material = new SimpleColor(Vector3!float(0, 0, 0), Vector3!float(173/255.0f, 234/255.0f, 234/255.0f), Vector3!float(0, 0, 0), 500);
	scene.objects.insert(s2);
	
	Light l = void;
	l.position = Vector3!double(-60, 180, -100);
	l.u = Vector3!double(3, 0, 0);
	l.v = Vector3!double(0, 3, 0);
	l.w = Vector3!double(0, 0, 3);
	l.I = Vector3!float(0.95f, 0.95f, 0.95f);
	scene.lights.insert(l);
}

/// recursively prints a BVH tree to the standard output
void printBVH(Surface root, int i = 0, string str = "")
{
	if( root is null )
		return;
	
	writeln("------PRINT()------");
	//writeln("Name = ", root.name);
	writeln(root.boundingBox());
	writeln("------~~~~~~~------\n");
	
	if( (cast(BVHNode)root) !is null )
	{
		printBVH((cast(BVHNode)(root)).left, i+1, "left");
		printBVH((cast(BVHNode)(root)).right, i+1, "right");
	}
}