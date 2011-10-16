package haxe.structs.internal;
import haxe.structs.options.Types;
import haxe.structs.Structs;

class StructsInternal
{
	public static inline function getInt8(me:Structs<Dynamic>, bytesOffset:Int):Byte
	{
#if flash9
		return flash.Memory.getByte(me + bytesOffset);
#elseif cpp
		return cpp.MemoryAccess.getByte(me, bytesOffset);
#elseif neko
		return untyped __dollar__sget(me, bytesOffset);
#elseif js
		return me.getUint8(bytesOffset);
#else
		return me[bytesOffset] & 0xFF;
#end
	}
	
	public static inline function getInt16(me:Structs<Dynamic>, bytesOffset:Int):Short
	{
#if flash9
		return flash.Memory.getUI16(me + bytesOffset);
#elseif cpp
		return cpp.MemoryAccess.getShort(me, bytesOffset);
#elseif neko
		return getInt8(me, bytesOffset + 1) | (getInt8(me, bytesOffset)<<8);
#elseif js
		return me.getUint16(bytesOffset);
#else
		return me[bytesOffset] & 0xFFFF;
#end
	}
	
	public static inline function getInt32(me:Structs<Dynamic>, bytesOffset:Int):Int
	{
#if flash9
		return flash.Memory.getI32(me + bytesOffset);
#elseif cpp
		return cpp.MemoryAccess.getInt(me, bytesOffset);
#elseif neko
		return (getInt8(me, bytesOffset) << 24) | (getInt8(me, bytesOffset + 1)<<16) | (getInt8(me, bytesOffset + 2)<<8) | (getInt8(me, bytesOffset + 3));
#elseif js
		return me.getInt32(bytesOffset);
#else
		return me[bytesOffset] | 0x0;
#end
	}
	
	public static inline function getSingle(me:Structs<Dynamic>, bytesOffset:Int):Single
	{
#if flash9
		return flash.Memory.getFloat(me + bytesOffset);
#elseif cpp
		return cpp.MemoryAccess.getSingle(me, bytesOffset);
#elseif neko
		return _float_of_bytes(untyped __dollar__ssub(me,bytesOffset,4),true);
#elseif js
		return me.getFloat32(bytesOffset);
#else
		return me[bytesOffset];
#end
	}
	
	public static inline function getDouble(me:Structs<Dynamic>, bytesOffset:Int):Double
	{
#if flash9
		return flash.Memory.getDouble(me + bytesOffset);
#elseif cpp
		return cpp.MemoryAccess.getDouble(me, bytesOffset);
#elseif neko
		return _double_of_bytes(untyped __dollar__ssub(me,bytesOffset,8),true);
#elseif js
		return me.getFloat64(bytesOffset);
#else
		me[bytesOffset];
#end
	}
	
	
	/////////////////// ENDIANNESS
	
	public static function isBigEndian():Null<Bool>
	{
#if flash9
		return false; //it's always little endian, AFAIK
#elseif cpp
		return bigEndian;
#elseif neko
		return true;
#elseif js
		return bigEndian;
#else
		return null;
#end
	}
	
#if (cpp || js)
	private static var bigEndian:Bool = _isBigEndian();

	private static function _isBigEndian():Bool
	{
		if (bigEndian != null)
			return bigEndian;
		var s = internalMake(4);
		setInt32(s, 0, 1);
		
		return getInt8(s, 0) != 1;
	}
	
#end
	
	//////////////////////////////////////////
	
	public static inline function setInt8(me:Structs<Dynamic>, bytesOffset:Int, val:Byte):Void
	{
#if flash9
		flash.Memory.setByte(me + bytesOffset, val);
#elseif cpp
		cpp.MemoryAccess.setByte(me, bytesOffset, val);
#elseif neko
		untyped __dollar__sset(me, bytesOffset, val);
#elseif js
		me.setUint8(bytesOffset, val);
#else
		me[bytesOffset] = val & 0xFF;
#end
	}
	
	public static inline function setInt16(me:Structs<Dynamic>, bytesOffset:Int, val:Short):Void
	{
#if flash9
		flash.Memory.setI16(me + bytesOffset, val);
#elseif cpp
		cpp.MemoryAccess.setShort(me, bytesOffset, val);
#elseif neko
		setInt8(me, bytesOffset, val >> 8);
		setInt8(me, bytesOffset + 1, val);
#elseif js
		me.setUint16(bytesOffset, val);
#else
		me[bytesOffset] = val & 0xFFFF;
#end
	}
	
	public static function setInt32h(me:Structs<Dynamic>, bytesOffset:Int, val:haxe.Int32):Void
	{
#if neko
		setInt16(me, bytesOffset, haxe.Int32.toInt( haxe.Int32.shr(haxe.Int32.and(val, haxe.Int32.make(0xffff,0)), 16)));
		setInt16(me, bytesOffset + 2, haxe.Int32.toInt(haxe.Int32.and(val, haxe.Int32.ofInt(0xffff))));
#else
		setInt32(me, bytesOffset, haxe.Int32.toInt(val));
#end
	}
	
	public static function setInt64(me:Structs<Dynamic>, bytesOffset:Int, val:haxe.Int64):Void
	{
		if (isBigEndian())
		{
			setInt32h(me, bytesOffset + 4, haxe.Int64.getHigh(val));
			setInt32h(me, bytesOffset, haxe.Int64.getLow(val));
		} else {
			setInt32h(me, bytesOffset, haxe.Int64.getHigh(val));
			setInt32h(me, bytesOffset + 4, haxe.Int64.getLow(val));
		}
	}
	
	public static inline function setInt32(me:Structs<Dynamic>, bytesOffset:Int, val:Int):Void
	{
#if flash9
		flash.Memory.setI32(me + bytesOffset, val);
#elseif cpp
		cpp.MemoryAccess.setInt(me, bytesOffset, val);
#elseif neko
		setInt8(me, bytesOffset, val >> 24);
		setInt8(me, bytesOffset + 1, val >> 16);
		setInt8(me, bytesOffset + 2, val >> 8);
		setInt8(me, bytesOffset + 3, val);
#elseif js
		me.setInt32(bytesOffset, val);
#else
		me[bytesOffset] = val | 0x0;
#end
	}
	
	public static inline function setSingle(me:Structs<Dynamic>, bytesOffset:Int, val:Single):Void
	{
#if flash9
		flash.Memory.setFloat(me + bytesOffset, val);
#elseif cpp
		cpp.MemoryAccess.setSingle(me, bytesOffset, val);
#elseif neko
		untyped __dollar__sblit(me,bytesOffset,_float_bytes(val,true),0,4);
#elseif js
		me.setFloat32(bytesOffset, val);
#else
		me[bytesOffset] = val;
#end
	}
	
	public static inline function setDouble(me:Structs<Dynamic>, bytesOffset:Int, val:Double):Void
	{
#if flash9
		flash.Memory.setDouble(me + bytesOffset, val);
#elseif cpp
		cpp.MemoryAccess.setDouble(me, bytesOffset, val);
#elseif neko
		untyped __dollar__sblit(me,bytesOffset,_double_bytes(val,true),0,8);
#elseif js
		me.setFloat64(bytesOffset, val);
#else
		me[bytesOffset] = val;
#end
	}
	
	public static inline function internalMake<T>(totalBytesLength:Int):Structs<T>
	{
#if flash9
		return haxe.structs.management.Manager.malloc(totalBytesLength);
#elseif cpp
		var ret = new haxe.io.BytesData();
		untyped ret[totalBytesLength - 1] = 0; //prealloc
		return ret;
#elseif neko
		var ret = untyped __dollar__smake(totalBytesLength);
		return ret;
#elseif js
		var buf = new js.webgl.TypedArray.ArrayBuffer(totalBytesLength);
		return new js.webgl.TypedArray.DataView(buf);
#elseif php //not working
		return new php.SplFixedArray(totalLength);
#else //not working
		var ret = [];
		ret[totalLength - 1] = 0; //prealloc
		return ret;
#end
	}
	
	public static inline function internalSize(s:Structs<Dynamic>):Int
	{
#if flash9
		return haxe.structs.management.Manager.getBytesLength(s);
#elseif cpp
		return s.length;
#elseif neko
		return untyped __dollar__ssize(s);
#elseif php
		return s.getSize();
#elseif js
		return s.buffer.byteLength;
#else
		return s.length;
#end
	}
	

	public static #if !js inline #end function internalRealloc<T>(s:Structs<T>, toBytesSize:Int, toLength:Int):Structs<T>
	{
#if flash9
		return haxe.structs.management.Manager.realloc(s, toBytesSize);
#elseif cpp
		if (s.length < toBytesSize)
		untyped s[toBytesSize - 1] = 0;
		return s;
#elseif neko
		var curSize = untyped __dollar__ssize(s);
		if (curSize < toBytesSize)
		{
			var sret = untyped __dollar__smake(toBytesSize);
			untyped __dollar__sblit(sret, 0, s, 0, curSize);
			return sret;
		} else {
			return s;
		}
#elseif php
		s.setSize(toLength);
		return s;
#elseif js
		if (s.buffer.byteLength < toBytesSize)
		{
			var buf2 = new js.webgl.TypedArray.ArrayBuffer(toBytesSize);
			var ret = new js.webgl.TypedArray.DataView(buf2);

			for (i in 0...Std.int(s.buffer.byteLength / 4))
			{
				ret.setInt32(i*4, s.getInt32(i*4));
			}

			return ret;
		} else {
			return s;
		}
#else
		if (s.length < toLength)
			s[toLength - 1] = 0;
		return s;
#end
	}

#if neko
	static var _float_of_bytes = neko.Lib.load("std","float_of_bytes",2);
	static var _double_of_bytes = neko.Lib.load("std","double_of_bytes",2);
	static var _float_bytes = neko.Lib.load("std","float_bytes",2);
	static var _double_bytes = neko.Lib.load("std","double_bytes",2);
#end
}