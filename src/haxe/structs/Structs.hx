package haxe.structs;
import haxe.macro.Expr;

/**
 * ...
 * @author waneck
 */

typedef Structs<T> = //where T is AbstractStruct
	#if (flash9 || cpp) Int
	#elseif js js.webgl.TypedArray.Data
	#elseif neko haxe.io.BytesData
	//php SplFixedArray 
	//java http://www.javamex.com/tutorials/io/nio_buffers.shtml
	//neko [custom made code]
	//c# Array of structs really
	#else Array<Dynamic>
#end;

class StructsExtensions
{
	
	@:macro public static function get(me:ExprRequire<Structs<Dynamic>>, index:Expr, ?field:Null<Expr>):Expr
	{
		return null;
	}
	
	@:macro public static function optimize(me:Expr):Expr
	{
		//here we will run a deep analysis on the block me;
		//as a first need, all unresolved CIdent will be considered as this.
		//then, we will detect the make() and makeFrom() patterns, and all structs will be unrolled to temp variables
		//we will then inline all methods that are from structs
		//we will then treat field access as var access, and also perform one pass of escape analysis
		//this will deterine all structs that need to be remade, and also will determine the vars that can be reused.
		//This will prevent the creation of lots of temp struct variables, and also will allow for any haxe target to benefit
		//from having stack allocated instances
		return null;
	}
}