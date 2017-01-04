/*******************************************************************************
 * GameBuilder Studio
 * Copyright (C) 2012 GameBuilder Inc.
 * For more information see http://www.gamebuilderstudio.com
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.starling2D
{
    import com.pblabs.engine.PBE;
    import com.pblabs.engine.PBUtil;
    import com.pblabs.engine.debug.Logger;
    import com.pblabs.rendering2D.ui.IUITarget;
    
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display3D.Context3DProfile;
    import flash.display3D.Context3DRenderMode;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.Dictionary;
    
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Sprite;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    
    /**
     * This class can be set as the SceneView on the BaseSceneComponent class and is used
     * as the canvas to draw the objects that make up the scene. It defaults to the size
     * of the stage.
     * 
     * <p>Currently this is just a stub, and exists for clarity and potential expandability in
     * the future.</p>
     */
    public class SceneViewG2D extends SceneViewG2DSprite implements IUITarget
    {
		private var _starlingViewIndex : int = 0;
		private var _starlingInstance : Starling;
		private var _gpuCanvasContainer : Sprite;
		
		private var _delayedCalls : Vector.<Object> = new Vector.<Object>();
		private var _displayObjectList : Vector.<DisplayObject> = new Vector.<DisplayObject>();
		private var _sharedStarlingView : Boolean = false;
		
		private static var _starlingViewMap : Dictionary = new Dictionary();
		private static var _starlingViewCount : int = 0;
		private static var _stage3DIndex : int = -1;
		
		public function SceneViewG2D(renderMode : String = Context3DRenderMode.AUTO, profile : String = Context3DProfile.BASELINE_CONSTRAINED, forceNewInstanceCreation : Boolean = false)
		{
			if(PBE.mainStage)
			{
				/*if(!PBE.mainClass.contains(this))
					PBE.mainClass.addChildAt(this, 0);*/
				
				// Intelligent default size.
				_width = PBE.mainStage.stageWidth;
				_height = PBE.mainStage.stageHeight;

				PBE.mainStage.scaleMode = StageScaleMode.NO_SCALE;
				PBE.mainStage.align = StageAlign.TOP_LEFT;
				
				if(Starling.current && !forceNewInstanceCreation){
					_starlingInstance = Starling.current;
					onContextCreated();
					onRootInitialized();
					_stage3DIndex = PBE.mainStage.stage3Ds.indexOf(_starlingInstance.context);
					_sharedStarlingView = true;
				}else{
					if(!Starling.current || forceNewInstanceCreation){
						Starling.multitouchEnabled = true; // useful on mobile devices
						
						_stage3DIndex = _stage3DIndex + 1;
						if(PBE.mainStage.stage3Ds[_stage3DIndex].context3D)
							PBE.mainStage.stage3Ds[_stage3DIndex].context3D.clear();
						
						_starlingInstance = new Starling(Sprite, PBE.mainStage, new Rectangle(0,0, width, height), PBE.mainStage.stage3Ds[_stage3DIndex], renderMode, profile);
						_starlingInstance.skipUnchangedFrames = true;
						_starlingInstance.addEventListener("context3DCreate", onContextCreated);
						_starlingInstance.addEventListener("rootCreated", onRootInitialized);
						_starlingInstance.start();

						if(Capabilities.os.toLowerCase().indexOf("mac") == -1 && Capabilities.os.toLowerCase().indexOf("windows") == -1)
							PBE.mainStage.addEventListener(Event.DEACTIVATE, stage_deactivateHandler, false, 0, true);
					}
				}
				
				if(!PBE.IS_SHIPPING_BUILD){
					//_starlingInstance.enableErrorChecking = true;
					//_starlingInstance.simulateMultitouch = true;
				}
				name = "SceneView_"+_starlingViewCount;
			
			}
			this.addEventListener("removedFromStage", onRemovedFromStage);
			this.addEventListener("addedToStage", onAddedToStage);
			
			_starlingViewCount = _starlingViewCount+1;
		}
		
		public static function findStarlingView(name : String):SceneViewG2D
		{
			if(_starlingViewMap.hasOwnProperty(name))
				return _starlingViewMap[name];
			return null;
		}
		
		public function addDisplayObject(dObj:Object):void
		{
			if(!_gpuCanvasContainer){
				_delayedCalls[_delayedCalls.length] = {func : addDisplayObject, params: [dObj] };
				return;
			}
			_displayObjectList[_displayObjectList.length] = dObj as DisplayObject;	
			_gpuCanvasContainer.addChild( dObj as DisplayObject );
		}
		
		public function clearDisplayObjects():void
		{
			if(!_gpuCanvasContainer){
				_delayedCalls.push( {func : clearDisplayObjects, params: null } );
				return;
			}

			var len : int = _displayObjectList.length;
			for(var i : int = 0; i < len; i++)
			{
				if(_gpuCanvasContainer.contains(_displayObjectList[i]))
					_gpuCanvasContainer.removeChild( _displayObjectList[i] );
			}
			_displayObjectList.length = 0;
		}
		
		public function removeDisplayObject(dObj:Object):void
		{
			if(!_gpuCanvasContainer){
				_delayedCalls.push( {func : removeDisplayObject, params: [dObj] } );
				return;
			}

			if(_gpuCanvasContainer.contains(dObj as DisplayObject))
				_gpuCanvasContainer.removeChild( dObj as DisplayObject );
			
			var dIndex : int = _displayObjectList.indexOf(dObj as DisplayObject);
			if(dIndex != -1)
				PBUtil.splice(_displayObjectList, dIndex, 1);
		}
		
		public function getDisplayObjectIndex(dObj:Object):int
		{
			if(!_gpuCanvasContainer) 
				return -1;
			return _displayObjectList.indexOf(dObj as DisplayObject);
		}

		public function setDisplayObjectIndex(dObj:Object, index:int):void
		{
			if(!_gpuCanvasContainer){
				_delayedCalls[_delayedCalls.length] = {func : setDisplayObjectIndex, params: [dObj, index] };
				return;
			}
			
			if(_gpuCanvasContainer.numChildren >= index){
				//Already in list
				var currentIndex : int = _displayObjectList.indexOf(dObj as DisplayObject);
				if(currentIndex > -1)
				{
					PBUtil.splice(_displayObjectList, currentIndex, 1);
				}
				PBUtil.splice(_displayObjectList, index, 0, dObj as DisplayObject);
				_gpuCanvasContainer.addChildAt(dObj as DisplayObject, index);
				//Try and add any pending objects, This is needed incase scenes are added out of order
				if(_pendingDisplayObjectAdditions.length > 0)
				{
					var pendingListLen : int = _pendingDisplayObjectAdditions.length;
					var tmpList : Array = [];
					for(var i : int = 0; i < pendingListLen; i++)
					{
						var tmpData : Object = _pendingDisplayObjectAdditions[i];
						if(_gpuCanvasContainer.numChildren >= tmpData.position)
						{
							_gpuCanvasContainer.addChildAt(tmpData.displayObject as DisplayObject, tmpData.position);

							PBUtil.splice(_displayObjectList, tmpData.position, 0, tmpData.displayObject);
							PBUtil.splice(_pendingDisplayObjectAdditions, 0, 1);
						}else{
							tmpList[tmpList.length] = _pendingDisplayObjectAdditions.splice(0, 1);
						}
					}
					_pendingDisplayObjectAdditions = tmpList;
				}
			}else{
				_pendingDisplayObjectAdditions[_pendingDisplayObjectAdditions.length] = {displayObject: dObj, position: index};
			}
		}
		
		public function setSize(width : Number, height : Number):void
		{
			_width = width;
			_height = height;
			var newViewPort : Rectangle = _starlingInstance.viewPort;
			newViewPort.width = _width;
			newViewPort.height = _height;
			_starlingInstance.stage.stageWidth = _width;
			_starlingInstance.stage.stageHeight = _height;
			_starlingInstance.viewPort = newViewPort;
		}
		
		public function dispose():void
		{
			_starlingViewCount = _starlingViewCount - 1;
			this.removeEventListener("removedFromStage", onRemovedFromStage);
			this.removeEventListener("addedToStage", onAddedToStage);

			if(!_sharedStarlingView){
				PBE.mainStage.removeEventListener(Event.DEACTIVATE, stage_deactivateHandler);

				_starlingInstance.removeEventListener("context3DCreate", onContextCreated);
				_starlingInstance.removeEventListener("rootCreated", onRootInitialized);
				_starlingInstance.stage.removeEventListener(TouchEvent.TOUCH, onTouch);

				InitializationUtilG2D.disposed.dispatch();
				
				_stage3DIndex = _stage3DIndex - 1;
			}

			clearDisplayObjects();
			
			//PBE.processManager.removeAnimatedObject(this);
			
			_disposed = true;
			
			//if(_gpuCanvasContainer && _starlingInstance)
				//(_starlingInstance.root as Sprite).removeChild(_gpuCanvasContainer);
			if(_starlingViewCount < 1){
				_starlingInstance.dispose();
			}
			_starlingInstance = null;
			_gpuCanvasContainer = null;
			delete _starlingViewMap[name];
		}

		private function onRemovedFromStage(event : *):void
		{
			if(_gpuCanvasContainer && _starlingInstance && _gpuCanvasContainer.parent && (_starlingInstance.root as Sprite).contains(_gpuCanvasContainer))
				(_starlingInstance.root as Sprite).removeChild(_gpuCanvasContainer);
		}
		
		private function onAddedToStage(event : *):void
		{
			if(_gpuCanvasContainer && _starlingInstance && !(_starlingInstance.root as Sprite).contains(_gpuCanvasContainer))
				(_starlingInstance.root as Sprite).addChild(_gpuCanvasContainer);
		}
		
		private function onRootInitialized(event : * = null):void{
			_gpuCanvasContainer = new Sprite();
			if(this.stage != null) 
				(_starlingInstance.root as Sprite).addChildAt(_gpuCanvasContainer, _starlingViewIndex);
			
			for each(var calls : Object in _delayedCalls)
			{
				(calls.func as Function).apply(this, calls.params);
			}
			if(!_sharedStarlingView)
			{
				//PBE.processManager.addAnimatedObject(this, 1000);
				InitializationUtilG2D.initializeRenderers.dispatch();
				
				_starlingInstance.stage.addEventListener(TouchEvent.TOUCH, onTouch);
			}
		}
		
		private var _touches : Vector.<Touch> = new Vector.<Touch>();
		private function onTouch(event : TouchEvent):void
		{
			if(!_starlingInstance) return;
			
			_touches.length = 0;
			event.getTouches(_starlingInstance.stage, null, _touches);
			//TODO: Do a touch object conversion to a generic engine Touch object instead of 
			//having the Starling dependency on the InputManager!!!
			PBE.inputManager.simulateTouch(_touches);
		}
		
		private function onContextCreated(event : * = null):void{
			// set framerate to 32 in software mode
			if (_starlingInstance && _starlingInstance.context.driverInfo.toLowerCase().indexOf("software") != -1) {
				_starlingInstance.nativeStage.frameRate = 32;
				Logger.info(this, "onContextCreated", "Running in Software mode Setting FPS to 32. ["+_starlingInstance.context.driverInfo.toLowerCase()+"]");
			}
		}
		
		private function stage_deactivateHandler(event:Event):void
		{
			stopRendering();
			PBE.mainStage.addEventListener(Event.ACTIVATE, stage_activateHandler, false, 0, true);
		}
		
		private function stage_activateHandler(event:Event):void
		{
			PBE.mainStage.removeEventListener(Event.ACTIVATE, stage_activateHandler);
			if(this._starlingInstance && !this._starlingInstance.isStarted)
				this._starlingInstance.start();
		}
		
		private function stopRendering():void
		{
			if(this._starlingInstance)
				this._starlingInstance.stop(true);
		}
		
		override public function get width():Number
        {
            return _width;
        }
        
        override public function set width(value:Number):void
        {
            _width = value;
			
			var newViewPort : Rectangle = _starlingInstance.viewPort;
			newViewPort.width = _width;
			newViewPort.height = _height;
			_starlingInstance.stage.stageWidth = _width;
			_starlingInstance.stage.stageHeight = _height;
			_starlingInstance.viewPort = newViewPort;
			
        }
        
        override public function get height():Number
        {
            return _height;
        }
        
        override public function set height(value:Number):void
        {
           _height = value;
		    
			var newViewPort : Rectangle = _starlingInstance.viewPort;
			newViewPort.width = _width;
			newViewPort.height = _height;
			_starlingInstance.stage.stageWidth = _width;
			_starlingInstance.stage.stageHeight = _height;
			_starlingInstance.viewPort = newViewPort;
		   
        }
		
		public function get viewIndex():int
		{
			return _starlingViewIndex;
		}
		
		public function set viewIndex(value:int):void
		{
			_starlingViewIndex = value;
			if(_gpuCanvasContainer && _starlingInstance && this.stage != null)
				(_starlingInstance.root as Sprite).addChildAt(_gpuCanvasContainer, _starlingViewIndex);
		}
		
        
		public function get canvasContainerG2D():DisplayObjectContainer{ return _gpuCanvasContainer; }
		public function get starlingInstance():Starling { return _starlingInstance; }
        
		override public function set name(value:String):void
		{
			if(_starlingViewMap.hasOwnProperty(name))
				delete _starlingViewMap[name];
			
			super.name = value;
			
			_starlingViewMap[value] = this;
		}
		
        private var _width:Number = 500;
        private var _height:Number = 500;
		private var _disposed : Boolean = false;
		private var _pendingDisplayObjectAdditions : Array = [];
    }
}
