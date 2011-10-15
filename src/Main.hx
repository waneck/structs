package ;
import haxe.structs.options.Types;
import haxe.structs.Structs;
using haxe.structs.Structs;

/**
 * ...
 * @author waneck
 */

class Main 
{
	static var a:Structs<Matrix>;
	
	public static function main() 
	{
		#if flash9
		var ba = new flash.utils.ByteArray();
		ba.length = 1024;
		flash.Memory.select(ba);
		#end
		
		a = Matrix.structs(11);
		
		a.set(10, this.test = 1, test3 = 3, test4 = 4);
		
		trace(a.get(10, test3));
		//var m = new Matrix();
		//m.test;
		trace(a.get(10));
		
		a.set(9, new Matrix(10,20,30,40));
		trace(a.get(9));
		trace(a.get(10, this.test));
		
		a.set(10, this.test = 1);
		a.set(10, this.test2 = 4);
		a.get(10, this.test2);
		
		var f = Single.structs(10);
		
		f.set(0, this = 0.1);
		f.set(1, 0.2);
		f.set(2, 0.3);
		f.foreach(val, trace(val));
		
		trace(f.get(0));
		trace(f.get(1));
		trace(f.get(2));
		
		a.foreach(myVar, 
		{
			trace(myVar);
		});
		
		trace(a.get(5, this.test3));
		//a.get(5, this.)
		
		//a.set(11, this.test = 1, test2 = 2, test3 = 3, test4 = 4);
		//trace(a.get(11));
		
	}
	
}