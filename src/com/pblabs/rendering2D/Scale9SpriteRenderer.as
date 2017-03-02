/*******************************************************************************
 * GameBuilder Studio
 * Copyright (C) 2012 GameBuilder Inc.
 * For more information see http://www.gamebuilderstudio.com
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.rendering2D
{
	import com.pblabs.engine.PBUtil;
	import com.pblabs.engine.core.ObjectType;
	import com.pblabs.engine.debug.Logger;
	
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public final class Scale9SpriteRenderer extends SpriteRenderer
	{
		private var _scale9Region:Rectangle = new Rectangle(0,0,5,5);
		
		public function Scale9SpriteRenderer()
		{
			super();
		}
		
		override public function onFrame(elapsed:Number):void
		{
			super.onFrame(elapsed);
			
			if(_imageDataDirty)
				bitmapData = originalBitmapData;
		}
		
		public function get scale9Region():Rectangle
		{
			return _scale9Region
		}
		public function set scale9Region(region : Rectangle):void
		{
			_scale9Region = region;
			if(bitmap && bitmap.bitmapData && _scale9Region && isValidRegion)
				bitmap.scale9Grid = _scale9Region;
			_imageDataDirty = true;
		}
		
		override public function set size(value:Point):void
		{
			if(_size && value && (_size.x != value.x || _size.y != value.y))
				_imageDataDirty = true;
			super.size = value;
		}
		
		override public function set scale(value:Point):void
		{
			if(_scale && value && (_scale.x != value.x || _scale.y != value.y)){
				if(value.x < 0) value.x = .1;
				if(value.y < 0) value.y = .1;
				_imageDataDirty = true;
			}
			super.scale = value;
		}

		override public function set bitmapData(value:BitmapData):void
		{
			if((!bitmap || !(bitmap is Scale9Bitmap)) && value)
				bitmap = new Scale9Bitmap(value);
			
			if(bitmap && bitmap.bitmapData && _scale9Region)
				bitmap.scale9Grid = _scale9Region;
			
			super.bitmapData = value;
			
			_imageDataDirty = false;
		}
		
		public function get originalScalableBitmapData() : BitmapData
		{
			return originalBitmapData;
		}
		
		override public function updateTransform(updateProps:Boolean = false):void
		{
			if(!displayObject)
				return;
			
			if(updateProps)
				updateProperties();
			
			var tmpScale : Point = combinedScale;
			_transformMatrix.identity();
			//_transformMatrix.scale(_scale.x, _scale.y);
			_transformMatrix.translate(-_registrationPoint.x * tmpScale.x, -_registrationPoint.y * tmpScale.y);
			_transformMatrix.rotate(PBUtil.getRadiansFromDegrees(_rotation + _rotationOffset));
			_transformMatrix.translate((_position.x + _positionOffset.x), (_position.y + _positionOffset.y));
			
			displayObject.transform.matrix = _transformMatrix;
			if(bitmap){
				(bitmap as Scale9Bitmap).width = (this._size.x * _scale.x);
				(bitmap as Scale9Bitmap).height = (this._size.y * _scale.y);
			}
			displayObject.alpha = _alpha;
			displayObject.blendMode = (this._blendMode != "none" && this._blendMode != "shader") ? _blendMode : "normal";
			displayObject.visible = (alpha > 0);
			
			_transformDirty = false;
		}

		protected function get isValidRegion() : Boolean {
			if(!originalBitmapData || !_scale9Region) return false;
			return _scale9Region.right <= originalBitmapData.width && _scale9Region.bottom <= originalBitmapData.height;
		}
		
		/**
		 * Is the rendered object opaque at the request position in screen space?
		 * @param pos Location in world space we are curious about.
		 * @return True if object is opaque there.
		 */
		override public function pointOccupied(worldPosition:Point, mask:ObjectType):Boolean
		{
			if (!displayObject || !scene)
				return false;
			
			// Sanity check.
			if(displayObject.stage == null)
				Logger.warn(this, "pointOccupied", "DisplayObject is not on stage, so hitTestPoint will probably not work right.");
			
			// This is the generic version, which uses hitTestPoint. hitTestPoint
			// takes a coordinate in screen space, so do that.
			worldPosition = scene.transformWorldToScreen(worldPosition);
			return displayObject.hitTestPoint(worldPosition.x, worldPosition.y, true);
		}
	}
}