package  {
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.display.Loader;
	import flash.net.Socket;
	import flash.events.Event;
	import com.adobe.crypto.SHA1;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.ByteArray;
	
	import ValveLib.Globals;
	import flash.geom.Point;
	
	public class MinigameAPI implements IMinigameAPI{
		private static const salt:String = "";
		private var minigameID:String = "";
		private var DEBUG:Boolean = false;
		private var gameName:String = "";
		private var lx:Object = null;
		private var data:Object = null;
		private var uid:String = null;
		private var currentLocalization:Object = null;
		private var language:String = null;
		
		private var container:MovieClip;
		private var panel:MovieClip;
		private var indent:MovieClip;
		private var outer:MovieClip;
		private var minigame:Minigame;
		private var title:TextField;
		private var closeButton:MovieClip;
		
		public function MinigameAPI(minigame:Minigame, container:MovieClip, panel:MovieClip, indent:MovieClip, 
									outer:MovieClip, title:TextField, closeButton:MovieClip, lx:Object, 
									gameName:String, debug:Boolean, uid:String, language:String = "english") {
			this.minigame = minigame;
			this.container = container;
			this.panel = panel;
			this.indent = indent;
			this.outer = outer;
			this.title = title;
			this.closeButton = closeButton;
			this.uid = uid;
			this.language = language;
			
			this.minigameID = minigame.minigameID;
			
			this.lx = lx;
			this.gameName = gameName;
			this.DEBUG = debug;
			
			
			this.currentLocalization = Globals.instance.GameInterface.LoadKVFile('resource/flash3/minigames/' + gameName + '/minigame_english.txt');
			if (currentLocalization.Tokens == null){
				currentLocalization.Tokens = new Object();
				log("No localization tokens found for minigame_english.txt");
			}
			if (language != "english"){
				var lang:Object = Globals.instance.GameInterface.LoadKVFile('resource/flash3/minigames/' + gameName + '/minigame_' + language + '.txt');
				if (lang.Tokens != null){
					for (var token:String in lang.Tokens){
						currentLocalization.Tokens[token] = lang.Tokens[token];
					}
				}
				else{
					log("No localization tokens found for minigame_" + language + ".txt");
				}
			}
			
			lx.PrintTable(currentLocalization);
		}
		
		public function getData() : Object{
			if (data == null){
				data = Globals.instance.GameInterface.LoadKVFile('resource/flash3/minigames/' + gameName + '/data.kv');
			}
			
			return data;
		}
		public function saveData() : void{
			if (data == null){
				log("saveData called with no data");
			}
			Globals.instance.GameInterface.SaveKVFile(data, 'resource/flash3/minigames/' + gameName + '/data.kv', gameName);
		}
		
		public function resizeGameWindow(wid:Number = -1, hei:Number = -1) : void {
			if (wid == -1)
				wid = minigame.width;
			if (hei == -1)
				hei = minigame.height;
			panel.width = wid + 15;
			panel.height = hei + 15;
			
			indent.width = wid + 14;
			
			outer.height = hei + 35;
			outer.width = wid + 18;
			
			title.width = wid + 18;
			
			closeButton.x = wid + 12;
		}
		
		public function updateTitle() : void {
			title.text = translate(minigame.title);
		}
		
		public function closeMinigame() : void {
			lx.closeMinigame();
		}
		
		public function translate(str:String) : String{
			trace("translate: " + str);
			if (str.charAt(0) != "#")
				return str;
				
			var token:String = str.substr(1);
			var translated:String = currentLocalization.Tokens[token];
			if (translated != null)
				return translated;
			
			trace("translated: " + translated);
			translated = Globals.instance.GameInterface.Translate(str);
			trace("translated: " + translated);
			if (translated != "")
				return translated;
			return str;
		}
		
		public function updateLeaderboard(leaderboard:String, value:Number) : void {
			if (DEBUG) {
				log("DEBUG on, not sending leaderboard info: " + leaderboard + " -- " + value);
				return;
			}
			
			var msg:Object = {minigameID:minigameID, leaderboard:leaderboard, value:value, userID32:uid, type:"HIGHSCORE"};
			var encodedJSON:String = GetDotaLobby.encode(msg);
			log("Leaderboard message: " + encodedJSON);
			msg["hmac"] = SHA1.hash(salt + encodedJSON);
			encodedJSON = GetDotaLobby.encode(msg);

			var socket:Socket = new Socket();

			var leaderboardConnect:Function = (function(json:String, socket:Socket) {
				socket.removeEventListener(Event.CONNECT, leaderboardConnect);
				return function(e:Event){
					trace("writing leaderboard socket: " + json);
					try{
						var ba:ByteArray = new ByteArray();
						var len:uint = ba.length;
						
						ba = new ByteArray();
						ba.writeUTF(json);
						trace(ba.length);
		
						socket.writeBytes(ba, 0, ba.length);
						socket.flush();
						
						var fun:Function = function(te:TimerEvent){
							socket.close();
						};
						var timer:Timer = new Timer(500, 1);
						timer.addEventListener(TimerEvent.TIMER, fun);
						timer.start();
					}catch(err:Error){
						trace(err);
					}
				};
			})(encodedJSON, socket);

			trace("CONNECTING");
			socket.connect("176.31.182.87", 4450);
			socket.addEventListener(Event.CONNECT, leaderboardConnect);
		}
		
		public function getUserID() : String {
			return uid;
		}
		
		public function log(obj:Object) : void {
			lx.traceLX("[" + gameName + "]" + obj.toString());
		}
	}
	
}
