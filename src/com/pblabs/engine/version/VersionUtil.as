package com.pblabs.engine.version
{
	import com.pblabs.engine.serialization.TypeUtility;
	
	import flash.display.Sprite;
	import flash.utils.getDefinitionByName;
	
	use namespace mx_internal;

	public class VersionUtil
	{
		public static function checkVersion(mainClass:Sprite):VersionDetails
		{
			var detail:VersionDetails = new VersionDetails();
			var testObj:*;
			var testClass:Object;
			
			// Test for Spark AIR Application
			testObj = TypeUtility.instantiate("spark.components::WindowedApplication",true);
			if(testObj)
			{
				detail.type = VersionType.AIR;
				testClass = getDefinitionByName("spark.components::WindowedApplication");
				detail.version = testClass.VERSION;
				return detail;
			}
			
			// Test for Halo AIR Application
			testObj = TypeUtility.instantiate("mx.core::WindowedApplication",true);
			if(testObj)
			{
				detail.type = VersionType.AIR;
				testClass = getDefinitionByName("mx.core::WindowedApplication");
				detail.version = testClass.VERSION;
				return detail;
			}
			
			// Test for Flex Spark Application
			testObj = TypeUtility.instantiate("spark.components::Application",true);
			if(testObj)
			{
				detail.type = VersionType.FLEX;
				testClass = getDefinitionByName("spark.components::Application");
				detail.version = testClass.VERSION;
				return detail;
			}
			
			// Test for Flex Halo Application
			testObj = TypeUtility.instantiate("mx.core::Application",true);
			if(testObj)
			{
				detail.type = VersionType.FLEX;
				testClass = getDefinitionByName("mx.core::Application");
				detail.version = testClass.VERSION;
				return detail;
			}
			
			detail.type = VersionType.FLASH;
			
			return detail;
		}
	}
}