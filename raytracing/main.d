/*
 * TODO:
 * a) Make the loop parallel - find where the problem is and it crashes
 * b) make a Mesh object
 * c) Make a .obj loader -- study the file format, see examples from Blender
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

import std.c.stdlib;
import std.math;
import std.parallelism;
import std.random;
import core.sync.semaphore;
import std.algorithm;

immutable SCREEN_WIDTH = 800;
immutable SCREEN_HEIGHT = 600;
immutable ASPECT_RATIO = SCREEN_WIDTH / cast(float)SCREEN_HEIGHT;

import derelict.sdl.sdl;

/++struct Cell
{
	std.container.Array!Surface surfaces;
	Box box;
}

void g(ref std.container.Array!Surface surfaces)
{	
	Vector3 min = Vector3(float.max, float.max, float.max),
			max = Vector3(-float.infinity, -float.infinity, -float.infinity);
	
	float avgVol = 0;
	
	// find the minimum and maximum points
	foreach(obj; surfaces)
	{
		Box box = obj.boundingBox();
		
		min.x = std.algorithm.min(min.x, box.min.x);
		min.y = std.algorithm.min(min.y, box.min.y);
		min.z = std.algorithm.min(min.z, box.min.z);
		
		max.x = std.algorithm.max(max.x, box.max.x);
		max.y = std.algorithm.max(max.y, box.max.y);
		max.z = std.algorithm.max(max.z, box.max.z);
		
	
		avgVol += std.algorithm.max(abs(box.max.x - box.min.x), abs(box.max.y - box.min.y), abs(box.max.z - box.min.z));
	}
	
	avgVol /= surfaces.length;
	float GRID_SIZE = avgVol * 8;
	
	writeln("The scene has ", surfaces.length, " objects.");
	
	writeln("min = ", min, "\nmax = ", max);
	writeln("\nx axis needs ", ceil((max.x - min.x)/GRID_SIZE));
	writeln("y axis needs ", ceil((max.y - min.y)/GRID_SIZE));
	writeln("z axis needs ", ceil((max.z - min.z)/GRID_SIZE));
	
	int dimX = cast(int)ceil((max.x - min.x)/GRID_SIZE);
	int dimY = cast(int)ceil((max.y - min.y)/GRID_SIZE);
	int dimZ = cast(int)ceil((max.z - min.z)/GRID_SIZE);
	
	writeln("\nWith grid size of ", GRID_SIZE, " we need: ", dimX * dimY * dimZ);
	
	auto grid = new Cell[][][](dimX, dimY, dimZ);
	
	// set the position of the bounding boxes
	for(int i = 0; i < dimX; ++i)
	{
		for(int j = 0; j < dimY; ++j)
		{
			for(int k = 0; k < dimZ; ++k)
			{
				grid[i][j][k].box.min.x = min.x + i * GRID_SIZE;
				grid[i][j][k].box.min.y = min.y + j * GRID_SIZE;
				grid[i][j][k].box.min.z = min.z + k * GRID_SIZE;
				
				grid[i][j][k].box.max.x = grid[i][j][k].box.min.x + GRID_SIZE;
				grid[i][j][k].box.max.y = grid[i][j][k].box.min.y + GRID_SIZE;
				grid[i][j][k].box.max.z = grid[i][j][k].box.min.z + GRID_SIZE;
				
				Box box1 = grid[i][j][k].box;
				
				//writeln("Testing grid[", i, "][", j, "][", k, "]");
				//writeln("from ", box1.min, " to\t", box1.max);
				
				// put the Surfaces into the boxes
				foreach(obj; surfaces)
				{
					//writeln("\tTesting obj with center at ", (cast(Sphere)obj).center);
					
					Box box2 = obj.boundingBox();
					//writeln("\tobj bbox = from ", box2.min, " to ", box2.max);
					
					Vector3 v[8];
					
					v[0] = Vector3(box2.min.x, box2.min.y, box2.min.z);
					v[1] = Vector3(box2.min.x, box2.min.y, box2.max.z);
					v[2] = Vector3(box2.min.x, box2.max.y, box2.min.z);
					v[3] = Vector3(box2.min.x, box2.max.y, box2.max.z);
					v[4] = Vector3(box2.max.x, box2.min.y, box2.min.z);
					v[5] = Vector3(box2.max.x, box2.min.y, box2.max.z);
					v[6] = Vector3(box2.max.x, box2.max.y, box2.min.z);
					v[7] = Vector3(box2.max.x, box2.max.y, box2.max.z);
					
					// if one point of the surface's bbox is inside the cell, put it in the list
					for(int l = 0; l < 8; ++l)
					{
						bool b = box1.isPointInside(v[l]);
						//writeln("\tTesting point at ", v[l], "... ", b);
						
						if( b )
						{
							grid[i][j][k].surfaces.insert(obj);
							//writeln("\tYes!");
							break;
						}
					}
					
					// if all of the points are outside, it means that the cell is inside the surface's bounding box
					// so add it to the list as well
					
					if( box2.min.x < box1.min.x && box2.min.y < box1.min.y && box2.min.z < box1.min.z
					&&  box2.max.x > box1.max.x && box2.max.y > box1.max.y && box2.max.z > box1.max.z )
						grid[i][j][k].surfaces.insert(obj);
				}
			}
		}
	}
	
	//writeln();
	
	// print
	ulong empty;
	ulong total;
	ulong maxObjects = ulong.min;
	for(int i = 0; i < dimX; ++i)
	{
		for(int j = 0; j < dimY; ++j)
		{
			for(int k = 0; k < dimZ; ++k)
			{
				/*writeln("Printing box ", i, ".", j, ".", k, " from ", grid[i][j][k].box.min, ", to ", grid[i][j][k].box.max);
				foreach(obj; grid[i][j][k].surfaces)
				{
					writeln((cast(Sphere)obj).center);
				}
				writeln();*/
				if( grid[i][j][k].surfaces.length == 0 )
					++empty;
				
				total += grid[i][j][k].surfaces.length;
				maxObjects = std.algorithm.max(maxObjects, grid[i][j][k].surfaces.length);
			}
		}
	}
	
	writeln("There are ", dimX * dimY * dimZ - empty, " non-empty cells.");
	writeln("Maximum objects in a cell: ", maxObjects);
	writeln("Average objects per cell (empty cells not included): ", cast(float)(total-empty) / (dimX * dimY * dimZ-empty));
}++/

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
	Scene scene = Scene();
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
		sema.wait();
		SDL_Flip(screen);
		sema.notify();
	}
	
	watch.stop();
	writeln(watch.peek().nsecs / 1_000_000_100.0, " s");

	//writeln("# of lights = ", scene.lights.length);
		
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
		n.normalize();
		
		Vector3 hitRay = -_hitInfo.ray;
		hitRay.normalize();
		
		Vector3 hitPoint = _hitInfo.hitPoint;
		
		// normalize the surface normal
		/++hitInfo.surfaceNormal.normalize();
		
		hitInfo.ray = -hitInfo.ray;
		hitInfo.ray.normalize();++/
		
		for(int i = 0; i < scene.lights.length; ++i)
		{
			Light light = scene.lights[i];
			
			Vector3 lightVector = light.position - hitPoint; // vector from the hit point to the light
		
			lightVector.normalize();
			
			HitInfo hitInfo2;
			Ray ray = {hitPoint, light.position - hitPoint};
			ray.d.normalize();
			
			if( !scene.trace(ray, hitInfo2, 0.1f) )
			{
				// diffuse shading
				if( n.dot(lightVector) > 0 )
				{
					finalColor = finalColor + light.I * kd * n.dot(lightVector);

					// specular shading
					Vector3 H = (lightVector + hitRay) * 0.5f; // find the half vector, H
					H.normalize();
					
					float specularDotProduct = dot(n, H);
					
					if( specularDotProduct > 0.0f )
						finalColor = finalColor + light.I * ks * std.math.pow(specularDotProduct, specularComponent);
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
	
		
	/*Mesh mesh = loadMesh("../Models/torus.obj");
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
	}*/
	
	float angle = 0;
	for(int i = 0; i < 200; ++i)
	{
		Vector3 center = Vector3(-120 + i * 5, 10 + 10 * sin(angle * PI / 180), 10 + i * 3);
		Sphere s = new Sphere(center, 2);
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
	}
	
	Vector3 center = Vector3(0, 10, 95);
	Sphere s = new Sphere(center, 10);
	s.material = new SimpleColor(Vector3(0, 0, 0), Vector3(173/255.0f, 234/255.0f, 234/255.0f), Vector3(1, 1, 1), 500);
	scene.objects.insert(s);
	
	
	// top light
	Light l;
	
	l.position = Vector3(0, 100, 200);
	l.I = Vector3(173/255.0f, 234/255.0f, 234/255.0f);
	scene.lights.insert(l);
	
	// left light
	l.position = Vector3(-80, 0, 0);
	l.I = Vector3(1, 1, 1);
	scene.lights.insert(l);
}