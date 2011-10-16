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
class MemoryAccess implements comtacti.native.InlinedHxcpp
{
	public static inline function getByte(buffer:BytesData, addr:Int):Byte
	{
		return untyped __cpp__("((int) (unsigned char) ({0}->GetBase()[addr]))", buffer);
	}
	
	public static inline function getDouble(buffer:BytesData, addr:Int):Double
	{
		return untyped __cpp__("*(double *)( ((unsigned char *){0}->GetBase())+addr)", buffer);
	}
	
	public static inline function getSingle(buffer:BytesData, addr:Int):Single
	{
		return untyped __cpp__("*(float *)( ((unsigned char *){0}->GetBase())+addr)", buffer);
	}
	
	public static inline function getInt(buffer:BytesData, addr:Int):Int
	{
		return untyped __cpp__("*(int *)( ((unsigned char *){0}->GetBase())+addr)", buffer);
	}
	
	public static inline function getShort(buffer:BytesData, addr:Int):Short
	{
		return untyped __cpp__("*(unsigned short *)( ((unsigned char *){0}->GetBase())+addr)", buffer);
	}
	
	public static inline function setByte(buffer:BytesData, addr:Int, val:Byte):Void
	{
		untyped __cpp__("{0}->GetBase()[addr] = {1}", buffer, val);
	}
	
	public static inline function setDouble(buffer:BytesData, addr:Int, val:Double):Void
	{
		untyped __cpp__("((double *)( ((unsigned char *){0}->GetBase())+addr))[0] = {1}", buffer, val);
	}
	
	public static inline function setSingle(buffer:BytesData, addr:Int, val:Single):Void
	{
		untyped __cpp__("((float *)( ((unsigned char *){0}->GetBase())+addr))[0] = {1}", buffer, val);
	}
	
	public static inline function setInt(buffer:BytesData, addr:Int, val:Int):Void
	{
		untyped __cpp__("((int *)( ((unsigned char *){0}->GetBase())+addr))[0] = {1}", buffer, val);
	}
	
	public static inline function setShort(buffer:BytesData, addr:Int, val:Short):Void
	{
		untyped __cpp__("((unsigned short *)( ((unsigned char *){0}->GetBase())+addr))[0] = {1}", buffer, val);
	}
}