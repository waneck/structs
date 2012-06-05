package haxe.structs.internal;
import haxe.structs.options.StructLayout;
import haxe.macro.MacroTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class StructExtensions
{
	@:macro public static function make(cls:ExprRequire<Class<Dynamic>>, args:Array<Expr>):Expr
	{
		return null;
	}
	
#if macro
	static function build():Array<Field>
	{
#if display
		var pos = Context.currentPos();
		
		var ret = [];
		var newArgs = [];
		for (field in Context.getBuildFields())
		{
			ret.push(field);
			newArgs.push({
				name:field.name,
				opt:true,
				type:null,
				value:null
			});
		}
		
		ret.push({
			name:"new",
			doc:null,
			access:[APublic],
			kind:FFun({
				args:newArgs,
				ret:null,
				expr:{
					expr:EBlock([]),
					pos:pos
				},
				params:[]
			}),
			pos:pos,
			meta:[]
		});
		
		return ret;
#else
		var fields = Context.getBuildFields();
		
		//check if struct extends another struct type
		var context:ClassType = Context.getLocalClass().get();
		var pos = Context.currentPos();
		
		var sc = context.superClass;
		var i = 0;
		while (sc != null)
		{
			i++;
			sc = sc.t.get().superClass;
		}
		
		if ( i > 1 )
			Context.error("A Struct cannot derive from another type other than AbstractStruct", Context.currentPos());
		
		var path = Context.getLocalClass().toString();
		var structLayout:StructLayout = Sequential;
		for (meta in context.meta.get())
		{
			switch(meta.name)
			{
				case "structLayout", ":structLayout":
					structLayout = switch(MacroTools.getString(meta.params[0], true))
					{
						case "Sequential": Sequential;
						case "Compact": Compact;
						case "Explicit": Explicit;
						default: Context.error("Invalid Struct Layout type", meta.pos);
					}
				default:
			}
		}
		
		//set it as final
		context.meta.add(":final", [], Context.currentPos());
		
		var structInfo = new StructInfo(path, structLayout);
		
		var newArgs = [];
		var newExpr = [];
		var disposeExpr = [];
		
		var newFields = [];
		
		for (field in fields)
		{
			var f = structInfo.addField(field);
			if (f != null)
			{
				newArgs.push({
					name:field.name,
					opt:true,
					type:null,
					value:null
				});
				
				newExpr.push({
					expr:EBinop(OpAssign, {
						expr:EField({
							expr:EConst(CIdent("this")),
							pos:field.pos
						}, field.name),
						pos:field.pos
					}, {
						expr:EConst(CIdent(field.name)),
						pos:field.pos
					}),
					pos:field.pos
				});
				
				switch(f.type)
				{
					case SFStruct(s):
						disposeExpr.push({
							expr:ECall(MacroTools.path([field.name, "dispose"], field.pos), []),
							pos:field.pos
						});
					default:
				}
			}
			
			newFields.push(field);
		}
		
		structInfo.close();
		
		newFields.push({
			name:"new",
			doc:null,
			access:[APublic],
			kind:FFun({
				args:newArgs,
				ret:null,
				expr:{
					expr:EBlock(newExpr),
					pos:pos
				},
				params:[]
			}),
			pos:pos,
			meta:[]
		});
		
		if (disposeExpr.length > 0)
			newFields.push({
				name:"dispose",
				doc:null,
				access:[APublic, AOverride],
				kind:FFun({
					args:[],
					ret:null,
					expr:{
						expr:EBlock(disposeExpr),
						pos:pos
					},
					params:[]
				}),
				pos:pos,
				meta:[]
			});
		
		//TODOs:
		//equals() and hashCode() implementation
		
		return newFields;
#end
	}
	
	static function buildOptimized():Array<Field>
	{
		return null;
	}
#end
}

#if macro
class StructInfo
{
	/**
	 * This is the most important data so we can achieve best performance on the cpu and also
	 * compatibility with native binaries (experimental)
	 */
	static #if (!(cpp && STRUCTS_DYNAMIC_ALIGNMENT)) inline #end var ALIGNMENT = #if (HXCPP_M64 || M64 || STRUCTS_M64) 8 #else 4 #end;
	/**
	 * The context for all StructInfos
	 */
	static var cache:Hash<StructInfo>;
	
	/**
	 * The full struct path
	 */
	public var path(default, null):String;
	/**
	 *  Native types are the common Int, Float, Byte, etc...
	 **/
	public var isNativeType(default, null):Bool;
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
	
	private var closed:Bool;
	
	private var layout:StructLayout;
	
	public var totalBytes(default, null):Int;
	
	public function new(path:String, structLayout:StructLayout)
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
		isNativeType = false;
		fields = [];
		totalBytes = 0;
		layout = structLayout;
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
		
		var isTypedef = false;
		var path = switch(t)
		{
			case TType(t, _):isTypedef = false; t.toString();
			case TInst(t, _):t.toString();
			case TEnum(t, _):t.toString();
			default: throw "assert";
		}
		
		return if (cache.exists(path))
		{
			cache.get(path);
		} else {
			var info = testBasicType(t);
			if (info != null) return info;
			if (isTypedef) return get(Context.follow(t, true));
			
			throw "Type " + path + " is not a Struct";
		}
	}
	
	private static function testBasicType(t:Type):Null<StructInfo>
	{
		var isTypedef = false;
		var path = switch(t)
		{
			case TType(t, _):isTypedef = true; t.toString();
			case TInst(t, _):t.toString();
			case TEnum(t, _):t.toString();
			default: throw "assert";
		};
		
		var stype = switch(path)
		{
			case "Int": SFInt;
			case "haxe.structs.options.Short": SFShort;
			case "haxe.Int64": SFInt64;
			case "haxe.Int32": SFInt32;
			case "haxe.structs.options.Byte": SFByte;
			case "Float", "haxe.structs.options.Double": SFDouble;
			case "haxe.structs.options.Single": SFSingle;
			default: null;
		}
		
		if (stype == null)
		{
			return if (isTypedef) testBasicType(Context.follow(t, true)); else null;
		}
		
		var info = new StructInfo(path, Sequential);
		info.isNativeType = true;
		info.fields.push({name:"this", type:stype, isStruct:false, byteOffset:0, defaultValue:null, pos:Context.makePosition({min:0, max:0, file:""}) });
		info.totalBytes = getFieldTypeBytes(stype);
		info.close();
		
		return info;
	}
	
	static function getType(type:ComplexType, pos:Position):Type
	{
		if (type == null)
			Context.error("All Structs declaration must define their types so they can work properly", pos);
		
		return switch(type)
		{
			case TFunction(_, _), TAnonymous(_), TParent(_), TExtend(_, _), TOptional(_): 
				Context.error("Only basic types and other Struct types can be used as Struct fields", pos);
			case TPath(tp):
				var path = if (tp.pack.length > 0) tp.pack.join(".") + "." + tp.name; else tp.name;
				return Context.typeof(Context.parse("{var _:" + path + "; _;}", pos));
		}
	}
	
	public function getField(name:String):Null<{name:String, type:StructFieldType, isStruct:Bool, byteOffset:Int, defaultValue:Expr, pos:Position }>
	{
		if (!closed)
			throw "getField only works when struct is already closed";
		
		for (field in fields)
		{
			if (field.name == name)
				return field;
		}
		
		return null;
	}
	
	public function iterator()
	{
		return fields.iterator();
	}
	
	public function close():Void
	{
		var shouldRunAlignment = true;
		switch(layout)
		{
			case Sequential:
				shouldRunAlignment = true;
			case Compact:
				var fs = [];
				for (field in fields)
				{
					fs.push({bytes:getFieldTypeBytes(field.type), field:field});
				}
				
				fs.sort(function(a,b) return a.bytes - b.bytes);
				
				for (i in 0...fs.length)
					fields[i] = fs[i].field;
				
				shouldRunAlignment = true;
			case Explicit:
				for (field in fields)
				{
					var tb = field.byteOffset + getFieldTypeBytes(field.type);
					if (this.totalBytes < tb)
						this.totalBytes = tb;
				}
				
				shouldRunAlignment = false;
		}
		
		if (shouldRunAlignment) applyAlignment();
		
		closed = true;
		var currentByteAlignment = this.totalBytes % ALIGNMENT;
		if (currentByteAlignment != 0)
			this.totalBytes += ALIGNMENT - currentByteAlignment;
	}
	
	private function applyAlignment():Void
	{
		//alignment rules taken from
		//http://en.wikipedia.org/wiki/Data_structure_alignment
		//and http://msdn.microsoft.com/en-us/library/ms253949(v=vs.80).aspx
		
		for (field in fields)
		{
			var fieldBytes = getFieldTypeBytes(field.type);
			var currentByteAlignment = this.totalBytes % fieldBytes;
			if (currentByteAlignment != 0)
			{
				this.totalBytes += (fieldBytes - currentByteAlignment);
			}
			
			field.byteOffset = this.totalBytes;
			this.totalBytes += fieldBytes;
		}
	}
	
	public function addField(field:Field):{name:String, type:StructFieldType, isStruct:Bool, byteOffset:Int, defaultValue:Expr, pos:Position } 
	{
		if (closed)
			throw "Cannot add field to closed struct";
		
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
		
		var fieldOffset = -1;
		var isExplicit = false;
		switch(layout)
		{
			case Explicit:
				isExplicit = true;
				
				for (meta in field.meta)
				{
					switch(meta.name)
					{
						case "fieldOffset", ":fieldOffset":
							fieldOffset = MacroTools.getInt(meta.params[0]);
					}
				}
			default:
		}
		
		return switch(field.kind)
		{
			case FVar(type, e):
				if (ignore) return null;
				var fieldType = getStructFieldType(getType(type, field.pos));
				var isStruct = switch(fieldType) { case SFStruct(_): true; default: false; };
				
				//Array<{name:String, type:StructFieldType, isStruct:Bool, byteOffset:Int, defaultValue:Expr }>;
				if (isExplicit)
				{
					if (fieldOffset < 0) Context.error("Please specify the field offset (Explicit layout)", field.pos);
					var fieldBytes = getFieldTypeBytes(fieldType);
					if (fieldOffset % fieldBytes != 0) Context.error("Unaligned explicit layout", field.pos);
				}
				
				var f = { name:field.name, type:fieldType, isStruct:isStruct, byteOffset: fieldOffset, defaultValue: e, pos:field.pos };
				this.fields.push( f );
				
				f;
			case FFun(f):
				if (field.name == "new")
					Context.error("Structs can't have constructors; They will be automatically generated", field.pos);
				
				if (ignore) return null;
				this.methods.set(field.name, f);
				
				null;
			case FProp(get, set, type, e):
				var f = null;
				if (!ignore)
				{
					f = addField({
						name:field.name,
						access:field.access,
						doc:field.doc,
						kind:FVar(type, e),
						pos:field.pos,
						meta:field.meta
					});
				}
				
				if (get != "default" && get != "null" && get != "never")
					propertiesGet.set(field.name, get);
				if (set != "default" && set != "null" && set != "never")
					propertiesSet.set(field.name, set);
				f;
		}
	}
	
	static function getFieldTypeBytes(sf:StructFieldType):Int
	{
		return switch(sf)
		{
			case SFInt64, SFDouble: 8;
			case SFInt, SFInt32, SFSingle: 4;
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
			case TType(t, _):isTypedef = true; t.toString();
			case TInst(t, _):t.toString();
			case TEnum(t, _):t.toString();
			default: throw "assert";
		};
		
		return switch(path)
		{
			case "Int": SFInt;
			case "haxe.structs.options.Short": SFShort;
			case "haxe.Int64": SFInt64;
			case "haxe.Int32": SFInt32;
			case "haxe.structs.options.Byte": SFByte;
			case "Float", "haxe.structs.options.Double": SFDouble;
			case "haxe.structs.options.Single": SFSingle;
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
	SFInt32;
	SFInt;
	SFShort;
	SFByte;
	SFDouble;
	SFSingle;
	SFStruct(struct:StructInfo);
}
#end