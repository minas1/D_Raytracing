module raytracing.surfaces.bvh;

import	raytracing.surfaces.surface,
		raytracing.box,
		raytracing.vector,
		raytracing.ray,
		raytracing.scene;

/** Bounding Volume Hierarchy node
 * For information about BVH trees: http://en.wikipedia.org/wiki/Bounding_volume_hierarchy
 */
class BVHNode : Surface
{
	private Surface left, right; // left and right children nodes
	
	Box box; // bounding box
	
	override bool hit(const ref Ray r, double t0, double t1, ref HitInfo hitInfo)
	{
		// first check if there is an interesction with the outer bounding box
		if( box.intersects(r) )
		{
			double leftT = void, rightT = void;
			bool leftHit = void, rightHit = void;

			// hit left child and right doesn't exist
			if( left !is null && right is null && left.hit(r, t0, t1, hitInfo) )
				leftT = hitInfo.t;
			// hit hight child and left doesn't exist
			else if( left is null && right !is null && right.hit(r, t0, t1, hitInfo) )
				rightT = hitInfo.t;
			// if both children exist
			else if( left !is null && right !is null )
			{
				// return the closest (or none if none of the is hit by the ray)

				HitInfo leftHitInfo = hitInfo, rightHitInfo = hitInfo;
				
				// left child
				leftHit = left.hit(r, t0, t1, leftHitInfo);
				leftT = leftHitInfo.t;
				
				// right child
				rightHit = right.hit(r, t0, t1, rightHitInfo);
				rightT = rightHitInfo.t;
				
				if( leftHit && !rightHit )
					hitInfo = leftHitInfo;
				else if( !leftHit && rightHit )
					hitInfo = rightHitInfo;
				else if( leftHit && rightHit )
					hitInfo = (leftT < rightT ? leftHitInfo : rightHitInfo);
				else // both false
					return false;
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
	
	override Vector3!float shade(const ref HitInfo hitInfo, ref Scene scene) const
	{
		return Vector3!float(0, 0, 0);
	}
}

/// creates a BVH tree from the given Surfaces. axis is the axis used for the 1st division. 0: x axis, 1: y, 2: z
BVHNode createBVHTree(Surface[] objects, ubyte axis = 0, int depth = 0)
{
	import std.algorithm, std.stdio;
	
	auto node = new BVHNode();

	// terminal cases
	if( objects.length == 1 )
	{
		node.left = objects[0];
		node.box = objects[0].boundingBox();
	}
	else if( objects.length == 2 )
	{
		node.left = objects[0];
		node.right = objects[1];
		
		auto b1 = objects[0].boundingBox();
		auto b2 = objects[1].boundingBox();
		node.box = combine(b1, b2);
	}
	else
	{
		switch(axis)
		{
		case 0:
			sort!("(a.boundingBox().min.x + a.boundingBox().max.x) * 0.5f < (b.boundingBox().min.x + b.boundingBox().max.x) * 0.5f", SwapStrategy.unstable)(objects);
			break;
		
		case 1:
			sort!("(a.boundingBox().min.y + a.boundingBox().max.y) * 0.5f < (b.boundingBox().min.y + b.boundingBox().max.y) * 0.5f", SwapStrategy.unstable)(objects);
			break;
				
		case 2:
			sort!("(a.boundingBox().min.z + a.boundingBox().max.z) * 0.5f < (b.boundingBox().min.z + b.boundingBox().max.z) * 0.5f", SwapStrategy.unstable)(objects);
			break;
				
		default:
			writeln("In ", __FILE__, ".createBVHTree(), axis is ", axis, " but must be 0, 1 or 2. Assuming 0.");
			sort!("(a.boundingBox().min.x + a.boundingBox().max.x) * 0.5f < (b.boundingBox().min.x + b.boundingBox().max.x) * 0.5f", SwapStrategy.unstable)(objects);
		}

		node.left = createBVHTree(objects[0..$/2], (axis + 1) % 3, depth + 1); // half surfaces go to left child
		node.right = createBVHTree(objects[$/2..$], (axis + 1) % 3, depth + 1); // other half to the right
		
		auto b1 = node.left.boundingBox(), b2 = node.right.boundingBox();
		node.box = combine(b1, b2); // combine the children's bounding boxes to get our own
	}
	
	return node;
}
