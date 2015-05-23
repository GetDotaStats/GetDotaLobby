package ModDotaLib.Utils {
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.display.MovieClip;
	
	public class AssetUtils {
		public static function CreateAsset(type) {
			var objclass = getDefinitionByName(type);
			var obj = new objclass();
			return obj;
		}
		
		public static function AdoptAsset(child, adoptedParent) {
			var griefingMother = child.parent;
			griefingMother.removeChild(child);
			adoptedParent.addChild(child);
			
			return child;
		}
		public static function AutoReplaceAssets(target) {
			var i:int;

			switch(getQualifiedClassName(target)) {
				case "ModDotaLib.DotoAssets::DotoContainer":
					trace("OMGOMGOMG A DOTOCONTAINER");
					ReplaceAsset(target, "DB4_outerpanel");
					//ReplaceAsset(t, "bg_overlayBox");
					break;
				case "ModDotaLib.DotoAssets::DotoScrollbar":
					trace("OMGOMGOMG A DOTOSCROLLBAR");
					var tmp = ReplaceAsset(target, "ScrollBarDota");
					tmp.scaleX = 1;
					tmp.width = 2*tmp.width;
				default:
					//trace("nvm, not interested in: "+getQualifiedClassName(t));
			}
			
        	if(target is MovieClip) {
        		// Loop over children
	        	for(i = 0; i < target.numChildren; i++) {
					// Recurse!
	        		AutoReplaceAssets(target.getChildAt(i));
	        	}
        	}
		}
		public static function ReplaceAsset(btn, type) {
			var parent = btn.parent;
			var oldx = btn.x;
			var oldy = btn.y;
			var oldwidth = btn.width;
			var oldheight = btn.height;
			var olddepth = parent.getChildIndex(btn);
			var oldname = btn.name;

			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			newObject.width = oldwidth;
			newObject.height = oldheight;
			newObject.name = oldname;
			
			parent.removeChild(btn);
			parent.addChild(newObject);
			
			parent.setChildIndex(newObject, olddepth);
			
			return newObject;
		}
	}
}