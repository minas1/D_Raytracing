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

import std.c.stdlib;

immutable SCREEN_WIDTH = 320;
immutable SCREEN_HEIGHT = 240;

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
	
	SDL_Surface* screen = SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, 32, SDL_HWSURFACE);
	SDL_Event event;
	
	srand(cast(uint)Clock.currTime.toUnixTime);
	
	// create the pixels array
	auto pixels = new Vector3[SCREEN_WIDTH][SCREEN_HEIGHT];
	Vector3 cameraPos = {0, 0, -1};
	
	// create the scene
	Scene scene;
	
	// create a sphere
	Vector3 center = {100, 0, 100};
	Sphere s = new Sphere(center, 20);
	
	scene.add(s);
	
	StopWatch watch;
	watch.start();
	
	ubyte red, green, blue;
	for(int x = 0; x < SCREEN_WIDTH; ++x)
	{
		red = cast(ubyte)rand() % 255;
		green = cast(ubyte)rand() % 255;
		blue = cast(ubyte)rand() % 255;
		
		for(int y = 0; y < SCREEN_HEIGHT; ++y)
		{
			writePixel(screen, x, y, red, green, blue);
			
			Vector3 p = {(x - SCREEN_WIDTH * 0.5f) / (SCREEN_WIDTH * 0.5f), (y - SCREEN_HEIGHT * 0.5f) / (SCREEN_HEIGHT * 0.5f), 0};
			
			Ray r = {cameraPos, p};
		}
	}
	
	watch.stop();
	writeln(watch.peek().nsecs / 1_000_000.0, " ms");
	
	SDL_Flip(screen); // update the screen

	bool quit = false;
	while( !quit )
	{
		SDL_WaitEvent(&event);
		/*if( SDL_PollEvent(&event) )
		{
		}*/
		
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