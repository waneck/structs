package haxe.structs.options;

enum StructLayout
{
	/**
	 *  It's the most compatible layout. Ideal for interoperability.
	 **/
	Sequential;
	/**
	 *  The fields will be rearranged in order to use as least space as it can.
	 *  The fields will all be correctly aligned, though.
	 **/
	Compact;
	/**
	 *  Explicitly define the layout with @:fieldOffset() meta
	 **/
	Explicit;
}