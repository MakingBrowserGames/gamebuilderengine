package PBLabs.Tweaker
{
   import PBLabs.Engine.Entity.*;
   import PBLabs.Engine.Debug.*;
   import PBLabs.Engine.Core.*;

   import flash.events.*;
   import flash.net.*;
   import flash.utils.Dictionary;

   /**
    * Put values from a Google Spreadsheet into your game for tweaking purposes.
    * <p>
    * A big part of any game are the values that define how it behaves. Small
    * changes in timing, forces, or scores can have big impacts on how fun a
    * game is. The process of making a game fun involves endless tweaking and
    * testing. Often the people doing that work are not programmers, so editing
    * source code and recompiling can be a big barrier for them.
    * <p>
    * The GoogleSpreadsheetTweaker lets the game programmer map values on named
    * objects and in templates to cells on a Google Spreadsheet. 
    */
   public class GoogleSpreadsheetTweaker extends EntityComponent
   {
      /**
       * The feed for a publicly accessible Google Spreadsheet.
       *
       * The naming convention for these feeds is described at 
       * http://code.google.com/apis/spreadsheets/docs/3.0/reference.html#ConstructingURIs
       *
       * Example of a working URL (key changed to protect the innocent):
       * http://spreadsheets.google.com/feeds/cells/pZ6iqteeevF7uf4J123yqSw/od6/public/basic
       * This gets the first sheet of the specified document.
       */
      public var SpreadsheetUrl:String = "";
      
      /**
       * The URL for the proxy script, described in the web subfolder of this
       * project.
       */
      public var ProxyUrl:String = "http://coderhump.com/pbe/latestSkirmish/GoogleSpreadsheetProxy.php";
      
      /**
       * List of TweakerMapEntry instances mapping cells to properties.
       */
      [TypeHint(type="PBLabs.Tweaker.TweakerMapEntry")]
      public var Config:Array = new Array();

      protected override function _OnAdd():void
      {
         // Request the URL via our proxy.
         var ur:URLRequest = new URLRequest(ProxyUrl);
         ur.method = URLRequestMethod.POST;
         ur.data = new URLVariables();
         ur.data["_url"] = SpreadsheetUrl;

         var loader:URLLoader = new URLLoader();
         loader.addEventListener(Event.COMPLETE, _OnLoadComplete);
         loader.addEventListener(IOErrorEvent.IO_ERROR, _OnLoadFail);
         loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _OnLoadFail);
         loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, 
               function(e:HTTPStatusEvent):void { Logger.Print(this, "Got status back: " + e.toString()); }
               );
         loader.load(ur);
         
         Logger.Print(this, "Requesting spreadsheet " + SpreadsheetUrl);
      }

      private function _OnLoadComplete(e:Event):void
      {
         // Convert bytes to string to XML.
         var tweakXML:XML = new XML((e.target as URLLoader).data);

        // Extract the entries.
        var xmlns:Namespace = new Namespace("xmlns", "http://www.w3.org/2005/Atom");
        tweakXML.addNamespace(xmlns);

        // Parse into a dictionary.
        var cellDictionary:Dictionary = new Dictionary();
        var res:XMLList = tweakXML.xmlns::entry;
        for each(var entryXML:XML in res)
        {
           //Logger.Print(this, "Cell " + entryXML.xmlns::title.toString() + " = " + entryXML.xmlns::content.toString());
           cellDictionary[entryXML.xmlns::title.toString()] = entryXML.xmlns::content.toString();
        }

        // Now we can map based on config data.
        for each(var configItem:TweakerMapEntry in Config)
        { 
           var newValue:* = cellDictionary[configItem.Cell];
           if(newValue == "NA" || newValue == "")
              continue;

           //Logger.Print(this, "Setting property " + configItem.Property + " to " + newValue +  " based on " + configItem.Cell);
           Owner.SetProperty(configItem.Property, newValue);
           if(!Owner.DoesPropertyExist(configItem.Property))
           {
              Logger.Print(this, "   - failed to set " + configItem.Property.Property);
              Owner.SetProperty(configItem.Property, newValue);
           }
        }

        // Give some status.
        Logger.Print(this, "Updated " + Config.length + " properties from " + SpreadsheetUrl);
      }

      private function _OnLoadFail(e:Event):void
      {
         Logger.Print(this, "Failed to load google spreadsheet tweak url: " + e.toString());
      }
   }
}
