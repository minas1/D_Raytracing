module raytracing.bvh;

import raytracing.surface, raytracing.box, raytracing.vector, raytracing.ray, raytracing.scene;

class BVHNode : Surface
{
	Surface left, right; // left and right children nodes
	
	Box box; // bounding box
	
	override bool hit(const ref Ray r, float t0, float t1, ref HitInfo hitInfo)
	{
		import std.algorithm, std.stdio;
		
		if( box.intersects(r) )
		{
			float leftT = float.max, rightT = float.max;
			bool leftHit = void, rightHit = void;
			
			/*if( left is null && right is null )
			{
				//std.stdio.writeln("left & right are null -- they shouldn't!!!");
			}*/
			
			if( left !is null && right is null && left.hit(r, t0, t1, hitInfo) )
			{
				//writeln("left !is null, right is null");
				leftT = hitInfo.t;
			}
			else if( left is null && right !is null && right.hit(r, t0, t1, hitInfo) )
			{
				//writeln("left is null, right !is null");
				rightT = hitInfo.t;
			}
			else if( left !is null && right !is null )
			{
				//writeln("left !is null, right !is null");
				
				HitInfo leftHitInfo = hitInfo, rightHitInfo = hitInfo;
				
				leftHit = left.hit(r, t0, t1, leftHitInfo);
				leftT = leftHitInfo.t;
				
				rightHit = right.hit(r, t0, t1, rightHitInfo);
				rightT = rightHitInfo.t;
				
				if( leftHit && !rightHit )
				{
					//writeln("Only left subtree was hit. t = ", hitInfo.t);
					hitInfo = leftHitInfo;
				}
				else if( !leftHit && rightHit )
				{
					//writeln("Only right subtree was hit. t = ", hitInfo.t);
					hitInfo = rightHitInfo;
				}
				else if( leftHit && rightHit )
				{
					//writeln("Both subtrees were hit. leftT = ", leftT, " rightT = ", rightT);
					hitInfo = (leftT < rightT ? leftHitInfo : rightHitInfo);
				}
				else // both false
				{
					//writeln("Both subtrees were NOT hit.");
					return false;
				}
			}
			
			return true;
		}
		
		return false;
	}
	
	/// returns the bounding box of this surface
	override Box boundingBox() const
	{
		return box;
	}
	
	override Vector3 shade(const ref HitInfo hitInfo, ref Scene scene) const
	{
		//std.stdio.writeln("In BVH.shade()");
		return Vector3(0, 0, 0);
	}
}

/// creates a BVH tree. axis is the axis used for the 1st division. 0: x axis, 1: y, 2: z
BVHNode createBVHTree(Surface[] objects, ubyte axis = 0, int depth = 0)
{
	import std.algorithm, std.stdio;
	
	auto node = new BVHNode();
	
	if( objects.length == 1 )
	{
		//writeln("One object. Depth = ", depth);
		
		node.left = objects[0];
		node.box = objects[0].boundingBox();
	}
	else if( objects.length == 2 )
	{
		//writeln("Two objects. Depth = ", depth);
		
		node.left = objects[0];
		node.right = objects[1];
		
		auto b1 = objects[0].boundingBox();
		auto b2 = objects[1].boundingBox();
		node.box = combine(b1, b2);
	}
	else
	{
		//writeln(objects.length, " objects. Depth = ", depth);
		
		switch(axis)
		{
		case 0:
			//sort!("(a.boundingBox().min.x + a.boundingBox().max.x) * 0.5f < (b.boundingBox().min.x + b.boundingBox().max.x) * 0.5f", SwapStrategy.unstable)(objects);
			sort!((a,b) => (a.boundingBox().min.x + a.boundingBox().max.x) * 0.5f < (b.boundingBox().min.x + b.boundingBox().max.x) * 0.5f)(objects);
			break;
		
		case 1:
			//sort!("(a.boundingBox().min.y + a.boundingBox().max.y) * 0.5f < (b.boundingBox().min.y + b.boundingBox().max.y) * 0.5f", SwapStrategy.unstable)(objects);
			sort!((a,b) => (a.boundingBox().min.y + a.boundingBox().max.y) * 0.5f < (b.boundingBox().min.y + b.boundingBox().max.y) * 0.5f)(objects);
			break;
				
		case 2:
			sort!((a,b) => (a.boundingBox().min.z + a.boundingBox().max.z) * 0.5f < (b.boundingBox().min.z + b.boundingBox().max.z) * 0.5f)(objects);
			break;
				
		default:
			writeln("In ", __FILE__, ".createBVHTree(), axis is ", axis, " but must be 0, 1 or 2. Assuming 0.");
			sort!("(a.boundingBox().min.x + a.boundingBox().max.x) * 0.5f < (b.boundingBox().min.x + b.boundingBox().max.x) * 0.5f", SwapStrategy.unstable)(objects);
		}
		
		node.left = createBVHTree(objects[0..$/2], (axis + 1) % 3, depth + 1);
		node.right = createBVHTree(objects[$/2..$], (axis + 1) % 3, depth + 1);
		
		auto b1 = node.left.boundingBox(), b2 = node.right.boundingBox();
		node.box = combine(b1, b2);
	}
	
	return node;
}

BVHNode createBVHTree2(Surface[] objects, ubyte axis = 0, int depth = 0)
{
	import std.algorithm, std.stdio;
	
	BVHNode root;
	
	//sort!("(a.boundingBox().min.x + a.boundingBox().max.x) * 0.5f < (b.boundingBox().min.x + b.boundingBox().max.x) * 0.5f", SwapStrategy.unstable)(objects);
	
	while( objects.length > 1 )
	{
		writeln("--- Level ---");
		foreach(o; objects)
			write("[", o.name, "] ");
		writeln();
		
		auto temp = new Surface[objects.length/2 + 1];
		auto sz = 0UL;
		
		for(auto i = 0UL; i < objects.length; i += 2)
		{
			writeln("i = ", i, " sz = ", sz+1);
			
			BVHNode parent = new BVHNode();
			parent.name = "p";
			
			parent.left = objects[i];
			if( i + 1 < objects.length )
			{	
				parent.right = objects[i+1];
			
				auto box1 = objects[i].boundingBox(), box2 = objects[i+1].boundingBox();
				parent.box = combine(box1, box2);
			}
			else
			{
				parent.right = null;
				parent.box = objects[i].boundingBox();
			}
			
			temp[sz++] = parent;
		}
		
		temp.length = sz;
		objects = temp;
	}
	
	root = cast(BVHNode)objects[0];
	
	return root;
}