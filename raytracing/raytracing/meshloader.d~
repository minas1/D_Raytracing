module raytracing.meshloader;

public import raytracing.mesh;

import raytracing.triangle;
import raytracing.vector;

import std.stdio;
import std.algorithm;
import std.array;
import std.container;
import std.conv;

Mesh loadMesh(string filename)
{
	if( filename.endsWith(".obj") )
		return loadMeshWavefrontObj(filename);
	
	return null;
}

Mesh loadMeshWavefrontObj(string filename)
{
	auto file = File(filename, "r");
	
	Array!Vector3 vertices;
	vertices.reserve(10);
	
	Mesh mesh = new Mesh();
	
	// read all vertices first
	foreach(line; file.byLine)
	{
		if( line == "" ) continue;
		
		auto tokens = split(line);
		
		if( tokens[0] == "v" )			// vertex
		{
			Vector3 v = Vector3(to!float(tokens[1]), to!float(tokens[2]), to!float(tokens[3]));
			vertices.insert(v);
		}
	}
	
	file.seek(0);
	foreach(line; file.byLine)
	{
		if( line == "" ) continue;
		auto tokens = split(line);
		
		if( tokens[0] == "f" )		// face
		{
			auto x = countUntil(tokens[1], "/");
			if( x != -1 )
				tokens[1] = tokens[1][0..x];
			
			x = countUntil(tokens[2], "/");
			if( x != -1 )
				tokens[2] = tokens[2][0..x];
			
			x = countUntil(tokens[3], "/");
			if( x != -1 )
				tokens[3] = tokens[3][0..x];
			
			Triangle t = new Triangle();
			
			t.a = vertices[to!int(tokens[1]) - 1];
			t.b = vertices[to!int(tokens[2]) - 1];
			t.c = vertices[to!int(tokens[3]) - 1];
			
			mesh.triangles.insert(t);
		}
	}
	
	return mesh;
}