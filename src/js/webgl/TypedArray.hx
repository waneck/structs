package js.webgl;
import haxe.structs.options.Types;

/**
 *  Based on Editor's Draft 12 September 2011
 *  (http://www.khronos.org/registry/typedarray/specs/latest/)
 **/

/**
 *  The ArrayBuffer type describes a buffer used to store data for the array buffer views.
 **/
@:native("ArrayBuffer")
extern class ArrayBuffer
{
	/**
	 *  The length of the ArrayBuffer in bytes, as fixed at construction time.
	 **/
	public var byteLength(default, null):Int;
	
	/**
	 *  Creates a new ArrayBuffer of the given length in bytes.
	 *  The contents of the ArrayBuffer are initialized to 0.
	 *  If the requested number of bytes could not be allocated an exception is raised.
	 **/
	public function new(byteLength:Int):Void;
	
}


/**
 *  The ArrayBufferView type holds information shared among all of the types of views of ArrayBuffers.
 **/
@:native("ArrayBufferView")
extern private class ArrayBufferView
{
	/**
	 *  The ArrayBuffer that this ArrayBufferView references.
	 **/
	public var buffer(default, null):ArrayBuffer;
	/**
	 *  The offset of this ArrayBufferView from the start of its ArrayBuffer, in bytes, as fixed at construction time.
	 **/
	public var byteOffset(default, null):Int;
	/**
	 *  The length of the ArrayBufferView in bytes, as fixed at construction time.
	 **/
	public var byteLength(default, null):Int;
}

@:native("TypedArray")
extern private class TypedArray<T> extends ArrayBufferView, implements ArrayAccess<T>
{
	/**
	 *  The size in bytes of each element in the array.
	 **/
	public var BYTES_PER_ELEMENT(default, null):Int;
	
	/**
	 *  Create a new TypedArray object using the passed ArrayBuffer for its storage. 
	 *  Optional byteOffset and length can be used to limit the section of the buffer referenced. 
	 *  The byteOffset indicates the offset in bytes from the start of the ArrayBuffer, and the length is 
	 *  the count of elements from the offset that this TypedArray will reference. If both byteOffset and 
	 *  length are omitted, the TypedArray spans the entire ArrayBuffer range. If the length is omitted, the
	 *  TypedArray extends from the given byteOffset until the end of the ArrayBuffer.
	 *  
	 *  The given byteOffset must be a multiple of the element size of the specific type, otherwise an exception
	 *  is raised.
	 *  
	 *  If a given byteOffset and length references an area beyond the end of the ArrayBuffer an exception is raised.
	 *  
	 *  If length is not explicitly specified, the length of the ArrayBuffer minus the byteOffset must be a multiple 
	 *  of the element size of the specific type, or an exception is raised.
	 **/
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<T>):Void {})
	@:overload(function(array:Array<T>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	/**
	 *  Create a new ArrayBuffer with enough bytes to hold length elements of this typed array, 
	 *  then creates a typed array view referring to the full buffer. As with a directly constructed ArrayBuffer, 
	 *  the contents are initialized to 0. If the requested number of bytes could not be allocated an exception 
	 *  is raised.
	 **/
	public static inline function ofLength<T>(length:Int):TypedArray<T>
	{
		untyped return new TypedArray(length);
	}
	/**
	 *  Create a new ArrayBuffer with enough bytes to hold array.length elements of this typed array, 
	 *  then creates a typed array view referring to the full buffer. The contents of the new view are 
	 *  initialized to the contents of the given array or typed array, with each element converted to 
	 *  the appropriate typed array type.
	 **/
	public static inline function ofTypedArray<T>(array:TypedArray<T>):TypedArray<T>
	{
		untyped return new TypedArray(array);
	}
	
	public static inline function ofArray<T>(array:Array<T>):TypedArray<T>
	{
		untyped return new TypedArray(array);
	}
	
	/**
	 *  The length of the TypedArray in elements, as fixed at construction time.
	 **/
	public var length(default, null):Int;
	/**
	 *  This is an index getter.
	 *  
	 *  Returns the element at the given numeric index.
	 **/
	public function get(index:Int):T;
	
	@:overload(function(array:TypedArray<T>, ?offset:Int):Void {})
	@:overload(function(array:Array<T>, ?offset:Int):Void {})
	public function set(index:Int, val:T):Void;
	/**
	 *  Set multiple values, reading input values from the array.
	 *  
	 *  The optional offset value indicates the index in the current array where values are written.
	 *  If omitted, it is assumed to be 0.
	 *  
	 *  If the input array is a TypedArray, the two arrays may use the same underlying ArrayBuffer. 
	 *  In this situation, setting the values takes place as if all the data is first copied into a 
	 *  temporary buffer that does not overlap either of the arrays, and then the data from the temporary 
	 *  buffer is copied into the current array.
	 *  
	 *  If the offset plus the length of the given array is out of range for the current TypedArray, an exception 
	 *  is raised.
	 **/
	public inline function setTypedArray(array:TypedArray<T>, ?offset:Int):Void
	{
		untyped set(array, offset);
	}
	
	public inline function setArray(array:Array<T>, ?offset:Int):Void
	{
		untyped set(array, offset);
	}
	/**
	 *  Returns a new TypedArray view of the ArrayBuffer store for this TypedArray, referencing the elements
	 *  at begin, inclusive, up to end, exclusive. If either begin or end is negative, it refers to an index
	 *  from the end of the array, as opposed to from the beginning.
	 *  
	 *  If end is unspecified, the subarray contains all elements from begin to the end of the TypedArray.
	 *  
	 *  The range specified by the begin and end values is clamped to the valid index range for the current array.
	 *  If the computed length of the new TypedArray would be negative, it is clamped to zero.
	 *  
	 *  The returned TypedArray will be of the same type as the array on which this method is invoked.
	 **/
	public function subarray(begin:Int, ?end:Int):TypedArray<T>;
}

/**
 *  Uint8ClampedArray is defined in order to replace CanvasPixelArray.
 *  It behaves identically to the other typed array views, except that the setters and constructor use
 *  clamping rather than modulo arithmetic when converting incoming number values. The IDL
 *  for Uint8ClampedArray follows.
 **/
@:native("Uint8ClampedArray")
extern class Uint8ClampedArray extends TypedArray<Byte>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Byte>):Void {})
	@:overload(function(array:Array<Byte>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	/**
	 *  Create a new ArrayBuffer with enough bytes to hold length elements of this typed array, 
	 *  then creates a typed array view referring to the full buffer. As with a directly constructed ArrayBuffer, 
	 *  the contents are initialized to 0. If the requested number of bytes could not be allocated an exception 
	 *  is raised.
	 **/
	public static inline function ofLength(length:Int):Uint8ClampedArray
	{
		untyped return new Uint8ClampedArray(length);
	}
	/**
	 *  Create a new ArrayBuffer with enough bytes to hold array.length elements of this typed array, 
	 *  then creates a typed array view referring to the full buffer. The contents of the new view are 
	 *  initialized to the contents of the given array or typed array, with each element converted to 
	 *  the appropriate typed array type.
	 **/
	public static inline function ofTypedArray(array:TypedArray<Byte>):Uint8ClampedArray
	{
		untyped return new Uint8ClampedArray(array);
	}
	
	public static inline function ofArray(array:Array<Byte>):Uint8ClampedArray
	{
		untyped return new Uint8ClampedArray(array);
	}
}

/**
 *  An ArrayBuffer is a useful object for representing an arbitrary chunk of data. In many cases, 
 *  such data will be read from disk or from the network, and will not follow the alignment restrictions 
 *  that are imposed on the typed array views described earlier. In addition, the data will often be 
 *  heterogeneous in nature and have a defined byte order. The DataView view provides a low-level 
 *  interface for reading such data from and writing it to an ArrayBuffer.
 **/
@:native("DataView")
extern class DataView extends ArrayBufferView
{
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?byteLength:Int):Void;
	
	// Gets the value of the given type at the specified byte offset
    // from the start of the view. There is no alignment constraint;
    // multi-byte values may be fetched from any offset.
    //
    // For multi-byte values, the optional littleEndian argument
    // indicates whether a big-endian or little-endian value should be
    // read. If false or undefined, a big-endian value is read.
    //
    // These methods raise an exception if they would read
    // beyond the end of the view.
	public function getInt8(byteOffset:Int):Byte;
	public function getUint8(byteOffset:Int):Byte;
	public function getInt16(byteOffset:Int, ?littleEndian:Bool):Short;
	public function getUint16(byteOffset:Int, ?littleEndian:Bool):Short;
	public function getInt32(byteOffset:Int, ?littleEndian:Bool):Int;
	public function getUint32(byteOffset:Int, ?littleEndian:Bool):Int;
	public function getFloat32(byteOffset:Int, ?littleEndian:Bool):Single;
	public function getFloat64(byteOffset:Int, ?littleEndian:Bool):Double;
	
    // Stores a value of the given type at the specified byte offset
    // from the start of the view. There is no alignment constraint;
    // multi-byte values may be stored at any offset.
    //
    // For multi-byte values, the optional littleEndian argument
    // indicates whether the value should be stored in big-endian or
    // little-endian byte order. If false or undefined, the value is
    // stored in big-endian byte order.
    //
    // These methods raise an exception if they would write
    // beyond the end of the view.
	public function setInt8(byteOffset:Int, value:Byte):Void;
	public function setUint8(byteOffset:Int, value:Byte):Void;
	public function setInt16(byteOffset:Int, value:Short, ?littleEndian:Bool):Void;
	public function setUint16(byteOffset:Int, value:Short, ?littleEndian:Bool):Void;
	public function setInt32(byteOffset:Int, value:Int, ?littleEndian:Bool):Void;
	public function setUint32(byteOffset:Int, value:Int, ?littleEndian:Bool):Void;
	public function setFloat32(byteOffset:Int, value:Single, ?littleEndian:Bool):Void;
	public function setFloat64(byteOffset:Int, value:Double, ?littleEndian:Bool):Void;
}

@:native("Int8Array")
extern class Int8Array extends TypedArray<Byte>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Byte>):Void {})
	@:overload(function(array:Array<Byte>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	public static inline function ofLength(length:Int):Int8Array
	{
		untyped return new Int8Array(length);
	}
	public static inline function ofTypedArray(array:TypedArray<Byte>):Int8Array
	{
		untyped return new Int8Array(array);
	}
	
	public static inline function ofArray(array:Array<Byte>):Int8Array
	{
		untyped return new Int8Array(array);
	}
}

@:native("Uint8Array")
extern class Uint8Array extends TypedArray<Byte>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Byte>):Void {})
	@:overload(function(array:Array<Byte>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	public static inline function ofLength(length:Int):Uint8Array
	{
		untyped return new Uint8Array(length);
	}
	public static inline function ofTypedArray(array:TypedArray<Byte>):Uint8Array
	{
		untyped return new Uint8Array(array);
	}
	
	public static inline function ofArray(array:Array<Byte>):Uint8Array
	{
		untyped return new Uint8Array(array);
	}
}

@:native("Int16Array")
extern class Int16Array extends TypedArray<Short>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Short>):Void {})
	@:overload(function(array:Array<Short>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	public static inline function ofLength(length:Int):Int16Array
	{
		untyped return new Int16Array(length);
	}
	public static inline function ofTypedArray(array:TypedArray<Short>):Int16Array
	{
		untyped return new Int16Array(array);
	}
	
	public static inline function ofArray(array:Array<Short>):Int16Array
	{
		untyped return new Int16Array(array);
	}
}

@:native("Uint16Array")
extern class Uint16Array extends TypedArray<Short>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Short>):Void {})
	@:overload(function(array:Array<Short>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	public static inline function ofLength(length:Int):Uint16Array
	{
		untyped return new Uint16Array(length);
	}
	public static inline function ofTypedArray(array:TypedArray<Short>):Uint16Array
	{
		untyped return new Uint16Array(array);
	}
	
	public static inline function ofArray(array:Array<Short>):Uint16Array
	{
		untyped return new Uint16Array(array);
	}
}

@:native("Int32Array")
extern class Int32Array extends TypedArray<Int>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Int>):Void {})
	@:overload(function(array:Array<Int>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	public static inline function ofLength(length:Int):Int32Array
	{
		untyped return new Int32Array(length);
	}
	public static inline function ofTypedArray(array:TypedArray<Int>):Int32Array
	{
		untyped return new Int32Array(array);
	}
	
	public static inline function ofArray(array:Array<Int>):Int32Array
	{
		untyped return new Int32Array(array);
	}
}

@:native("Uint32Array")
extern class Uint32Array extends TypedArray<Int>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Int>):Void {})
	@:overload(function(array:Array<Int>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	public static inline function ofLength(length:Int):Uint32Array
	{
		untyped return new Uint32Array(length);
	}
	public static inline function ofTypedArray(array:TypedArray<Int>):Uint32Array
	{
		untyped return new Uint32Array(array);
	}
	
	public static inline function ofArray(array:Array<Int>):Uint32Array
	{
		untyped return new Uint32Array(array);
	}
}

@:native("Float32Array")
extern class Float32Array extends TypedArray<Single>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Single>):Void {})
	@:overload(function(array:Array<Single>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	public static inline function ofLength(length:Int):Float32Array
	{
		untyped return new Float32Array(length);
	}
	public static inline function ofTypedArray(array:TypedArray<Single>):Float32Array
	{
		untyped return new Float32Array(array);
	}
	
	public static inline function ofArray(array:Array<Single>):Float32Array
	{
		untyped return new Float32Array(array);
	}
}

@:native("Float64Array")
extern class Float64Array extends TypedArray<Double>
{
	@:overload(function(length:Int):Void {})
	@:overload(function(array:TypedArray<Double>):Void {})
	@:overload(function(array:Array<Double>):Void {})
	public function new(buffer:ArrayBuffer, ?byteOffset:Int, ?length:Int):Void;
	
	public static inline function ofLength(length:Int):Float64Array
	{
		untyped return new Float64Array(length);
	}
	public static inline function ofTypedArray(array:TypedArray<Double>):Float64Array
	{
		untyped return new Float64Array(array);
	}
	
	public static inline function ofArray(array:Array<Double>):Float64Array
	{
		untyped return new Float64Array(array);
	}
}