module raytracing.math;

import core.stdc.stdlib;

/// returns a double from [i, j]
double randDouble(double i, double j) @safe nothrow
{
	return i + (j - i) * (rand() / cast(double)RAND_MAX);
}