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
	import com.pblabs.engine.PBUtil;
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.resource.ResourceEvent;
	import com.pblabs.engine.util.MCUtil;
	import com.pblabs.rendering2D.SWFSpriteRenderer;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	
	public class SWFSpriteRendererG2D extends SWFSpriteRenderer
	{
		public function SWFSpriteRendererG2D()
		{
			super();
		}
		
		override public function pointOccupied(worldPosition:Point, mask:ObjectType):Boolean
		{
			if (!gpuObject || !scene)
				return false;
			
			var localPos:Point = transformWorldToObject(worldPosition);
			return gpuObject.hitTest(localPos) ? true : false;
		}

		/**
		 * @inheritDoc
		 */
		override public function updateTransform(updateProps:Boolean = false):void
		{
			if(!gpuObject){
				super.updateTransform(updateProps);
				return;
			}
			
			if(updateProps)
				updateProperties();
			
			_transformMatrix.identity();
			//_transformMatrix.scale(combinedScale.x, combinedScale.y);
			_transformMatrix.translate(-_registrationPoint.x * combinedScale.x, -_registrationPoint.y * combinedScale.y);
			_transformMatrix.rotate(PBUtil.getRadiansFromDegrees(_rotation + _rotationOffset));
			_transformMatrix.translate((_position.x + _positionOffset.x), (_position.y + _positionOffset.y));
			
			gpuObject.transformationMatrix = _transformMatrix;
			//gpuObject.pivotX = _registrationPoint.x;
			//gpuObject.pivotY = _registrationPoint.y;
			gpuObject.alpha = this._alpha;
			gpuObject.blendMode = this._blendMode;
			gpuObject.visible = (alpha > 0);
			gpuObject.touchable = _mouseEnabled;
			
			_transformDirty = false;
		}

		override protected function buildG2DObject(skipCreation : Boolean = false):void
		{
			if(!Starling.context && !skipCreation){
				InitializationUtilG2D.initializeRenderers.add(buildG2DObject);
				return;
			}
			
			if(!skipCreation){
				var texture : Texture;
				if(!_resource){
					return;
				}
				if(!gpuObject){
					texture = ResourceTextureManagerG2D.getTextureByKey( getTextureCacheKey() );
					if(texture)
					{
						gpuObject = new Image(texture);
					}else if(bitmapData){
						//Create GPU Renderer Object
						gpuObject = new Image(ResourceTextureManagerG2D.getTextureForBitmapData( bitmapData, getTextureCacheKey() ));
					}
				}else if(bitmapData){
					if((gpuObject as Image).texture)
						(gpuObject as Image).texture.dispose();
					
					(gpuObject as Image).texture = ResourceTextureManagerG2D.getTextureForBitmapData(bitmapData, getTextureCacheKey());
					(gpuObject as Image).readjustSize();
				}
				if(!bitmapData) return;
				smoothing = _smoothing;
				skipCreation = true;
				_imageDataDirty = false;
			}
			super.buildG2DObject(skipCreation);
		}
		
		override protected function onRemove():void
		{
			super.onRemove();
			InitializationUtilG2D.initializeRenderers.remove(buildG2DObject);
		}

		override protected function paintMovieClipToBitmap(instance : DisplayObject):void
		{
			if(ResourceTextureManagerG2D.isATextureCachedWithKey( getTextureCacheKey() ) && gpuObject){
				ResourceTextureManagerG2D.releaseTexture( (gpuObject as Image).texture );
			}
			super.paintMovieClipToBitmap(instance);
		}
		
		override protected function onResourceUpdated(event : ResourceEvent):void
		{
			if(ResourceTextureManagerG2D.isATextureCachedWithKey( getTextureCacheKey() ) && gpuObject){
				ResourceTextureManagerG2D.releaseTexture( (gpuObject as Image).texture );
			}
			super.onResourceUpdated(event);
		}
		

		protected function modifyTexture(data:Texture):Texture
		{
			return data;            
		}

		protected function getTextureCacheKey():String{
			if(!_resource)
				return null;
			return _fileName + ":" + _containingObjectName + ":" + _scale.toString();
		}

		override public function set mouseEnabled(value:Boolean):void
		{
			_mouseEnabled = value;
			
			if(!gpuObject) return;
			gpuObject.touchable = _mouseEnabled;
		}

		override public function set bitmapData(value:BitmapData):void
		{
			if (value === bitmap.bitmapData)
				return;
			
			// store orginal BitmapData so that modifiers can be re-implemented 
			// when assigned modifiers attribute later on.
			originalBitmapData = value;
			
			// check if we should do modification
			//TODO: Add gpu modifiers later on
			/*
			if (modifiers.length>0)
			{
				// apply all bitmapData modifiers
				bitmap.bitmapData = modify(originalBitmapData.clone());
				dataModified();			
			}	
			else						
			*/
			bitmap.bitmapData = value;
			
			// Due to a bug, this has to be reset after setting bitmapData.
			smoothing = _smoothing;
			
			_imageDataDirty = true;
			_transformDirty = true;
			buildG2DObject();
		}
		
		/**
		 * @see Bitmap.smoothing 
		 */
		[EditorData(ignore="true")]
		override public function set smoothing(value:Boolean):void
		{
			super.smoothing = value;
			if(gpuObject)
			{
				if(!_smoothing)
					(gpuObject as Image).smoothing = TextureSmoothing.NONE;
				else
					(gpuObject as Image).smoothing = TextureSmoothing.BILINEAR;
			}
		}
		
	}
}