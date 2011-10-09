package haxe.macro;
import haxe.macro.Expr;

class PrettyPrint
{
	public static function make(e:Expr):String
	{
		var sb = new EnhancedStringBuf();
		_mk(e, sb);
		return sb.toString();
	}
	
	public static function makeWithComplexType(ct:ComplexType):String
	{
		var sb = new EnhancedStringBuf();
		ctToString(ct, sb);
		return sb.toString();
	}
	
	public static function makeWithField(f:Field):String
	{
		var sb = new EnhancedStringBuf();
		fieldToString(f, sb);
		return sb.toString();
	}
	
	public static function makeWithFunction(f:Function, name:String):String
	{
		var sb = new EnhancedStringBuf();
		functionToString(f, name, sb);
		return sb.toString();
	}
	
	private static function _mk(e:Expr, sb:EnhancedStringBuf):EnhancedStringBuf
	{
		return switch(e.expr)
		{
			case EConst( c ):
				switch(c)
				{
					case CIdent(s), CInt(s), CFloat(s), CType(s): sb.add(s);
					case CString(s): sb.add("\"").add(s).add("\"");
					case CRegexp(r, opt): sb.add("~/"); sb.add(r); sb.add("/"); sb.add(opt);
				}
			case EArray( e1, e2):
				_mk(e1, sb); sb.add("["); _mk(e2, sb); sb.add("]");
			case EBinop(op, e1, e2):
				_mk(e1, sb);
				function getOp(op):String
				{
					return switch(op)
					{
						case OpAdd: "+";
						case OpMult: "*";
						case OpDiv: "/";
						case OpSub: "-";
						case OpAssign: "=";
						case OpEq: "==";
						case OpNotEq: "!=";
						case OpGt: ">";
						case OpGte: ">=";
						case OpLt: "<";
						case OpLte: "<=";
						case OpAnd: "&";
						case OpOr: "|";
						case OpXor: "^";
						case OpBoolAnd: "&&";
						case OpBoolOr: "||";
						case OpShl: "<<";
						case OpShr: ">>";
						case OpUShr: ">>>";
						case OpMod: "%";
						case OpAssignOp( op ): getOp(op) + "=";
						case OpInterval: "...";
					}
				}
				
				sb.add(" "); sb.add(getOp(op)); sb.add(" "); _mk(e2, sb);
			case EField(e, field), EType(e, field):
				_mk(e, sb); sb.add("."); sb.add(field);
			case EParenthesis(e):
				sb.add("("); _mk(e, sb); sb.add(")");
			case EObjectDecl( fields):
				sb.add("{").indent().newline();
				var first = true;
				for (f in fields)
				{
					if (first) first = false else sb.add(", ").newline();
					sb.add(f.field).add(":");
					_mk(f.expr, sb);
				}
				sb.outdent().newline().add("}");
			case EArrayDecl( values ):
				sb.add("[");
				for (val in values)
					_mk(val, sb);
				sb.add("]");
			case ECall( e, params ):
				_mk(e, sb);
				sb.add("(");
				var first = true;
				for (param in params)
				{
					if (first) first = false; else sb.add(", ");
					_mk(param, sb);
				}
				sb.add(")");
			case ENew( t, params ):
				var pack = t.pack.copy();
				pack.push(t.name);
				sb.add("new ").add(pack.join(".")).add("(");
				var first = true;
				for (param in params)
				{
					if (first) first = false; else sb.add(", ");
					_mk(param, sb);
				}
				sb.add(")");
			case EUnop( op, postFix, e ):
				var op = switch(op)
				{
					case OpIncrement: "++";
					case OpDecrement: "--";
					case OpNot: "!";
					case OpNeg: "-";
					case OpNegBits: "~";
				};
				if (postFix)
				{
					_mk(e, sb);
					sb.add(op);
				} else {
					sb.add(op);
					_mk(e, sb);
				}
			case EVars( vars ):
				var first = true;
				for (v in vars)
				{
					if (first) first = false; else sb.add(", ");
					sb.add(v.name).addIf(":", v.type != null);
					if (v.type != null)
						ctToString(v.type, sb);
					sb.addIf(" = ", v.expr != null);
					if (v.expr != null) _mk(v.expr, sb);
				}
				sb;
			case EFunction(name, f):
				functionToString(f, name, sb);
			case EBlock(el):
				sb.add("{").indent().newline();
				for (e in el)
					_mk(e, sb).add(";").newline();
				sb.outdent().newline().add("}");
			case EFor(it, expr):
				sb.add("for (");
				_mk(it, sb).add(")");
				_mk(expr, sb);
			case EIn(e1, e2):
				_mk(e1, sb).add(" in ");
				_mk(e2, sb);
			case EIf(econd, eif, eelse), ETernary(econd, eif, eelse):
				sb.add("if (");
				_mk(econd, sb);
				sb.add(") ");
				_mk(eif, sb);
				if (eelse != null)
				{
					sb.add(" else ");
					_mk(eelse, sb);
				}
				sb;
			case EWhile(econd, e, normalWhile):
				if (normalWhile)
				{
					sb.add("while (");
					_mk(econd, sb);
					sb.add(") ");
					_mk(e, sb);
				} else {
					sb.add("do ");
					_mk(e, sb);
					sb.add("while (");
					_mk(econd, sb);
					sb.add(") ");
				}
			case ESwitch(e, cases, edef):
				sb.add("switch(");
				_mk(e, sb);
				sb.add(") {").indent().newline();
				for (c in cases)
				{
					sb.add("case ").exprJoin(c.values, ", ").add(":").indent().newline();
					_mk(c.expr, sb);
					sb.outdent().newline();
				}
				if (edef != null)
				{
					sb.add("default:").indent().newline();
					_mk(edef, sb);
					sb.outdent().newline();
				}
				sb.outdent().newline().add("}").newline();
			case ETry(e, catches):
				sb.add("try ");
				_mk(e, sb);
				for (c in catches)
				{
					sb.add("catch (").add(c.name).add(":");
					ctToString(c.type, sb).add(" ");
					_mk(c.expr, sb);
				}
				sb;
			case EReturn(e):
				sb.add("return ");
				if (e != null)
				{
					_mk(e, sb);
				}
				sb;
			case EBreak: sb.add("break");
			case EContinue: sb.add("continue");
			case EUntyped(e): sb.add("untyped "); _mk(e, sb);
			case EThrow(e):sb.add("throw "); _mk(e, sb);
			case ECast(e, t):
				if (t == null)
				{
					sb.add("cast ");
					_mk(e, sb);
				} else {
					sb.add("cast(");
					_mk(e, sb);
					ctToString(t, sb);
					sb.add(")");
				}
			case EDisplay(e, isCall):
				sb.add("EDisplay(").add(isCall).add(", ");
				_mk(e, sb);
			case EDisplayNew(t):
				var pack = t.pack.copy();
				pack.push(t.name);
				sb.add("EDisplayNew(").add(pack.join(".")).add(")");
		}
	}
	
	private static function ctToString(ct:ComplexType, buf:EnhancedStringBuf):EnhancedStringBuf
	{
		return switch(ct)
		{
			case TPath(p):
				var pack = p.pack.copy();
				pack.push(p.name);
				buf.add(pack.join("."));
			case TFunction(args, ret):
				for (arg in args)
				{
					buf.add(ctToString(arg, buf));
					buf.add("->");
				}
				buf.add(ctToString(ret, buf));
			case TAnonymous(fields):
				buf.add("{").indent().newline();
				for (field in fields)
				{
					fieldToString(field, buf);
				}
				buf.outdent().newline().add("}").newline();
			case TParent(t):
				buf.add("{ >");
				ctToString(t, buf);
				buf.add(" }");
			case TExtend(tp, fields):
				buf.add("{ >");
				var pack = tp.pack.copy();
				pack.push(tp.name);
				buf.add(pack.join(".")).indent().newline();
				for (field in fields)
					fieldToString(field, buf);
				buf.outdent().newline().add("}").newline();
		}
	}
	
	private static function fieldToString(field:Field, buf:EnhancedStringBuf):EnhancedStringBuf
	{
		var isPublic = false;
		for (acc in field.access)
		{
			if (acc == APublic) isPublic = true;
		}
		return switch(field.kind)
		{
			case FVar(t, e): 
				buf.addIf("public ", isPublic).add("var ").add(field.name).addIf(":", t != null);
				if (t != null) ctToString(t, buf);
				if (e != null)
				{
					buf.add(" = ");
					_mk(e, buf);
				}
				buf.add(";").newline();
			case FFun(fun):
				buf.addIf("public ", isPublic);
				functionToString(fun, field.name, buf).newline();
			case FProp(get, set, t, e):
				buf.addIf("public ", isPublic).add("function ").add(field.name).add("(").add(get).add(", ").add(set).addIf(":", t != null);
				if (t != null) ctToString(t, buf);
				if (e != null)
				{
					buf.add(" = ");
					_mk(e, buf);
				}
				buf.add(";").newline();
		}
	}
	
	private static function functionToString(fun:Function, name:String, buf:EnhancedStringBuf):EnhancedStringBuf
	{
		buf.add("function ").add(name);
		buf.addIf("<", fun.params.length != 0).join(fun.params, ", ", "name").addIf(">", fun.params.length != 0);
		buf.add("(");
		var first = true;
		for (arg in fun.args)
		{
			if (first) first = false; else buf.add(", ");
			buf.addIf("?", arg.opt).add(arg.name).addIf(":", arg.type != null);
			if (arg.type != null) ctToString(arg.type, buf);
			buf.addIf(" = ", arg.value != null);
			if (arg.value != null) _mk(arg.value, buf);
		}
		buf.add(")").addIf(":", fun.ret != null);
		if (fun.ret != null) ctToString(fun.ret, buf);
		buf.add(" ");
		if (fun.expr != null)
			_mk(fun.expr, buf);
		return buf;
	}
}

class EnhancedStringBuf
{
	private var sb:StringBuf;
	private var tabs:Int;
	
	public function new():Void
	{
		sb = new StringBuf();
		tabs = 0;
	}
	
	public function add(d:Dynamic):EnhancedStringBuf
	{
		sb.add(d);
		return this;
	}
	
	public function join(arr:Array<Dynamic>, chr:String, accessor:String):EnhancedStringBuf
	{
		var first = true;
		for (a in arr)
		{
			if (first) first = false; else add(chr);
			add(Reflect.field(a, accessor));
		}
		return this;
	}
	
	public function exprJoin(arr:Array<Expr>, chr:String):EnhancedStringBuf
	{
		var first = true;
		for (a in arr)
		{
			if (first) first = false; else add(chr);
			untyped PrettyPrint._mk(a, this);
		}
		return this;
	}
	
	
	
	public function addIf(d:Dynamic, _if:Bool):EnhancedStringBuf
	{
		if (_if) add(d);
		return this;
	}
	
	
	public function indent():EnhancedStringBuf
	{
		tabs++;
		return this;
	}
	
	public function outdent():EnhancedStringBuf
	{
		tabs--;
		return this;
	}
	
	public function newline():EnhancedStringBuf
	{
		add("\n");
		for (_ in 0...tabs)
			add("\t");
		return this;
	}
	
	public function toString():String
	{
		return sb.toString();
	}
}