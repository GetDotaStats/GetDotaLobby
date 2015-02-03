package  {
	import flash.display.MovieClip;
	
	public class Minigame extends MovieClip{
		
		public var minigameAPI:IMinigameAPI;
		public var debug:Boolean;
		public var globals:Object;
		public var gameAPI:Object;
		
		public var title:String = "Minigame Title";
		public var minigameID:String = "";

		public function Minigame() {
			// constructor code
		}

		public function initialize() : void{}
		public function close() : Boolean { return true;}
		public function resize(stageWidth:int, stageHeight:int, scaleRatio:Number) : Boolean { return true;}
	}
}
