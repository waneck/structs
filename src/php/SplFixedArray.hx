@:native("SplFixedArray")
extern class SplFixedArray<T> implements ArrayAccess<T>
{
	public function new(size:Int):Void;
	public function count():Int;
	public function current():T;
	public static function fromArray<T>(array:php.NativeArray, ?saveIndexes:Bool):SplFixedArray<T>;
	public function getSize():Int;
	public function key():Int;
	public function next():Void;
	public function offsetExists(idx:Int):Bool;
	public function offsetGet(idx:Int):T;
	public function offsetSet(idx:Int, val:T):Void;
	public function offsetUnset(idx:Int):Void;
	public function rewind():Void;
	public function setSize(newSize:Int):Int;
	public function toArray():php.NativeArray;
	public function valid():Bool;
}