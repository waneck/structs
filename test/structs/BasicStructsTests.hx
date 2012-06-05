package structs;
import haxe.structs.internal.StructsInternal;
import utest.Assert;
import haxe.structs.Structs;
import haxe.structs.AbstractStruct;

using haxe.structs.Structs;

class BasicStructsTests
{
	
	var basicStruct:Structs<BasicStruct>;
	var complexStruct:Structs<ComplexStruct1>;
	var complexStruct2:Structs<ComplexStruct2>;
	
	public function new():Void
	{
		
	}
	
	public function setup():Void
	{
		basicStruct = BasicStruct.structs(10);
		complexStruct = ComplexStruct1.structs(10);
		complexStruct2 = ComplexStruct2.structs(10);
		
		trace("Am I big endian? " + StructsInternal.isBigEndian());
	}
	
	public function test_Initialization():Void 
	{
		basicStruct = BasicStruct.structs(10);
		basicStruct.foreach(struct, 
		{
			Assert.same(struct, new BasicStruct(0,0,0,0,0.0));
		});
		Assert.equals(10, basicStruct.structsLength());
	}
	
	public function test_Foreach():Void 
	{
		var i = 0;
		
		basicStruct.foreach(struct, 
		{
			basicStruct.set(i, a=i, b=i, c=i, d=i, e=i+0.0);
			i++;
		});
		
		var len = basicStruct.structsLength();
		Assert.equals(i, len, "Structs.length()# is returning a different value from foreach iterations. Expected " + i + " and got " + len);
		
		for (i in 0...len)
		{
			Assert.same(basicStruct.get(i), new BasicStruct(i,i,i,i,i+0.0));
		}
	}
	
	public function test_BasicStructValuesOverflow():Void 
	{
		//first test if all values are initialized to zero
		var i = 0;
		
		basicStruct.foreach(struct, 
		{
			basicStruct.set(i++, a=i*111, b=i*10000, c=i*1000000000, d=i*50, e=i*100.0);
		});
		
		i = 0;
		basicStruct.foreach(struct, {
			i++;
			Assert.same(new BasicStruct((i*111 & 0xFF),(i*10000 & 0xFFFF),Std.int(i*1000000000) & 0xFFFFFFFF,(i*50 & 0xFF),i*100.0), struct);
		});
	}
	
	public function test_ComplexStructGetSet():Void 
	{
		var i = 0;
		complexStruct.set(i, a=i+0.0, basic.a=i, basic.b=i, basic.c=i, basic.d=i, basic.e=i+0.0, b=i+0.0);
		Assert.same(complexStruct.get(i), new ComplexStruct1(i+0.0,new BasicStruct(i,i,i,i,i+0.0),i+0.0));
	}
	
	public function test_ComplexStructForeach():Void 
	{
		var i = 0;
		
		complexStruct.foreach(struct, 
		{
			complexStruct.set(i, a=i, basic.a=i, basic.b=i, basic.c=i, basic.d=i, basic.e=i+0.0, b=i);
			i++;
		});
		
		var len = complexStruct.structsLength();
		Assert.equals(i, len, "Structs.length()# is returning a different value from foreach iterations. Expected " + i + " and got " + len);
		
		for (i in 0...len)
		{
			Assert.same(new ComplexStruct1(i+0.0,new BasicStruct(i,i,i,i,i+0.0),i+0.0), complexStruct.get(i));
		}
	}
	
	public function test_InvSqrt():Void 
	{
		var number = 1024;
		
		Assert.floatEquals(1 / Math.sqrt(number), invSqrt(number), 0.01);
	}
	
	public function test_Int64Endianness():Void 
	{
		var helper = Int64Helper.structs(1);
		var i64 = Int64.make(Int32.make(0x1234, 0x5678), Int32.make(0x9012, 0x3456));
		helper.set(0, int64 = i64);
		var i1 = helper.get(0, int1);
		var i2 = helper.get(0, int2);
		
		if (StructsInternal.isBigEndian())
		{
			Assert.isTrue(Int32.compare(Int32.make(0x1234, 0x5678), i1) == 0);
		} else {
			Assert.isTrue(Int32.compare(Int32.make(0x1234, 0x5678), i2) == 0);
		}
	}
	
	private function invSqrt(x:Float):Float 
	{
		var helper = InvSqrtHelper.structs(1);
		var half = 0.5 * x;
    helper.set(0, float = x);
		var i = helper.get(0, int);
    i = Int32.sub( Int32.make(0x5f37, 0x59df), (Int32.shr(i,1)) );
		helper.set(0, int = i);
		x = helper.get(0, float);
    x = x * (1.5 - half*x*x);
    return x;
	}
	
}

@:structLayout(Explicit)
class Int64Helper extends AbstractStruct
{
	@:fieldOffset(0)
	public var int64:Int64;
	@:fieldOffset(0)
	public var int1:Int32;
	@:fieldOffset(4)
	public var int2:Int32;
}

@:structLayout(Explicit)
class InvSqrtHelper extends AbstractStruct
{
	@:fieldOffset(0)
	public var float:Single;
	@:fieldOffset(0)
	public var int:Int32;
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