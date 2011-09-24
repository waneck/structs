package haxe.structs.management;

/**
 * ...
 * @author waneck
 */

class Manager 
{

	public static function malloc(sizeInBytes:Int):MemoryAddress
	{
		
	}
	
	public static function realloc(addr:MemoryAddress, newSizeInBytes:Int):MemoryAddress
	{
		
	}
	
	public static function free(addr:MemoryAddress, sizeInBytes:Int):Void
	{
		
	}
	
	
}

typedef MemoryAddress = Int;