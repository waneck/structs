package structs;
import haxe.structs.Structs;
import haxe.structs.AbstractStruct;

class BasicStructsTests
{
	var basicStruct:Structs<BasicStruct>;
	
	public function new():Void
	{
		
	}
	
	public function setup():Void
	{
		
	}
	
	
}

class BasicStruct extends AbstractStruct
{
	public var a:Byte;
	public var b:Short;
	public var c:Int;
	public var d:Byte;
	public var e:Double;
}

class ComplexStruct1 extends AbstractStruct
{
	public var a:Single;
	public var basic:BasicStruct;
	public var b:Double;
}

class ComplexStruct2 extends AbstractStruct
{
	public var complex:ComplexStruct1;
}