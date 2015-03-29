package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	
	public class LobbyEntry extends MovieClip {
		
		public var lobbyID:int;
		
		public function LobbyEntry() {
			// constructor code
			stop();
			this.addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			this.addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
		}
		
		public function onRollOver(event:MouseEvent){
			gotoAndStop(2);
		}
		
		public function onRollOut(event:MouseEvent){
			gotoAndStop(1);
		}
	}
	
}
