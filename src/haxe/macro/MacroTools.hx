package haxe.macro;
import haxe.macro.Expr;

/**
 * A set of common tools for manipulating macro data
 * @author waneck
 */

class MacroTools 
{

	public static function getString(e:Expr, ?acceptIdent = false):String
	{
		return switch(e.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CString(s): s;
					case CIdent(s), CType(s): if (acceptIdent) s; else throw UnexpectedType(["CString"], e.expr, e.pos);
					default: throw UnexpectedType((acceptIdent) ? ["CString", "CIdent", "CType"] : ["CString"], e.expr, e.pos);
				}
			default: throw UnexpectedType((acceptIdent) ? ["CString", "CIdent", "CType"] : ["CString"], e.expr, e.pos);
		}
	}
	
	public static function getInt(e:Expr):Int
	{
		return switch(e.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CInt(s): Std.parseInt(s);
					default: throw UnexpectedType(["CInt"], e.expr, e.pos);
				}
			default: throw UnexpectedType(["CInt"], e.expr, e.pos);
		}
	}
	
	public static function getPath(e:Expr, ?a:Array<String>):Array<String>
	{
		if (null == a)
		{
			a = [];
		}
		
		return switch(e.expr)
		{
			case EConst(c):
				switch(c)
				{
					case CIdent(s), CType(s): a.push(s); a;
					default: throw UnexpectedType(["EConst(CIdent, CType)", "EField", "EType"], e.expr, e.pos);
				}
			case EType(e, f), EField(e, f):
				getPath(e, a);
				a.push(f);
				a;
			default: throw UnexpectedType(["EConst(CIdent, CType)", "EField", "EType"], e.expr, e.pos);
		}
	}
	
	public static function mkCall(_path:Array<String>, arguments:Array<Expr>, pos:Position):Expr
	{
		return {expr:ECall(path(_path, pos), arguments), pos:pos};
	}
	
	
	public static function separatePackage(a:Array<String>) : { pack:Array<String>, type:String, fields:Array<String> }
	{
		var pack = [];
		var i = 0;
		var len = a.length;
		while(i < len)
		{
			var val = a[i];
			var fst = val.charCodeAt(0);
			if (fst >= 'A'.code && fst <= 'Z'.code) //is upper case
				break;
			
			pack.push(val);
			i++;
		}
		
		var type = a[i++];
		var fields = [];
		for (j in i...len)
			fields.push(a[j]);
		
		return { pack:pack, type:type, fields:fields };
	}
	
	public static function mk(e:ExprDef, p:Position):Expr
	{
		return { expr:e, pos:p };
	}
	
	public static function mkc(e:ExprDef, expr:Expr):Expr
	{
		return { expr:e, pos:expr.pos };
	}
	
	public static function path(p:Array<String>, pos) : Expr
	{
		function isUpperFirst(string:String) : Bool
		{
			var fst = string.charCodeAt(0);
			return fst >= 'A'.code && fst <= 'Z'.code;
		}
		
		
		var len = p.length;
		switch(len)
		{
			case 0: throw "Inexistent path";
			case 1: 
				var field = p.pop();
				return (isUpperFirst(field)) ? mk(EConst(CType(field)), pos) : mk(EConst(CIdent(field)), pos);
			default:
				var field = p.pop();
				return (isUpperFirst(field)) ? mk(EType( path(p, pos), field), pos) : mk(EField(path(p,pos), field), pos);
		}
			
	}
	
}

enum MacroExprError
{
	UnexpectedType(expected:Array<String>, got:ExprDef, pos:Position);
}