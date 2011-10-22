package haxe.structs;
import haxe.structs.options.Types;

/**
 * ...
 * @author waneck
 */

#if !macro @:autoBuild(haxe.structs.internal.StructExtensions.build()) #end
class AbstractStruct 
{
	
	public function dispose():Void 
	{
		
	}
	
	function toString():String
	{
		var sbuf = new StringBuf();
		var cls = Type.getClass(this);
		sbuf.add("{ [" + Type.getClassName(cls) +"] ");
		var first= true;
		for (f in Type.getInstanceFields(cls))
		{
			var fld = Reflect.field(this, f);
			if (Reflect.isFunction(fld))
				continue;
			if (first) first = false; else sbuf.add(", ");
			sbuf.add(f);
			sbuf.add(" => ");
			sbuf.add(fld);
		}
		sbuf.add(" }");
		return sbuf.toString();
	}
	
	
}

//just convenience so we don't need to import Types explicitly

//unsigned short
typedef Short = haxe.structs.options.Short;
//unsigned byte
typedef Byte = haxe.structs.options.Byte;
typedef Single = haxe.structs.options.Single;
typedef Double = haxe.structs.options.Double;
typedef PackedBool = haxe.structs.options.PackedBool;
typedef Int32 = haxe.structs.options.Int32;
typedef Int64 = haxe.structs.options.Int64