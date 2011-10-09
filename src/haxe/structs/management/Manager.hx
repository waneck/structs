package haxe.structs.management;

/**
 * ...
 * @author waneck
 */

class Manager 
{

	public static function malloc(sizeInBytes:Int):MemoryAddress
	{
		return 0;
	}
	
	public static function realloc(addr:MemoryAddress, newSizeInBytes:Int):MemoryAddress
	{
		return 0;
	}
	
	public static function free(addr:MemoryAddress):Void
	{
		
	}
	
	public static function getBytesLength(addr:MemoryAddress):Int
	{
		return 0;
	}
	
	
}

typedef MemoryAddress = Int;