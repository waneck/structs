package ;
import haxe.structs.Structs;
using haxe.structs.Structs;

/**
 * ...
 * @author waneck
 */

class Main 
{
	static var a:Structs<Matrix>;
	
	static function main() 
	{
		#if flash9
		var ba = new flash.utils.ByteArray();
		ba.length = 1024;
		flash.Memory.select(ba);
		#end
		
		a.set(10, test = 1, test2 = 2, test3 = 3, test4 = 4);
		
		trace(a.get(10, test3));
		//var m = new Matrix();
		//m.test;
		trace(a.get(10));
	}
	
}