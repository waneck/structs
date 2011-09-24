package haxe.structs;

/**
 * This interface can be implemented by any class that makes use of a struct. A macro will run that will
 * 	* transform any struct instance into member variables
 *  * transform any struct member call into its inlined and optimized counterpart
 *  * automatically apply StructsExtensions.optimize() to all its functions
 * @author waneck
 */

@:autoBuild(haxe.structs.StructExtensions.buildOptimized())
interface OptimizedStructUsage 
{
	
}