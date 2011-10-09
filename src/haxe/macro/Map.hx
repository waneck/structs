//
//  Map
//
//  Created by Caue W. on 2011-03-19.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
package haxe.macro;
import haxe.macro.Expr;

using Lambda;

class Map 
{
	#if macro
	var pos:Position;
	var current:Expr;
	var currentMappedBlock:Array<Expr>;
	var currentBlock:Expr;
	var inValue:Bool;
	var cumulativeInValue:Bool;
	
	public static function mapExpr<A>(fn:Expr->Expr, e:Null<Expr>) : Null<Expr>
	{
		if (e == null)
			return null;
		
		function _map(e:Null<Expr>) : Null<Expr>
		{
			return if (e == null)
				null;
			else
				fn(e);
		}
		
		function mk(e2:ExprDef)
		{
			return { expr:e2, pos:e.pos };
		}
		
		return switch(e.expr)
		{
			case EConst(c):
				e;
			case EArray(e1, e2):
				mk(EArray(_map(e1), _map(e2)));
			case EBinop(op, e1, e2):
				mk(EBinop(op, _map(e1), _map(e2)));
			case EField(e, field):
				mk(EField(_map(e), field));
			case EType(e, field):
				mk(EType(_map(e), field));
			case EParenthesis(e):
				mk(EParenthesis(_map(e)));
			case EObjectDecl(fields):
				mk(EObjectDecl(fields.map(function(fe) return {field:fe.field, expr:_map(fe.expr)}).array()));
			case EArrayDecl(vals):
				mk(EArrayDecl(vals.map(function(e) return _map(e)).array()));
			case ECall(e, p):
				mk(ECall(_map(e), p.map(function(e) return _map(e)).array()));
			case ENew(t, p):
				mk(ENew(t, p.map(function(e) return _map(e)).array() ));
			case EUnop(op, pf, e):
				mk(EUnop(op, pf, _map(e)));
			case EVars(vars):
				mk(EVars( vars.map(function(v) return {name:v.name, type:v.type, expr:_map(v.expr)} ).array() ));
			case EFunction(name, f):
				mk(EFunction(name, { args:f.args, ret:f.ret, expr:_map(mkBlock(f.expr)), params:f.params }));
			case EBlock(b):
				var currentMappedBlock = [];
			
				for (e2 in b)
				{
					currentMappedBlock.push(_map(e2));
				}
			
				mk(EBlock( currentMappedBlock ));
			case EFor(v, it, expr):
				mk(EFor(v, _map(it), _map(mkBlock(expr))));
			case EIf(econd, eif, eelse):
				mk(EIf(_map(econd), _map(mkBlock(eif)), _map(mkBlock(eelse))));
			case EWhile(econd, e, normalWhile):
				mk(EWhile(_map(econd), _map(mkBlock(e)), normalWhile));
			case ESwitch(e, cases, edef):
				mk(ESwitch(_map(e), cases.map(function(c) return {values:c.values.map(function(e) return _map(e)).array() , expr:_map(mkBlock(c.expr)) } ).array(), _map(mkBlock(edef))));
			case ETry(e, catches):
				mk(ETry(_map(mkBlock(e)), catches.map(function(c) return {name:c.name, type:c.type, expr:_map(mkBlock(c.expr))}).array()));
			case EReturn(e):
				mk(EReturn(_map(e)));
			case EBreak, EContinue, EDisplayNew(_):
				e;
			case EUntyped(e):
				mk(EUntyped(_map(e)));
			case EThrow(e):
				mk(EThrow(_map(e)));
			case ECast(e, t):
				mk(ECast(_map(e), t));
			case EDisplay(e, call):
				mk(EDisplay(_map(e), call));
			case ETernary(econd, eif, eelse):
				mk(ETernary(_map(econd), _map(eif), _map(eelse)));
		}
	}
	
	
	//"public access" function
	function map(e:Expr) : Expr
	{
		cumulativeInValue = false;
		inValue = false;
		return _map(e);
	}
	
	//internal function
	function _map(e:Expr) : Expr
	{
		inValue = false;
		
		//handle Null<Expr> cases
		if (e == null)
			return null;
		
		var lastPos = this.pos;
		var lastE = this.current;
		
		this.pos = e.pos;
		this.current = e;
		
		var me = this;
		var _inValue = inValue;
		var _cumulative = cumulativeInValue;
		inValue = true;
		cumulativeInValue = true;
		
		
		var eret = mapImpl(e);
		if (eret == null)
			eret = switch(e.expr)
			{
				case EConst(c):
					e;
				case EArray(e1, e2):
					inValue = true;
					mk(EArray(_map(e1), _map(e2)));
				case EBinop(op, e1, e2):
					inValue = true;
					mk(EBinop(op, _map(e1), _map(e2)));
				case EField(e, field):
					mk(EField(_map(e), field));
				case EType(e, field):
					mk(EType(_map(e), field));
				case EParenthesis(e):
					inValue = _inValue;
					mk(EParenthesis(_map(e)));
				case EObjectDecl(fields):
					mk(EObjectDecl(fields.map(function(fe) return {field:fe.field, expr:me._map(fe.expr)}).array()));
				case EArrayDecl(vals):
					mk(EArrayDecl(vals.map(function(e) return me._map(e)).array()));
				case ECall(e, p):
					mk(ECall(_map(e), p.map(function(e) return me._map(e)).array()));
				case ENew(t, p):
					mk(ENew(t, p.map(function(e) return me._map(e)).array() ));
				case EUnop(op, pf, e):
					mk(EUnop(op, pf, _map(e)));
				case EVars(vars):
					mk(EVars( vars.map(function(v) return {name:v.name, type:v.type, expr:me._map(v.expr)} ).array() ));
				case EFunction(name, f):
					mk(EFunction(name, { args:f.args, ret:f.ret, expr:_map(mkBlock(f.expr)), params:f.params }));
				case EBlock(b):
					pushStack();
					var lastB = this.currentBlock;
					this.currentBlock = e;
					var lastBlArray = this.currentMappedBlock;
					this.currentMappedBlock = [];
				
					for (e2 in b)
					{
						inValue = false;
						cumulativeInValue = _cumulative;
					
						currentMappedBlock.push(_map(e2));
					}
				
					var e = mk(EBlock( currentMappedBlock ));
				
				
					this.currentBlock = lastB;
					this.currentMappedBlock = lastBlArray;
					popStack();
				
					e;
				case EFor(v, it, expr):
					mk(EFor(v, _map(it), _map(mkBlock(expr))));
				case EIf(econd, eif, eelse):
					mk(EIf(_map(econd), _map(mkBlock(eif)), _map(mkBlock(eelse))));
				case EWhile(econd, e, normalWhile):
					mk(EWhile(_map(econd), _map(mkBlock(e)), normalWhile));
				case ESwitch(e, cases, edef):
					mk(ESwitch(_map(e), cases.map(function(c) return {values:c.values.map(function(e) return me._map(e)).array() , expr:me._map(mkBlock(c.expr)) } ).array(), _map(mkBlock(edef))));
				case ETry(e, catches):
					mk(ETry(_map(mkBlock(e)), catches.map(function(c) return {name:c.name, type:c.type, expr:me._map(mkBlock(c.expr))}).array()));
				case EReturn(e):
					mk(EReturn(_map(e)));
				case EBreak, EContinue, EDisplayNew(_):
					e;
				case EUntyped(e):
					mk(EUntyped(_map(e)));
				case EThrow(e):
					mk(EThrow(_map(e)));
				case ECast(e, t):
					mk(ECast(_map(e), t));
				case EDisplay(e, call):
					mk(EDisplay(_map(e), call));
				case ETernary(econd, eif, eelse):
					mk(ETernary(_map(econd), _map(eif), _map(eelse)));
			}
		
		this.inValue = _inValue;
		
		this.pos = lastPos;
		this.current = lastE;
		return eret;
	}
	
	function addExprToCurrentBlock(e:Expr) : Void
	{
		currentMappedBlock.push(e);
	}
	
	function mapImpl(e:Expr) : Null<Expr>
	{
		//override me
		return null;
	}
	
	function pushStack()
	{
		
	}
	
	function popStack()
	{
		
	}
	
	static function mkBlock(e:Expr) : Expr
	{
		if (e == null)
			return null;
		
		switch(e.expr)
		{
			case EBlock(_):
				return e;
			default:
				return { expr:EBlock([e]), pos:e.pos };
		}
	}
	
	
	function mk(e:ExprDef)
	{
		return { expr:e, pos:pos };
	}
	#end
}