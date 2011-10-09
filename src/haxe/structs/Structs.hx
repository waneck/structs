package haxe.structs;
import haxe.macro.PrettyPrint;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.structs.StructExtensions;
import haxe.macro.MacroTools;
#end

/**
 * ...
 * @author waneck
 */

typedef Structs<T> = //where T is AbstractStruct
	#if flash9 Int
	#elseif js js.webgl.TypedArray.DataView
	#elseif (neko || cpp) haxe.io.BytesData
	#elseif php php.SplFixedArray
	//java http://www.javamex.com/tutorials/io/nio_buffers.shtml
	//c# Array of structs really
	#else Array<Dynamic>
#end;

//typedef FixedStructs<T, Const> = Structs<T>;

class StructsExtensions
{
	
	@:macro public static function tr(expr:Expr):Expr
	{
		trace(PrettyPrint.make(expr));
		
		return {expr:EConst(CIdent("null")), pos:expr.pos};
	}
	
	
	@:macro public static function get(me:ExprRequire<Structs<Dynamic>>, index:Expr, ?fieldExpr:Expr):Expr
	{
		switch(fieldExpr.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CIdent(n): if (n == "null") fieldExpr = null;
					default:
				}
			default:
		}
		return _get(me, index, fieldExpr);
	}
	
	@:macro public static function set(fieldsOrNewStruct:Array<ExprRequire<Structs<Dynamic>>>):Expr
	{
		var me = fieldsOrNewStruct.shift();
		var index = fieldsOrNewStruct.shift();
		return _set(me, index, fieldsOrNewStruct);
	}
	
#if macro
	private static function _set(me:Expr, index:Expr, fieldsOrNewStruct:Array<Expr>):Expr
	{
		var type = Context.typeof(me);
		var pos = Context.currentPos();
		
		//get the underlying struct type (Structs<MyType>, get MyType)
		
		var struct = StructInfo.get(getStructType(type, me.pos));
		var bytesOffset = {
			expr:EBinop(OpMult, index, {
				expr:EConst(CInt(struct.totalBytes + "")),
				pos:index.pos
			}),
			pos:index.pos
		};
		
		if (fieldsOrNewStruct.length < 1) Context.error("Too few arguments", pos);
		
		function separateOpAssign(expr:Expr, throwErrors:Bool):{leftSide:Array<String>, rightSide:Expr, assignOp:Null<Binop>}
		{
			return switch(expr.expr)
			{
				case EParenthesis(p): separateOpAssign(p, throwErrors);
				case EBinop(op, e1, e2):
					var assignOp = null;
					switch(op)
					{
						case OpAssignOp(op):
							assignOp = op;
						case OpAssign:
						default: 
							if (throwErrors) Context.error("Invalid expression. An assign operation was expected", expr.pos);
							else return null;
					}
					
					var leftSide = MacroTools.getPath(e1);
					{leftSide:leftSide, rightSide:e2, assignOp:assignOp};
				default:
					if (throwErrors) Context.error("Invalid expression. An assign operation was expected", expr.pos);
					else null;
			}
		}
		
		var assign = separateOpAssign(fieldsOrNewStruct[0], false);
		if (assign == null)
		{
			if (fieldsOrNewStruct.length > 1)
				separateOpAssign(fieldsOrNewStruct[0], true); //throw error
			var e = setFieldExpr(me, bytesOffset, {type:SFStruct(struct), byteOffset:0}, fieldsOrNewStruct[0], null, pos);
			trace(PrettyPrint.make(e));
			return e;
		}
		
		var block = [];
		for (assignField in fieldsOrNewStruct)
		{
			var struct = struct;
			var assign = separateOpAssign(assignField, true);
			
			var fieldOffset = 0;
			var lastF = null;
			for (field in assign.leftSide)
			{
				if (lastF != null)
				{
					switch(lastF.type)
					{
						case SFStruct(s):
							struct = s;
						default:
							Context.error("Field " + lastF.name + " does not contain fields", assign.rightSide.pos);
					}
					fieldOffset += lastF.byteOffset;
				}

				lastF = struct.getField(field);
				if (lastF == null)
				{
					Context.error("Type " + struct.path + " does not contain field " + field, assign.rightSide.pos);
				}
			}

			if (fieldOffset != 0)
				bytesOffset = {
					expr:EBinop(OpAdd, bytesOffset, {
						expr: EConst(CInt(fieldOffset + "")),
						pos:pos
					}),
					pos:pos
				};

			var e = setFieldExpr(me, bytesOffset, cast lastF, assign.rightSide, assign.assignOp, pos);
			block.push(e);
		}
		
		var e = {expr:EBlock(block), pos:pos};
		trace(PrettyPrint.make(e));
		return e;
	}
	
	/*TODO
	private static function binopToCall(op:Binop, e1:Expr, e2:Expr):String
	{
		var func = switch(op)
		{
			case OpAdd: "add";
			case OpSub: "sub";
			case OpMult: "mul";
			case OpDiv: "div";
			case OpMod: "mod";
			case OpShr: "shr";
			case OpShl: "shl";
			case OpUShr: "ushr";
			case OpAnd: "and";
			case OpOr: "or";
			case OpXor: "xor";
			//case OpNeg: "neg";
			//case OpNegBits: "complement";
		}
	}*/
	
	private static function platformSetExpr(me:Expr, bytesOffset:Expr, field:{type:StructFieldType, byteOffset:Int}, setExpr:Expr, pos:Position):Expr
	{
		var func = switch(field.type)
		{
			case SFInt: "setInt32";
			case SFShort: "setInt16";
			case SFByte: "setInt8";
			case SFDouble: "setDouble";
			case SFSingle: "setFloat";
			case SFInt32: "setInt32h";
			case SFInt64: "setInt64";
			default: throw "assert";
		};

		return MacroTools.mkCall(["haxe", "structs", "internal", "StructsInternal", func], [me, {expr:EBinop(OpAdd, bytesOffset, {expr:EConst(CInt(field.byteOffset + "")), pos:pos}), pos:pos}, setExpr], pos);
	}
	
	private static function setFieldExpr(me:Expr, bytesOffset:Expr, field:{type:StructFieldType, byteOffset:Int}, setExpr:Expr, assignOp:Null<Binop>, pos:Position):Expr
	{
		return switch(field.type)
		{
			case SFInt, SFShort, SFByte, SFDouble, SFSingle, SFInt32, SFInt64:
				if (assignOp != null)
				{
					setExpr = 
					{
						expr:EBinop(assignOp, getFieldExpr(me, bytesOffset, field, pos), setExpr),
						pos:pos
					};
				}
				
				platformSetExpr(me, bytesOffset, field, setExpr, pos);
			case SFStruct(info):
				var offset = bytesOffset;
				var exprs = [];
				if (field.byteOffset != 0)
				{
					exprs.push({
						expr:EVars([{ name:"__offset__", type:null, expr:{
							expr:EBinop(OpAdd, bytesOffset, {
								expr:EConst(CInt(field.byteOffset + "")),
								pos:pos
							}),
							pos: pos
						} }]), 
						pos:pos
					});
					offset = {expr:EConst(CIdent("__offset__")), pos:pos};
				}
				
				switch(setExpr.expr)
				{
					case ENew(path, params):
						if (path.name != info.path.substr(info.path.lastIndexOf(".")))
							Context.error("Expecting type " + info.path + " but got " + path.name, setExpr.pos);
						
						var fields = Lambda.array(info);
						for (i in 0...params.length)
						{
							var param = params[i];
							var field = fields[i];
							
							exprs.push(setFieldExpr(me, offset, field, param, null, param.pos));
						}
					default:
						exprs.push({
							expr:EVars([{ name:"__setval__", type:null, expr:setExpr }]), 
							pos:pos
						});
						setExpr = {expr:EConst(CIdent("__setval__")), pos:pos};
						
						for (field in info)
						{
							var setExpr = {expr:EField(setExpr, field.name), pos:setExpr.pos};
							exprs.push(setFieldExpr(me, offset, field, setExpr, null, setExpr.pos));
						}
				}
				
				if (exprs.length == 1)
					exprs[0];
				else
					{
						expr:EBlock(exprs),
						pos:pos
					};
		}
	}

	static function getStructType(type:Type, pos:Position):Type
	{
		return switch(type)
		{
			case TType(tref, params):
				switch(tref.toString())
				{
					case "haxe.structs.Structs":
						if (params.length != 1)
							Context.error("Incorrect number of arguments for Structs<Structs.T>", pos);
						params[0];
					default:
						getStructType(Context.follow(type, true), pos);
				}
			default: Context.error("Incorrect argument type. Expected haxe.structs.Structs<Structs.T>, but got " + Std.string(type), pos);
		}
	}
	
	static function _get(me:Expr, index:Expr, fieldExpr:Null<Expr>):Expr
	{
		var type = Context.typeof(me);
		var pos = Context.currentPos();
		
		//get the underlying struct type (Structs<MyType>, get MyType)
		
		var struct = StructInfo.get(getStructType(type, me.pos));
		var bytesOffset = {
			expr:EBinop(OpMult, index, {
				expr:EConst(CInt(struct.totalBytes + "")),
				pos:index.pos
			}),
			pos:index.pos
		};
		
		var realField = null;
		if (fieldExpr != null)
		{
			realField = haxe.macro.MacroTools.getPath(fieldExpr);
		} else {
			var e = getFieldExpr(me, bytesOffset, {type:SFStruct(struct), byteOffset:0}, pos);
			trace(PrettyPrint.make(e));
			return e;
		}
		
		if (realField[0] == "this") realField.splice(0, 1);
		
		var fieldOffset = 0;
		var lastF = null;
		for (field in realField)
		{
			if (lastF != null)
			{
				switch(lastF.type)
				{
					case SFStruct(s):
						struct = s;
					default:
						Context.error("Field " + lastF.name + " does not contain fields", fieldExpr.pos);
				}
				fieldOffset += lastF.byteOffset;
			}
			
			lastF = struct.getField(field);
			if (lastF == null)
			{
				Context.error("Type " + struct.path + " does not contain field " + field, fieldExpr.pos);
			}
		}
		
		if (fieldOffset != 0)
			bytesOffset = {
				expr:EBinop(OpAdd, bytesOffset, {
					expr: EConst(CInt(fieldOffset + "")),
					pos:pos
				}),
				pos:pos
			};
		
		var e = getFieldExpr(me, bytesOffset, cast lastF, pos);
		trace(PrettyPrint.make(e));
		return e;
	}
	
	private static function platformGetExpr(me:Expr, bytesOffset:Expr, field:{type:StructFieldType, byteOffset:Int}, pos:Position):Expr
	{
		return switch(field.type)
		{
			case SFInt64:
				var getI32_1 = platformGetExpr(me, bytesOffset, {type:SFInt32, byteOffset:field.byteOffset}, pos);
				var getI32_2 = platformGetExpr(me, bytesOffset, {type:SFInt32, byteOffset:field.byteOffset + 4}, pos);
				MacroTools.mkCall(["haxe", "Int64", "make"], [getI32_1, getI32_2], pos);
			case SFInt32:
				if (Context.defined("neko")) //special case for 31 bits ints
				{
					var getI16_1 = platformGetExpr(me, bytesOffset, {type:SFShort, byteOffset:field.byteOffset}, pos);
					var getI16_2 = platformGetExpr(me, bytesOffset, {type:SFShort, byteOffset:field.byteOffset + 2}, pos);
					MacroTools.mkCall(["haxe", "Int32", "make"], [getI16_1, getI16_2], pos);
				} else {
					var getI32 = platformGetExpr(me, bytesOffset, {type:SFInt, byteOffset:field.byteOffset}, pos);
					MacroTools.mkCall(["haxe", "Int32", "ofInt"], [getI32], pos);
				}
			case SFInt, SFShort, SFByte, SFDouble, SFSingle:
				var func = switch(field.type)
				{
					case SFInt: "getInt32";
					case SFShort: "getInt16";
					case SFByte: "getInt8";
					case SFDouble: "getDouble";
					case SFSingle: "getFloat";
					default: null;
				};
				
				MacroTools.mkCall(["haxe", "structs", "internal", "StructsInternal", func], [me, {expr:EBinop(OpAdd, bytesOffset, {expr:EConst(CInt(field.byteOffset + "")), pos:pos}), pos:pos}], pos);
			case SFStruct(_): throw "assert"; //this case is already ruled out by getFieldExpr
		}
	}
	
	private static function getFieldExpr(me:Expr, bytesOffset:Expr, field:{type:StructFieldType, byteOffset:Int}, pos:Position):Expr
	{
		return switch(field.type)
		{
			case SFInt, SFShort, SFByte, SFDouble, SFSingle, SFInt32, SFInt64:
				platformGetExpr(me, bytesOffset, field, pos);
			case SFStruct(info):
				//var __offset__ = me + bytesOffset;
				var offset = bytesOffset;
				var exprs = [];
				if (field.byteOffset != 0)
				{
					exprs.push({
						expr:EVars([{ name:"__offset__", type:null, expr:{
							expr:EBinop(OpAdd, bytesOffset, {
								expr:EConst(CInt(field.byteOffset + "")),
								pos:pos
							}),
							pos: pos
						} }]), 
						pos:pos
					});
					offset = {expr:EConst(CIdent("__offset__")), pos:pos};
				}
				
				var newArgs = [];
				for (field in info)
				{
					newArgs.push(getFieldExpr(me, offset, field, pos));
				}
				
				var pack = info.path.split(".");
				var name = pack.pop();
				exprs.push({
					expr:ENew({ pack:pack, name:name, params:[], sub:null }, newArgs),
					pos:pos
				});
				
				if (exprs.length == 1)
					exprs[0];
				else
					{
						expr:EBlock(exprs),
						pos:pos
					};
		}
	}
	
#end
	
	@:macro public static function optimize(me:Expr):Expr
	{
		//here we will run a deep analysis on the block 'me';
		//as a first need, all unresolved CIdent will be considered as this.
		//we will then inline all methods that are from structs
		//then, we will detect the make() and makeFrom() patterns, and all structs will be unrolled to temp variables
		//we will then treat field access as var access, and also perform one pass of escape analysis
		//this will deterine all structs that need to be remade, and also will determine the vars that can be reused.
		//This will prevent the creation of lots of temp struct variables, and also will allow for any haxe target to benefit
		//from having stack allocated instances
		return null;
	}
}