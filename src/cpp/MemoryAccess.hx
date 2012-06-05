package cpp;
import haxe.structs.options.Types;
import haxe.io.BytesData;

/**
 * MemoryAccess :	A helper class for cpp so we can access directly, and unsafely, an underlying BytesData content
 * 
 * @langversion		HaXe 2
 * @targets			cpp
 * @author			Caue Waneck:<a href="mailto">waneck@gmail.com</a>
 * @since			2011-10-15
 */
class MemoryAccess
{
	public static inline function getByte(buffer:BytesData, addr:Int):Byte 
		return untyped __global__.__hxcpp_memory_get_byte(buffer, addr)
	
	public static inline function getDouble(buffer:BytesData, addr:Int):Double
		return untyped __global__.__hxcpp_memory_get_double(buffer, addr)
	
	public static inline function getSingle(buffer:BytesData, addr:Int):Single
		return untyped __global__.__hxcpp_memory_get_float(buffer, addr)
	
	public static inline function getInt(buffer:BytesData, addr:Int):Int
		return untyped __global__.__hxcpp_memory_get_i32(buffer, addr)
	
	public static inline function getShort(buffer:BytesData, addr:Int):Short
		return untyped __global__.__hxcpp_memory_get_ui16(buffer, addr)
	
	public static inline function setByte(buffer:BytesData, addr:Int, val:Byte):Void
		return untyped __global__.__hxcpp_memory_set_byte(buffer, addr, val)
	
	public static inline function setDouble(buffer:BytesData, addr:Int, val:Double):Void
		return untyped __global__.__hxcpp_memory_set_double(buffer, addr, val)
	
	public static inline function setSingle(buffer:BytesData, addr:Int, val:Single):Void
		return untyped __global__.__hxcpp_memory_set_float(buffer, addr, val)
	
	public static inline function setInt(buffer:BytesData, addr:Int, val:Int):Void
		return untyped __global__.__hxcpp_memory_set_i32(buffer, addr, val)
	
	public static inline function setShort(buffer:BytesData, addr:Int, val:Short):Void
		return untyped __global__.__hxcpp_memory_set_i16(buffer, addr, val)
}