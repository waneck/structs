package haxe.structs;

class Tools
{
	public static inline function unsafeCast<T>(obj:Dynamic, cls:Class<T>):T
	{
		return obj;
	}
	
}