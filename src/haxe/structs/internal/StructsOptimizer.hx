//
//  StructsOptimizer
//
//  Created by Caue W. on 2011-10-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
package haxe.structs.internal;
import haxe.macro.Map;

/**
 * StructsOptimizer :	
 *  For now, this class will iterate through all AST and change each field access of the 
 *  toChangeVars hash to a local var (defined by the hash itself)
 * 
 * @langversion		HaXe 2
 * @targets			cpp, flash, flash9, js, neko, php
 * @author			Caue Waneck:<a href="mailto">waneck@gmail.com</a>
 * @since			2011-10-10
 */
class StructsOptimizer extends Map
{
	private var toChangeVars:Hash<Hash<String>>
	
	public function new()
	{
		
	}
}