package haxe.structs;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class StructExtensions
{
#if macro
	static function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		
		//check if struct extends another struct type
		var context:ClassType = Context.getLocalClass().get();
		
		var sc = context.superClass;
		var i = 0;
		while (sc != null)
		{
			i++;
			sc = sc.t.get().superClass;
		}
		
		if ( i > 1 )
			Context.error("A Struct cannot derive from another type other than AbstractStruct", Context.currentPos());
		
		//set it as final
		context.meta.add(":final", [], Context.currentPos());
		
		var path = Context.getLocalClass().toString();
		
		var structInfo = new StructInfo(path);
		
		for (field in fields)
		{
			structInfo.addField(field);
		}
		
		//TODOs:
		//add new() method
		//override dispose() method to replicate dispose on other structs -> only the ones that contain Structs<> reference
		//check on each function for unreferenced this calls -> everything must be used as this.
		
		return null;
	}
	
	static function buildOptimized():Array<Field>
	{
		return null;
	}
#end
}

#if macro
private class StructInfo
{
	/**
	 * This is the most important data so we can achieve best performance on the cpu and also
	 * compatibility with native binaries (experimental)
	 */
	static inline var ALIGNMENT = #if (HXCPP_M64 || M64 || STRUCTS_M64) 8 #else 4 #end;
	/**
	 * The context for all StructInfos
	 */
	static var cache:Hash<StructInfo>;
	
	/**
	 * The full struct path
	 */
	public var path(default, null):String;
	/**
	 * All struct methods; Having them as a Function object will
	 * allow us to inline those functions on other macros
	 */
	private var methods:Hash<Function>;
	/**
	 * All variable fields in the struct. They contain the offset of each field, the field position, and a possible default value.
	 */
	private var fields:Array<{name:String, type:StructFieldType, isStruct:Bool, byteOffset:Int, defaultValue:Expr, pos:Position }>;
	/**
	 * Getter functions - so we can emulate normal haxe behaviour
	 */
	private var propertiesGet:Hash<String>;
	/**
	 * Setter functions - so we can emulate normal haxe behaviour
	 */
	private var propertiesSet:Hash<String>;
	
	private var totalBytes:Int;
	
	public function new(path:String)
	{
		if (cache == null)
			cache = new Hash();
		this.path = path;
		
		if (cache.exists(path))
			throw "assert";
		
		cache.set(path, this);
		methods = new Hash();
		propertiesGet = new Hash();
		propertiesSet = new Hash();
		fields = [];
		totalBytes = 0;
	}
	
	/**
	 * Gets the struct info from the cache
	 * @param	t	macro Type for the struct
	 * @return
	 */
	public static function get(t:Type):StructInfo
	{
		if (cache == null)
			cache = new Hash();
		
		var path = switch(t)
		{
			case TType(t, _):t.toString();
			case TInst(t, _):t.toString();
			case TEnum(t, _):t.toString();
			default: throw "assert";
		}
		
		return if (cache.exists(path))
		{
			cache.get(path);
		} else {
			throw "Type " + path + " is not a Struct";
		}
	}
	
	static function getType(type:ComplexType, pos:Position):Type
	{
		if (type == null)
			Context.error("All Structs declaration must define their types so they can work properly", pos);
		
		return switch(type)
		{
			case TFunction(_, _), TAnonymous(_), TParent(_), TExtend(_, _): 
				Context.error("Only basic types and other Struct types can be used as Struct fields", pos);
			case TPath(tp):
				var path = if (tp.pack.length > 0) tp.pack.join(".") + "." + tp.name; else tp.name;
				return Context.typeof(Context.parse("{var _:" + path + "; _;}", pos));
		}
	}
	
	public function addField(field:Field):Void 
	{
		var ignore = false;
		for (meta in field.meta)
		{
			switch(meta.name)
			{
				case "ignore", ":ignore":
					ignore = true;
				default:
			}
		}
		
		trace(field.name);
		switch(field.kind)
		{
			case FVar(type, e):
				if (ignore) return;
				var fieldType = getStructFieldType(getType(type, field.pos));
				var isStruct = switch(fieldType) { case SFStruct(_): true; default: false; };
				//Array<{name:String, type:StructFieldType, isStruct:Bool, byteOffset:Int, defaultValue:Expr }>;
				var currentByteAlignment = this.totalBytes % ALIGNMENT;
				var fieldBytes = getFieldTypeBytes(fieldType);
				if (currentByteAlignment != 0)
				{
					if (currentByteAlignment + fieldBytes > ALIGNMENT)
					{
						this.totalBytes += (ALIGNMENT - currentByteAlignment);
					}
				}
				
				var currentByteOffset = this.totalBytes;
				this.totalBytes += fieldBytes;
				
				this.fields.push( { name:field.name, type:fieldType, isStruct:isStruct, byteOffset: currentByteOffset, defaultValue: e, pos:field.pos } );
				
			case FFun(f):
				if (field.name == "new")
					Context.error("Structs can't have constructors; They will be automatically generated", field.pos);
				
				if (ignore) return;
				this.methods.set(field.name, f);
			
			case FProp(get, set, type):
				if (!ignore)
				{
					field.kind = FVar(type, null);
					addField(field);
				}
				
				if (get != "default" && get != "null" && get != "never")
					propertiesGet.set(field.name, get);
				if (set != "default" && set != "null" && set != "never")
					propertiesSet.set(field.name, set);
		}
	}
	
	static function getFieldTypeBytes(sf:StructFieldType):Int
	{
		return switch(sf)
		{
			case SFInt64, SFDouble: 8;
			case SFInt, SFSingle: 4;
			case SFShort: 2;
			case SFByte: 1;
			case SFStruct(s): s.totalBytes;
		}
	}
	
	private function getStructFieldType(t:Type):StructFieldType
	{
		var isTypedef = false;
		var path = switch(t)
		{
			case TType(t, _):t.toString();
			case TInst(t, _):t.toString();
			case TEnum(t, _):isTypedef = true;  t.toString();
			default: throw "assert";
		};
		
		return switch(path)
		{
			case "Int": SFInt;
			case "haxe.structs.Short": SFShort;
			case "haxe.Int64": SFInt64;
			case "haxe.structs.Byte": SFByte;
			case "Float", "haxe.structs.Double": SFDouble;
			case "haxe.structs.Single": SFSingle;
			default: if (isTypedef)
				getStructFieldType(Context.follow(t, true));
			else
			{
				SFStruct(checkCircular(get(t)));
			}
		}
	}
	
	private function checkCircular(sinfo:StructInfo):StructInfo 
	{
		for (field in sinfo.fields)
		{
			switch(field.type)
			{
				case SFStruct(s):
					if (s.path == this.path)
						Context.error("Circular reference detected between " + sinfo.path + "." + field.name + " and " + this.path, field.pos);
					else
						checkCircular(s);
				default:
			}
		}
		
		return sinfo;
	}
}

enum StructFieldType
{
	SFInt64;
	SFInt;
	SFShort;
	SFByte;
	SFDouble;
	SFSingle;
	SFStruct(struct:StructInfo);
}
#end