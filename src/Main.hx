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
		
		a = Matrix.structs(11);
		
		a.set(10, this.test = 1, test2 = 2, test3 = 3, test4 = 4);
		
		trace(a.get(10, test3));
		//var m = new Matrix();
		//m.test;
		trace(a.get(10));
		
		a.set(9, new Matrix(1,2,3,4));
		trace(a.get(9));
		
		a.get(5, this.test);
		
		a.set(11, this.test = 1, test2 = 2, test3 = 3, test4 = 4);
		trace(a.get(11));
		
	}
	
}