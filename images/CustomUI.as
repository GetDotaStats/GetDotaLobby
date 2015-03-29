package {
	import flash.display.MovieClip;
	import flash.text.*;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class CustomUI extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		private var ScreenWidth:int;
		private var ScreenHeight:int;
		public var scaleRatioY:Number;
				
		//constructor, you usually will use onLoaded() instead
		public function CustomUI() : void {
	
		}
		
		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			//make this UI visible
			visible = true;
			
			trace("OnLoaded");
				
			//let the client rescale the UI
			Globals.instance.resizeManager.AddListener(this);
			
			trace("resize manager done");
			
			//pass the gameAPI on to the modules
			this.myVotePanel.setup(this.gameAPI, this.globals);
			trace("myVotePanel.setup");
			this.myGamePanel.setup(this.gameAPI, this.globals);
			trace("myGamePanel.setup");
			this.mySpellPanel.setup(this.gameAPI, this.globals);
			trace("mySpellPanel.setup");
			this.mySpellListButton.setup(this.gameAPI, this.globals, this.mySpellPanel);
			trace("mySpellListButton.setup!");
			
			// Icon Setups
			//this.mySpellPanel.icy_path.setup(this.gameAPI, this.globals, "Icy Path");
			//this.mySpellPanel.portal.setup(this.gameAPI, this.globals, "Portal");
									
			//this.gameAPI.SubscribeToGameEvent("show_ultimate_ability", this.AbilityButtonEvent);
						
			trace("Custom UI loaded!");
		}
					
		//this handles the resizes
		public function onResize(re:ResizeManager) : * {
			
			// calculate by what ratio the stage is scaling
			scaleRatioY = re.ScreenHeight/1080;
			
			trace("##### RESIZE #########");
					
			ScreenWidth = re.ScreenWidth;
			ScreenHeight = re.ScreenHeight;
					
			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			this.myVotePanel.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.myGamePanel.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.mySpellPanel.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			this.mySpellListButton.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
		}
	}
}