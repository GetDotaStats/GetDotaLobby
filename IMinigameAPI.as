package  {
	import flash.events.KeyboardEvent;
	
	public interface IMinigameAPI {

		// Interface methods:
		function getData() : Object;
		function saveData() : void;
		
		function resizeGameWindow() : void;
		function closeMinigame() : void;
		function updateTitle() : void;
		function updateLeaderboard(leaderboard:String, value:Number) : void;
		function getUserID() : String;
		
		function log(obj:Object) : void;
	}
}
