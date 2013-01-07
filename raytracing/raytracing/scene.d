module raytracing.scene;

import std.container;

import raytracing.ray;
import raytracing.surface;
import raytracing.light;
import raytracing.box;

struct Cell
{
	std.container.Array!Surface surfaces;
	Box box;
}

struct Scene
{
	Array!Surface objects;	// objects in the scene
	Array!Light lights;		// lights in the scene
	//Light[] lights;
	
	Cell[] grid; // used for uniform space partitioning
	
	Cell[][][] grid2; // TODO: use this to not check all grids
	
	@disable this(); // disable the default constructor because space needs to be reserved for objects and lights
	
	this(size_t objectReserveSpace = 20, size_t lightReserveSpace = 3)
	{
		objects.reserve(objectReserveSpace);
		lights.reserve(lightReserveSpace);
	}
	
	bool trace(const ref Ray ray, ref HitInfo hitInfo, float t0)
	{
		HitInfo	closestHitInfo;	// hitInfo of the closest object
		closestHitInfo.t = float.max;
		
		traceUsingUSP(ray, hitInfo, t0, closestHitInfo);
		//traceAll(ray, hitInfo, t0, closestHitInfo);
		
		hitInfo = closestHitInfo;
		
		return closestHitInfo.hitSurface !is null;
	}
	
	/// trace all rays with all objects
	private void traceAll(const ref Ray ray, ref HitInfo hitInfo, float t0, ref HitInfo closestHitInfo)
	{
		for(int i = 0; i < objects.length; ++i)
		{
			// TODO: change the 1000 to something else, preferably not hardcoded
			if( objects[i].hit(ray, t0, 1000, hitInfo) && hitInfo.t < closestHitInfo.t && hitInfo.t > t0) // hit?
			{
				closestHitInfo = hitInfo;
			}
		}
	}
	
	/// trace rays using uniform space partitioning data structure
	private void traceUsingUSP(const ref Ray ray, ref HitInfo hitInfo, float t0, ref HitInfo closestHitInfo)
	{
		/++for(int i = 0; i < grid2.length; ++i)
		{
			for(int j = 0; j < grid2[i].length; ++j)
			{
				for(int k = 0; k < grid2[i][j].length; ++k)
				{
					if( i == 0 || j == 0 || k == 0 || i == grid2.length - 1 || j == grid2[i].length - 1 || k == grid2[i][j].length - 1)
					{
						if( grid2[i][j][k].box.intersects(ray) )
							std.stdio.writefln("Intersection @ %s, %s, %s", i, j, k);
					}
				}
			}
		}
		std.stdio.readln();++/
		
		for(int i = 0; i < grid.length; ++i)
		{
			if( grid[i].box.intersects(ray) )
			{
				for(int m = 0; m < grid[i].surfaces.length; ++m)
				{
					if( grid[i].surfaces[m].hit(ray, t0, 1000, hitInfo) && hitInfo.t < closestHitInfo.t && hitInfo.t > t0) // hit?
					{
						closestHitInfo = hitInfo;
					}
				}
			}
		}
	}
	
	void preCalc()
	{
		grid = buildUSP(objects);
	}
	
	/// build uniform space partitioning
	private Cell[] buildUSP(ref Array!Surface surfaces)
	{
		import raytracing.vector, raytracing.box;
		import std.stdio, std.math;

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
		float GRID_SIZE = avgVol * 10;
		
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
		
		// set the position of the bounding boxes and put the surfaces inside them
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
					
					// put the Surfaces into the boxes
					foreach(obj; surfaces)
					{
						Box box2 = obj.boundingBox();
						
						bool bX = (box2.min.x <= box1.min.x && box2.max.x >= box1.min.x) || (box2.min.x <= box1.max.x && box2.max.x >= box1.min.x);
						bool bY = (box2.min.y <= box1.min.y && box2.max.y >= box1.min.y) || (box2.min.y <= box1.max.y && box2.max.y >= box1.min.y);
						bool bZ = (box2.min.z <= box1.min.z && box2.max.z >= box1.min.z) || (box2.min.z <= box1.max.z && box2.max.z >= box1.min.z);
						
						if( bX && bY && bZ )
							grid[i][j][k].surfaces.insert(obj);
					}
				}
			}
		}
		
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
		
		grid2 = grid;
		
		Cell[] nonEmpty = new Cell[dimX * dimY * dimZ - empty];
		int index = 0;
		for(int i = 0; i < dimX; ++i)
		{
			for(int j = 0; j < dimY; ++j)
			{
				for(int k = 0; k < dimZ; ++k)
				{
					if( grid[i][j][k].surfaces.length != 0 )
						nonEmpty[index++] = grid[i][j][k];
				}
			}
		}
		
		return nonEmpty;
	}
}